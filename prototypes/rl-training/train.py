"""
Multi-agent RL training for myvampire party AI.
Uses godot_rl v0.8.2 + Ray RLlib (multi-policy).

Install dependencies:
  pip install ray[rllib] torch godot-rl

Usage:
  Terminal 1 (start first):
    cd /home/arkiven4/Documents/Project/Other/myvampire
    python3.10 prototypes/rl-training/train.py

  Terminal 2 (after Python prints "waiting for connection"):
    godot --headless res://prototypes/rl-training/TrainingArena.tscn -- --speedup=10
    # NOTE: Scene path goes BEFORE '--'. Everything after '--' is a user arg read by godot_rl.

Models saved to: prototypes/rl-training/models/
"""

import os
import sys
import ray
import numpy as np
import gymnasium as gym
from ray.tune.registry import register_env
from ray.rllib.env.multi_agent_env import MultiAgentEnv
from godot_rl.core.godot_env import GodotEnv

from agent_config import (
    get_observation_spaces,
    get_action_spaces,
    get_agent_ids,
    get_policies,
    get_policy_mapping_fn,
    save_config,
)
from utils import MODELS_DIR, init_ray, make_logger_creator, build_base_ppo_config


def _set_policies_to_train(algo, policies: list) -> None:
    """Cross-version compatible policy freezing for Ray RLlib.

    `Algorithm.set_policies_to_train` was removed on newer Ray versions but
    still exists on rollout workers. Try each API in order and use whichever
    actually works in the installed Ray build.
    """
    set_method = getattr(algo, "set_policies_to_train", None)
    if callable(set_method):
        set_method(policies)
        return

    for attr in ("workers", "env_runner_group"):
        wg = getattr(algo, attr, None)
        if wg is None:
            continue
        foreach = getattr(wg, "foreach_worker", None)
        if not callable(foreach):
            continue
        try:
            foreach(
                lambda w, p=policies: (
                    w.set_policies_to_train(p)
                    if hasattr(w, "set_policies_to_train") else None
                )
            )
            return
        except Exception:
            continue

    if hasattr(algo, "config"):
        try:
            algo.config.policies_to_train = list(policies)
        except Exception:
            pass

