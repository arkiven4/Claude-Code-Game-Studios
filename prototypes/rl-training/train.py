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
from ray.rllib.algorithms.ppo import PPOConfig
from ray.tune.registry import register_env
from ray.rllib.env.multi_agent_env import MultiAgentEnv
from godot_rl.core.godot_env import GodotEnv

# Import unified config
from agent_config import (
    get_observation_spaces,
    get_action_spaces,
    get_agent_ids,
    get_policies,
    get_policy_mapping_fn,
    save_config,
)

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")
os.makedirs(MODELS_DIR, exist_ok=True)

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
        }

        res_obs = {
            "evan":    {"obs": np.array(obs[0]["obs"], dtype=np.float32)},
            "evelyn":  {"obs": np.array(obs[1]["obs"], dtype=np.float32)},
            "team":    {"obs": np.array(obs[2]["obs"], dtype=np.float32)},
            "enemy_0": {"obs": np.array(obs[3]["obs"], dtype=np.float32)},
            "enemy_1": {"obs": np.array(obs[4]["obs"], dtype=np.float32)},
            "enemy_2": {"obs": np.array(obs[5]["obs"], dtype=np.float32)},
        }
        res_rew = {
            "evan":    reward[0],
            "evelyn":  reward[1],
            "team":    reward[2],
            "enemy_0": reward[3],
            "enemy_1": reward[4],
            "enemy_2": reward[5],
        }
        res_term = {
            "evan":    terminated[0],
            "evelyn":  terminated[1],
            "team":    terminated[2],
            "enemy_0": terminated[3],
            "enemy_1": terminated[4],
            "enemy_2": terminated[5],
            "__all__": all(terminated)
        }
        res_trunc = {
            "evan":    truncated[0],
            "evelyn":  truncated[1],
            "team":    truncated[2],
            "enemy_0": truncated[3],
            "enemy_1": truncated[4],
            "enemy_2": truncated[5],
            "__all__": all(truncated)
        }

        return res_obs, res_rew, res_term, res_trunc, res_info
    
    def close(self):
        if self._env:
            self._env.close()

def env_creator(env_config):
    return RayMultiAgentGodotEnv(env_config)

def main():
    if not ray.is_initialized():
        ray.init()
    
    import torch
    print(f"CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"Using GPU: {torch.cuda.get_device_name(0)}")
    
    register_env("godot_multiagent", env_creator)

    print("Python server listening on port 11008 — launch Godot now.")
    print("Launch: godot --headless -- res://prototypes/rl-training/TrainingArena.tscn")

    config = (
        PPOConfig()
        .api_stack(
            enable_rl_module_and_learner=False,
            enable_env_runner_and_connector_v2=False,
        )
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

    # Redirect logs to project directory
    from ray.tune.logger import UnifiedLogger
    import datetime

    def custom_logger_creator(config):
        base_logdir = os.path.join(os.path.dirname(__file__), "ray_results")
        os.makedirs(base_logdir, exist_ok=True)
        # Create a unique subfolder for this run
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        run_logdir = os.path.join(base_logdir, f"PPO_godot_{timestamp}")
        os.makedirs(run_logdir, exist_ok=True)
        return UnifiedLogger(config, run_logdir)

    algo = config.build_algo(logger_creator=custom_logger_creator)

    print("Training started. Ctrl+C to stop.")
    try:
        for iteration in range(500):
            result = algo.train()
            if iteration % 10 == 0:
                reward = result.get('episode_reward_mean')
                reward_str = f"{reward:.3f}" if isinstance(reward, (float, int)) else str(reward)
                
                # Extract victory metric from custom metrics (team policy)
                # RLlib nested structure: result['custom_metrics']['team_victory_mean']
                custom = result.get('custom_metrics', {})
                win_rate = custom.get('team_victory_mean', 0.0) * 100.0
                ep_len = result.get('episode_len_mean', 0.0)

                print(f"[{iteration}] reward: {reward_str} | wins: {win_rate:.1f}% | len: {ep_len:.1f}")
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
