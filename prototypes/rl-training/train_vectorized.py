"""
Vectorized multi-agent RL training for myvampire party AI.
Runs N arena groups inside one Godot process — more experience per wall-clock second
than a single arena, without the overhead of N separate Godot instances.

Agents per arena : evan, evelyn, team, enemy_0, enemy_1, enemy_2  (6 total)
Total agents     : N * 6  (all seen by one godot_rl Sync node)

Install:
  pip install ray[rllib] torch godot-rl

Usage:
  Terminal 1 — start Python first:
    cd /home/arkiven4/Documents/Project/Other/myvampire
    python3.10 prototypes/rl-training/train_vectorized.py

  Terminal 2 — launch Godot after Python prints "waiting for connection":
    godot --headless res://prototypes/rl-training/VectorizedTraining.tscn -- --n_arenas=8 --speedup=10
    # NOTE: scene path goes BEFORE '--'; everything after '--' is read by godot_rl.

Models saved to: prototypes/rl-training/models/
"""

import os
import ray
import numpy as np
import gymnasium as gym
from ray.rllib.algorithms.ppo import PPOConfig
from ray.tune.registry import register_env
from ray.rllib.env.multi_agent_env import MultiAgentEnv
from godot_rl.core.godot_env import GodotEnv

# Import unified config
from agent_config import (
    get_observation_spaces,
    get_action_spaces,
    get_base_agents,
    get_policy_mapping_fn,
    get_policies,
    save_config,
)

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")
os.makedirs(MODELS_DIR, exist_ok=True)

# Agents per arena (must match scene registration order)
_BASE_AGENTS = get_base_agents()
_AGENTS_PER_ARENA = len(_BASE_AGENTS)


class VectorizedGodotEnv(MultiAgentEnv):
    def __init__(self, env_config):
        super().__init__()
        self.port = env_config.get("port", 11008)
        self.seed = env_config.get("seed", 42)
        self.n_arenas = env_config.get("n_arenas", 4)
        self.env_config = env_config
        self._env = None

        # Build the full set of agent IDs: arena_0_evan, arena_0_evelyn, ...
        self._agent_ids = set()
        for i in range(self.n_arenas):
            for name in _BASE_AGENTS:
                self._agent_ids.add(f"arena_{i}_{name}")
        self.possible_agents = self._agent_ids

        # --- Observation / action spaces ---
        # Get base spaces from unified config
        base_obs_spaces = get_observation_spaces()
        base_act_spaces = get_action_spaces()

        obs_spaces = {}
        act_spaces = {}
        for i in range(self.n_arenas):
            for j, agent_name in enumerate(_BASE_AGENTS):
                key = f"arena_{i}_{agent_name}"
                obs_spaces[key] = base_obs_spaces[agent_name]
                act_spaces[key] = base_act_spaces[agent_name]

        self.observation_space = gym.spaces.Dict(obs_spaces)
        self.action_space = gym.spaces.Dict(act_spaces)

    def reset(self, *, seed=None, options=None):
        if self._env is None:
            self._env = GodotEnv(port=self.port, seed=self.seed)

        obs, info = self._env.reset()
        return self._unpack_obs(obs), {}

    def step(self, action_dict):
        actions = []
        for i in range(self.n_arenas):
            p = f"arena_{i}_"
            evan   = action_dict.get(p + "evan",    {"action": 0, "heal_target": 1})
            evelyn = action_dict.get(p + "evelyn",  {"action": 0, "heal_target": 1})
            team   = action_dict.get(p + "team",    {"evan_target": 3, "evan_role": 0,
                                                      "evelyn_target": 3, "evelyn_role": 0})
            e0     = action_dict.get(p + "enemy_0", {"action": 0})
            e1     = action_dict.get(p + "enemy_1", {"action": 0})
            e2     = action_dict.get(p + "enemy_2", {"action": 0})

            actions.append([int(evan["action"]),   int(evan["heal_target"])])
            actions.append([int(evelyn["action"]), int(evelyn["heal_target"])])
            actions.append([int(team["evan_target"]), int(team["evan_role"]),
                            int(team["evelyn_target"]), int(team["evelyn_role"])])
            actions.append([int(e0["action"])])
            actions.append([int(e1["action"])])
            actions.append([int(e2["action"])])

        obs, reward, terminated, truncated, info = self._env.step(actions, order_ij=True)

        res_obs  = self._unpack_obs(obs)
        res_rew  = {}
        res_term = {}
        res_trunc = {}
        res_info  = {}

        # Determine if the shared episode is over (any arena fully done).
        # IMPORTANT: individual agents must NEVER be marked done unless __all__ is
        # also True in the same step. If an individual agent gets terminated=True
        # while __all__=False, RLlib opens a new sub-episode for that agent within
        # the same rollout. When __all__ later fires, the agent's batch contains
        # multiple eps_ids → "Batches must only contain steps from a single trajectory".
        arena_done = [
            all(terminated[i * _AGENTS_PER_ARENA + j] for j in range(_AGENTS_PER_ARENA))
            for i in range(self.n_arenas)
        ]
        arena_trunc = [
            all(truncated[i * _AGENTS_PER_ARENA + j] for j in range(_AGENTS_PER_ARENA))
            for i in range(self.n_arenas)
        ]
        episode_over = any(arena_done) or any(arena_trunc)

        for i in range(self.n_arenas):
            off = i * _AGENTS_PER_ARENA
            p   = f"arena_{i}_"
            for j, name in enumerate(_BASE_AGENTS):
                key = p + name
                res_rew[key]  = reward[off + j]
                res_info[key] = info[off + j] if len(info) > off + j else {}
                if episode_over:
                    # Arena that naturally finished → terminated; others → truncated.
                    res_term[key]  = arena_done[i]
                    res_trunc[key] = not arena_done[i]
                else:
                    res_term[key]  = False
                    res_trunc[key] = False

        res_term["__all__"]  = episode_over
        res_trunc["__all__"] = episode_over

        return res_obs, res_rew, res_term, res_trunc, res_info

    def close(self):
        if self._env:
            self._env.close()

    def _unpack_obs(self, obs) -> dict:
        result = {}
        for i in range(self.n_arenas):
            off = i * _AGENTS_PER_ARENA
            p   = f"arena_{i}_"
            for j, name in enumerate(_BASE_AGENTS):
                result[p + name] = {"obs": np.array(obs[off + j]["obs"], dtype=np.float32)}
        return result