class RayMultiAgentGodotEnv(MultiAgentEnv):
    def __init__(self, env_config):
        super().__init__()
        self.port = env_config.get("port", 11008)
        self.seed = env_config.get("seed", 42)
        self.env_config = env_config
        self._env = None

        # Get IDs and spaces from unified config
        self._agent_ids = get_agent_ids()
        self.possible_agents = self._agent_ids

        obs_spaces = get_observation_spaces()
        act_spaces = get_action_spaces()

        self.observation_space = gym.spaces.Dict(obs_spaces)
        self.action_space = gym.spaces.Dict(act_spaces)

    def reset(self, *, seed=None, options=None):
        if self._env is None:
            config = {
                "env_path": None,
                "show_window": self.env_config.get("show_window", False),
                "action_repeat": 1,
                "speedup": self.env_config.get("speedup", 10),
            }
            self._env = GodotEnv(
                port=self.port,
                seed=self.seed,
                **config
            )

        obs, info = self._env.reset()
        return {
            "evan":    {"obs": np.array(obs[0]["obs"], dtype=np.float32)},
            "evelyn":  {"obs": np.array(obs[1]["obs"], dtype=np.float32)},
            "team":    {"obs": np.array(obs[2]["obs"], dtype=np.float32)},
            "enemy_0": {"obs": np.array(obs[3]["obs"], dtype=np.float32)},
            "enemy_1": {"obs": np.array(obs[4]["obs"], dtype=np.float32)},
            "enemy_2": {"obs": np.array(obs[5]["obs"], dtype=np.float32)},
            "enemy_3": {"obs": np.array(obs[6]["obs"], dtype=np.float32)},
            "enemy_4": {"obs": np.array(obs[7]["obs"], dtype=np.float32)},
            "enemy_5": {"obs": np.array(obs[8]["obs"], dtype=np.float32)},
        }, {}

    def step(self, action_dict):
        # Map back to Godot list order (must match scene-tree agent registration order)
        # Use .get() with no-op defaults — RLlib may omit agents it considers inactive
        evan_act   = action_dict.get("evan",    {"action": 0, "heal_target": 1})
        evelyn_act = action_dict.get("evelyn",  {"action": 0, "heal_target": 1})
        team_act   = action_dict.get("team",    {"evan_target": 3, "evan_role": 0, "evelyn_target": 3, "evelyn_role": 0})
        e0_act     = action_dict.get("enemy_0", {"action": 0})
        e1_act     = action_dict.get("enemy_1", {"action": 0})
        e2_act     = action_dict.get("enemy_2", {"action": 0})
        e3_act     = action_dict.get("enemy_3", {"action": 0})
        e4_act     = action_dict.get("enemy_4", {"action": 0})
        e5_act     = action_dict.get("enemy_5", {"action": 0})

        actions = [
            [int(evan_act["action"]),   int(evan_act["heal_target"])],
            [int(evelyn_act["action"]), int(evelyn_act["heal_target"])],
            [
                int(team_act["evan_target"]),
                int(team_act["evan_role"]),
                int(team_act["evelyn_target"]),
                int(team_act["evelyn_role"]),
            ],
            [int(e0_act["action"])],
            [int(e1_act["action"])],
            [int(e2_act["action"])],
            [int(e3_act["action"])],
            [int(e4_act["action"])],
            [int(e5_act["action"])],
        ]
        obs, reward, terminated, truncated, info = self._env.step(actions, order_ij=True)

        # Extract custom metrics from info
        # info[i] contains the dict returned by agent.get_statistics()
        res_info = {
            "evan":    info[0] if len(info) > 0 else {},
            "evelyn":  info[1] if len(info) > 1 else {},
            "team":    info[2] if len(info) > 2 else {},
            "enemy_0": info[3] if len(info) > 3 else {},
            "enemy_1": info[4] if len(info) > 4 else {},
            "enemy_2": info[5] if len(info) > 5 else {},
            "enemy_3": info[6] if len(info) > 6 else {},
            "enemy_4": info[7] if len(info) > 7 else {},
            "enemy_5": info[8] if len(info) > 8 else {},
        }

        res_obs = {
            "evan":    {"obs": np.array(obs[0]["obs"], dtype=np.float32)},
            "evelyn":  {"obs": np.array(obs[1]["obs"], dtype=np.float32)},
            "team":    {"obs": np.array(obs[2]["obs"], dtype=np.float32)},
            "enemy_0": {"obs": np.array(obs[3]["obs"], dtype=np.float32)},
            "enemy_1": {"obs": np.array(obs[4]["obs"], dtype=np.float32)},
            "enemy_2": {"obs": np.array(obs[5]["obs"], dtype=np.float32)},
            "enemy_3": {"obs": np.array(obs[6]["obs"], dtype=np.float32)},
            "enemy_4": {"obs": np.array(obs[7]["obs"], dtype=np.float32)},
            "enemy_5": {"obs": np.array(obs[8]["obs"], dtype=np.float32)},
        }
        res_rew = {
            "evan":    reward[0],
            "evelyn":  reward[1],
            "team":    reward[2],
            "enemy_0": reward[3],
            "enemy_1": reward[4],
            "enemy_2": reward[5],
            "enemy_3": reward[6],
            "enemy_4": reward[7],
            "enemy_5": reward[8],
        }
        res_term = {
            "evan":    terminated[0],
            "evelyn":  terminated[1],
            "team":    terminated[2],
            "enemy_0": terminated[3],
            "enemy_1": terminated[4],
            "enemy_2": terminated[5],
            "enemy_3": terminated[6],
            "enemy_4": terminated[7],
            "enemy_5": terminated[8],
            "__all__": all(terminated)
        }
        res_trunc = {
            "evan":    truncated[0],
            "evelyn":  truncated[1],
            "team":    truncated[2],
            "enemy_0": truncated[3],
            "enemy_1": truncated[4],
            "enemy_2": truncated[5],
            "enemy_3": truncated[6],
            "enemy_4": truncated[7],
            "enemy_5": truncated[8],
            "__all__": all(truncated)
        }

        return res_obs, res_rew, res_term, res_trunc, res_info
    
    def close(self):
        if self._env:
            self._env.close()

def env_creator(env_config):
    return RayMultiAgentGodotEnv(env_config)

