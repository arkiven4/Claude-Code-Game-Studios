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

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")
os.makedirs(MODELS_DIR, exist_ok=True)

# Agents per arena (must match scene registration order)
_BASE_AGENTS = ["evan", "evelyn", "team", "enemy_0", "enemy_1", "enemy_2"]
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
        # Sizes must match GDScript N_OBS constants (updated after recent fixes):
        #   party agent : 54  (self=10, casting=2, allies×3=15, enemies×4=20, directive=7)
        #   team agent  : 33  (unchanged)
        #   hive agent  : 25  (self=5, party×2=10, enemy_allies×2=10)
        obs_party  = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (54,), dtype=np.float32)})
        obs_team   = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (33,), dtype=np.float32)})
        obs_enemy  = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (25,), dtype=np.float32)})

        act_party = gym.spaces.Dict({
            "action":      gym.spaces.Discrete(11),  # 0=wait,1-4=skills,5-8=movement,9=basic,10=special
            "heal_target": gym.spaces.Discrete(2),   # 0=self, 1=lowest-HP ally
        })
        act_team = gym.spaces.Dict({
            "evan_target":   gym.spaces.Discrete(4),
            "evan_role":     gym.spaces.Discrete(3),
            "evelyn_target": gym.spaces.Discrete(4),
            "evelyn_role":   gym.spaces.Discrete(3),
        })
        act_enemy = gym.spaces.Dict({
            "action": gym.spaces.Discrete(6),  # 0=wait,1=skill0,2=skill1,3-5=movement
        })

        obs_spaces = {}
        act_spaces = {}
        for i in range(self.n_arenas):
            obs_spaces[f"arena_{i}_evan"]    = obs_party
            obs_spaces[f"arena_{i}_evelyn"]  = obs_party
            obs_spaces[f"arena_{i}_team"]    = obs_team
            obs_spaces[f"arena_{i}_enemy_0"] = obs_enemy
            obs_spaces[f"arena_{i}_enemy_1"] = obs_enemy
            obs_spaces[f"arena_{i}_enemy_2"] = obs_enemy

            act_spaces[f"arena_{i}_evan"]    = act_party
            act_spaces[f"arena_{i}_evelyn"]  = act_party
            act_spaces[f"arena_{i}_team"]    = act_team
            act_spaces[f"arena_{i}_enemy_0"] = act_enemy
            act_spaces[f"arena_{i}_enemy_1"] = act_enemy
            act_spaces[f"arena_{i}_enemy_2"] = act_enemy

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

        for i in range(self.n_arenas):
            off = i * _AGENTS_PER_ARENA
            p   = f"arena_{i}_"
            for j, name in enumerate(_BASE_AGENTS):
                key = p + name
                res_rew[key]   = reward[off + j]
                res_term[key]  = terminated[off + j]
                res_trunc[key] = truncated[off + j]
                res_info[key]  = info[off + j] if len(info) > off + j else {}

        res_term["__all__"]  = all(terminated)
        res_trunc["__all__"] = all(truncated)

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
    if "enemy_" in agent_id:
        return "enemy_hive_policy"
    if agent_id.endswith("evelyn"):
        return "evelyn_policy"
    if agent_id.endswith("evan"):
        return "evan_policy"
    return "team_policy"


def main():
    N_ARENAS = 8  # Tune to your CPU/GPU. Each arena adds ~6 agents worth of throughput.

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
                "enemy_hive_policy": (None, None, None, {}),
            },
            # Check evelyn before evan — "_evan" is a substring of "_evelyn"
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

    print("Training started. Ctrl+C to stop.")
    try:
        for iteration in range(500):
            result = algo.train()
            if iteration % 10 == 0:
                reward = result.get("episode_reward_mean")
                reward_str = f"{reward:.3f}" if isinstance(reward, (float, int)) else str(reward)
                custom = result.get("custom_metrics", {})
                wins = custom.get("team_victory_mean", 0.0) * 100.0
                ep_len = result.get("episode_len_mean", 0.0)
                print(f"[{iteration}] reward: {reward_str} | wins: {wins:.1f}% | len: {ep_len:.1f} "
                      f"| arenas: {N_ARENAS}")
            if iteration % 50 == 0:
                save_path = algo.save(MODELS_DIR)
                print(f"Checkpoint saved: {save_path}")
    except KeyboardInterrupt:
        print("Training interrupted.")

    algo.save(os.path.join(MODELS_DIR, "final_vec"))
    print(f"Training complete. Models saved to {MODELS_DIR}")
    ray.shutdown()


if __name__ == "__main__":
    main()