def _policy_for(agent_id: str) -> str:
    """Map vectorized agent IDs (arena_N_<name>) to shared policy names."""
    mapping_fn = get_policy_mapping_fn()
    # Extract base agent name from arena_N_<name> format
    base_name = "_".join(agent_id.split("_")[2:])  # everything after "arena_N_"
    return mapping_fn(base_name)


def main():
    N_ARENAS = 32  # Tune to your CPU/GPU. Each arena adds ~6 agents worth of throughput.

    if not ray.is_initialized():
        ray.init()

    import torch
    print(f"CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"Using GPU: {torch.cuda.get_device_name(0)}")

    register_env("godot_vec", lambda cfg: VectorizedGodotEnv(cfg))

    print(f"Vectorized training — {N_ARENAS} arenas, {N_ARENAS * _AGENTS_PER_ARENA} total agents.")
    print("Waiting for Godot to connect on port 11008 ...")
    print(f"Launch: godot --headless res://prototypes/rl-training/VectorizedTraining.tscn "
          f"-- --n_arenas={N_ARENAS} --speedup=10")

    config = (
        PPOConfig()
        .api_stack(
            enable_rl_module_and_learner=False,
            enable_env_runner_and_connector_v2=False,
        )
        .environment("godot_vec", env_config={"port": 11008, "n_arenas": N_ARENAS})
        .multi_agent(
            policies={
                "evan_policy":       (None, None, None, {}),
                "evelyn_policy":     (None, None, None, {}),
                "team_policy":       (None, None, None, {}),
                # Higher entropy so enemy explores more aggressively
                "enemy_hive_policy": (None, None, None, {"entropy_coeff": 0.05}),
            },
            policy_mapping_fn=lambda agent_id, *args, **kwargs: _policy_for(agent_id),
        )
        .training(
            lr=3e-4,
            # 12000 steps per arena base; scales linearly so batch stays proportional.
            train_batch_size=12000 * N_ARENAS,
            num_epochs=10,
            entropy_coeff=0.02,   # Higher entropy for better early exploration
        )
        .env_runners(num_env_runners=0)
        .resources(num_gpus=1)
    )

    import datetime
    from ray.tune.logger import UnifiedLogger

    def custom_logger_creator(cfg):
        base = os.path.join(os.path.dirname(__file__), "ray_results")
        os.makedirs(base, exist_ok=True)
        ts = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        run_dir = os.path.join(base, f"PPO_vec_{N_ARENAS}arenas_{ts}")
        os.makedirs(run_dir, exist_ok=True)
        return UnifiedLogger(cfg, run_dir)

    algo = config.build_algo(logger_creator=custom_logger_creator)

    # --- Early stopping config ---
    # Primary metric: team_policy reward (rises as damage progress improves —
    # includes on_victory +5, on_enemy_killed +0.5, on_defeat -5).
    # custom_metrics is always empty in this RLlib setup, so we read from
    # policy_reward_mean directly instead.
    PATIENCE      = 50    # iterations without improvement before stopping
    MIN_REWARD_DELTA = 0.5  # minimum team reward gain to count as improvement
    # Warn (and optionally stop) when a policy's entropy collapses this low.
    # With 11 actions, random entropy ≈ ln(11) ≈ 2.4. Below 0.5 means near-deterministic.
    ENTROPY_WARN  = 0.5
    ENTROPY_STOP  = 0.1   # hard stop — policy is essentially deterministic

    best_team_reward  = float("-inf")
    no_improve_iters  = 0
    best_ckpt_path    = None

    # Alternating training schedule — prevents party from staying permanently ahead.
    # Even iters: only enemy trains (dedicated catch-up time).
    # Odd iters:  only party trains (party keeps improving, enemy must adapt).
    # After ENEMY_CATCHUP_ITERS, switch to free-for-all (all policies always train).
    ENEMY_CATCHUP_ITERS = 100  # How long to run alternating before going free-for-all
    _PARTY_POLICIES = ["evan_policy", "evelyn_policy", "team_policy"]
    _ENEMY_POLICIES = ["enemy_hive_policy"]
    _ALL_POLICIES   = _PARTY_POLICIES + _ENEMY_POLICIES

    print("Training started. Ctrl+C to stop.")
    print(f"Early stopping: patience={PATIENCE} iters | min_reward_delta={MIN_REWARD_DELTA} "
          f"| entropy_stop={ENTROPY_STOP}")
    print(f"Alternating training: first {ENEMY_CATCHUP_ITERS} iters alternate party/enemy, then free-for-all.")
    try:
        for iteration in range(500):
            # Alternate which side trains to prevent party from staying permanently ahead.
            if iteration < ENEMY_CATCHUP_ITERS:
                to_train = _ENEMY_POLICIES if iteration % 2 == 0 else _PARTY_POLICIES
            else:
                to_train = _ALL_POLICIES
            algo.config._is_frozen = False
            algo.config.policies_to_train = to_train
            algo.config._is_frozen = True

            result = algo.train()

            policy_rewards = result.get("env_runners", {}).get("policy_reward_mean", {})
            team_reward = policy_rewards.get("team_policy", float("nan"))
            ep_len      = result.get("episode_len_mean") or result.get("env_runners", {}).get("episode_len_mean", 0.0)

            # --- Per-policy entropy check ---
            learner_info = result.get("info", {}).get("learner", {})
            entropy_collapse = False
            for policy_name, policy_info in learner_info.items():
                entropy = policy_info.get("learner_stats", {}).get("entropy", float("inf"))
                if entropy < ENTROPY_WARN:
                    print(f"  [WARN] {policy_name} entropy={entropy:.3f} — "
                          f"policy becoming deterministic (threshold={ENTROPY_WARN})")
                if entropy < ENTROPY_STOP:
                    print(f"  [STOP] {policy_name} entropy={entropy:.3f} collapsed "
                          f"below {ENTROPY_STOP} — stopping to prevent degenerate policy.")
                    entropy_collapse = True

            if iteration % 10 == 0:
                team_str = f"{team_reward:.2f}" if team_reward == team_reward else "n/a"
                print(f"[{iteration}] team_reward: {team_str} | ep_len: {ep_len:.1f} "
                      f"| no_improve: {no_improve_iters}/{PATIENCE} | arenas: {N_ARENAS}")

            # --- Best checkpoint (skip NaN iterations — no completed episodes yet) ---
            if team_reward == team_reward and team_reward >= best_team_reward + MIN_REWARD_DELTA:
                best_team_reward = team_reward
                no_improve_iters = 0
                best_ckpt_path   = algo.save(os.path.join(MODELS_DIR, "best"))
                save_config(best_ckpt_path)  # Save agent config with checkpoint
                print(f"  [BEST] team_reward={team_reward:.2f} — checkpoint: {best_ckpt_path}")
            elif team_reward == team_reward:  # only count non-NaN iterations
                no_improve_iters += 1

            # --- Periodic checkpoint ---
            if iteration % 50 == 0:
                save_path = algo.save(MODELS_DIR)
                save_config(save_path)  # Save agent config with checkpoint
                print(f"Checkpoint saved: {save_path}")

            # --- Early stopping ---
            if entropy_collapse:
                break
            if no_improve_iters >= PATIENCE:
                print(f"[EARLY STOP] team_policy reward hasn't improved by ≥{MIN_REWARD_DELTA} "
                      f"for {PATIENCE} iterations (best={best_team_reward:.2f}). Stopping.")
                break

    except KeyboardInterrupt:
        print("Training interrupted.")

    final_path = algo.save(os.path.join(MODELS_DIR, "final_vec"))
    save_config(final_path)  # Save agent config with final checkpoint
    print(f"Training complete. Best team reward: {best_team_reward:.2f}")
    if best_ckpt_path:
        print(f"Best checkpoint: {best_ckpt_path}")
    print(f"Models saved to {MODELS_DIR}")
    ray.shutdown()


if __name__ == "__main__":
    main()