def main():
    init_ray()
    register_env("godot_multiagent", env_creator)

    print("Python server listening on port 11008 — launch Godot now.")
    print("Launch: godot --headless -- res://prototypes/rl-training/TrainingArena.tscn")

    config = (
        build_base_ppo_config()
        .environment("godot_multiagent", env_config={"port": 11008})
        .multi_agent(
            policies=get_policies(),
            policy_mapping_fn=get_policy_mapping_fn(),
        )
        .training(
            lr=3e-4,
            train_batch_size=12000,  # ~10 episodes at Stage 1; was 4000 (~3 eps) — too noisy
            num_epochs=10,
            entropy_coeff=0.02,     # was 0.01 — more exploration pressure in early training
        )
        .env_runners(num_env_runners=0)
        .resources(num_gpus=1)
    )

    algo = config.build_algo(logger_creator=make_logger_creator("PPO_godot"))

    _PARTY_POLICIES = ["evan_policy", "evelyn_policy", "team_policy"]
    _ENEMY_POLICIES = ["enemy_hive_policy"]
    _ALL_POLICIES   = _PARTY_POLICIES + _ENEMY_POLICIES

    print("Training started. Ctrl+C to stop.")

    # --- Win-rate proxy derived from team_policy reward ---
    # custom_metrics is empty in this RLlib setup, so we map the team policy's
    # per-episode reward to a [0, 1] win-rate proxy using fixed floor/ceiling:
    #   loss scenario  ≈ -8  (on_defeat -5 + on_ally_died -1.5 × 2)
    #   win scenario   ≈ +7  (on_victory +5 + on_enemy_killed +0.5 × 3 + survival)
    # Rolling window smooths single-iter noise so freeze state doesn't flap.
    LOSS_FLOOR = -6.0
    WIN_CEIL   = 6.0
    WR_WINDOW  = 5
    wr_history: list[float] = []

    last_result = {}
    try:
        for iteration in range(500):
            # Compute win-rate proxy from last iteration's team reward
            prev_rewards = last_result.get("env_runners", {}).get("policy_reward_mean", {})
            team_reward_prev = prev_rewards.get("team_policy")
            if isinstance(team_reward_prev, (float, int)):
                wr_instant = max(0.0, min(1.0, (team_reward_prev - LOSS_FLOOR) / (WIN_CEIL - LOSS_FLOOR)))
                wr_history.append(wr_instant)
                if len(wr_history) > WR_WINDOW:
                    wr_history.pop(0)

            # Dynamic policy freezing to maintain ~50% winrate balance
            if iteration > 20 and wr_history:  # Allow initial data gathering
                win_rate = sum(wr_history) / len(wr_history)

                if win_rate < 0.35:
                    # Party losing too much: freeze Enemy, let Party learn
                    to_train = _PARTY_POLICIES
                    status_msg = f" (FREEZE ENEMY | WR: {win_rate*100:.1f}%)"
                elif win_rate > 0.65:
                    # Party winning too much: freeze Party, let Enemy learn
                    to_train = _ENEMY_POLICIES
                    status_msg = f" (FREEZE PARTY | WR: {win_rate*100:.1f}%)"
                else:
                    # Balanced: train everyone
                    to_train = _ALL_POLICIES
                    status_msg = f" (BALANCED | WR: {win_rate*100:.1f}%)"

                _set_policies_to_train(algo, to_train)
            else:
                to_train = _ALL_POLICIES
                status_msg = " (INITIALIZING)"

            result = algo.train()
            last_result = result
            if iteration % 10 == 0:
                reward = result.get('episode_reward_mean')
                reward_str = f"{reward:.3f}" if isinstance(reward, (float, int)) else str(reward)

                wr_display = (sum(wr_history) / len(wr_history) * 100.0) if wr_history else 0.0
                ep_len = result.get('episode_len_mean', 0.0)

                print(f"[{iteration}] reward: {reward_str} | wr: {wr_display:.1f}% | len: {ep_len:.1f}{status_msg}")
            if iteration % 50 == 0:
                save_path = algo.save(MODELS_DIR)
                save_config(save_path)  # Save agent config with checkpoint
                print(f"Checkpoint saved: {save_path}")
    except KeyboardInterrupt:
        print("Training interrupted.")

    final_path = algo.save(os.path.join(MODELS_DIR, "final"))
    save_config(final_path)  # Save agent config with final checkpoint
    print(f"Training complete. Models saved to {MODELS_DIR}")
    ray.shutdown()

if __name__ == "__main__":
    main()
