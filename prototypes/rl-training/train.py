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
    godot --headless -- res://prototypes/rl-training/TrainingArena.tscn \
      --speedup=10 --fixed-fps=2000 --disable-render-loop

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

class RayMultiAgentGodotEnv(MultiAgentEnv):
    def __init__(self, env_config):
        super().__init__()
        self.port = env_config.get("port", 11008)
        self.seed = env_config.get("seed", 42)
        config = {
            "env_path": None,
            "show_window": False,
            "action_repeat": 1,
            "speedup": 10,
        }
        self._env = GodotEnv(
            port=self.port,
            seed=self.seed,
            **config
        )
        
        # Based on TrainingArena.tscn structure:
        # Agent 0: Evan (obs 46, act 9)
        # Agent 1: Evelyn (obs 46, act 9)
        # Agent 2: Team (obs 33, multi-head act)
        self._agent_ids = ["evan", "evelyn", "team"]
        
        # Evan/Evelyn Spaces
        obs_46 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (46,), dtype=np.float32)})
        act_9 = gym.spaces.Discrete(9)
        
        # Team Spaces
        obs_33 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (33,), dtype=np.float32)})
        act_team = gym.spaces.Dict({
            "evan_target": gym.spaces.Discrete(4),
            "evan_role": gym.spaces.Discrete(3),
            "evelyn_target": gym.spaces.Discrete(4),
            "evelyn_role": gym.spaces.Discrete(3),
        })
        
        self.observation_space = gym.spaces.Dict({
            "evan": obs_46,
            "evelyn": obs_46,
            "team": obs_33,
        })
        self.action_space = gym.spaces.Dict({
            "evan": act_9,
            "evelyn": act_9,
            "team": act_team,
        })

    def reset(self, *, seed=None, options=None):
        obs, info = self._env.reset()
        return {
            "evan": {"obs": np.array(obs[0]["obs"], dtype=np.float32)},
            "evelyn": {"obs": np.array(obs[1]["obs"], dtype=np.float32)},
            "team": {"obs": np.array(obs[2]["obs"], dtype=np.float32)},
        }, {}

    def step(self, action_dict):
        # Map back to Godot list order
        # GodotEnv.from_numpy expects action[agent_idx][head_idx] when order_ij=True
        evan_act = action_dict["evan"]
        evelyn_act = action_dict["evelyn"]
        team_act = action_dict["team"]
        
        actions = [
            [int(evan_act)],
            [int(evelyn_act)],
            [
                int(team_act["evan_target"]),
                int(team_act["evan_role"]),
                int(team_act["evelyn_target"]),
                int(team_act["evelyn_role"]),
            ],
        ]
        obs, reward, terminated, truncated, info = self._env.step(actions, order_ij=True)
        
        res_obs = {
            "evan": {"obs": np.array(obs[0]["obs"], dtype=np.float32)},
            "evelyn": {"obs": np.array(obs[1]["obs"], dtype=np.float32)},
            "team": {"obs": np.array(obs[2]["obs"], dtype=np.float32)},
        }
        res_rew = {"evan": reward[0], "evelyn": reward[1], "team": reward[2]}
        res_term = {
            "evan": terminated[0], 
            "evelyn": terminated[1], 
            "team": terminated[2],
            "__all__": all(terminated)
        }
        res_trunc = {
            "evan": truncated[0], 
            "evelyn": truncated[1], 
            "team": truncated[2],
            "__all__": all(truncated)
        }
        
        return res_obs, res_rew, res_term, res_trunc, {}
    
    def close(self):
        self._env.close()

def env_creator(env_config):
    return RayMultiAgentGodotEnv(env_config)

def main():
    if not ray.is_initialized():
        ray.init()
    
    register_env("godot_multiagent", env_creator)

    print("Waiting for Godot to connect on port 11008 ...")
    print("Launch: godot --headless -- res://prototypes/rl-training/TrainingArena.tscn")

    config = (
        PPOConfig()
        .api_stack(
            enable_rl_module_and_learner=False,
            enable_env_runner_and_connector_v2=False,
        )
        .environment("godot_multiagent", env_config={"port": 11008})
        .multi_agent(
            policies={
                "evan_policy":   (None, None, None, {}),
                "evelyn_policy": (None, None, None, {}),
                "team_policy":   (None, None, None, {}),
            },
            policy_mapping_fn=lambda agent_id, *args, **kwargs: f"{agent_id}_policy",
        )
        .training(
            lr=3e-4,
            train_batch_size=4000,
            num_epochs=10,
            entropy_coeff=0.01,
        )
        .env_runners(num_env_runners=0)
        .resources(num_gpus=0)
    )

    algo = config.build_algo()

    print("Training started. Ctrl+C to stop.")
    try:
        for iteration in range(500):
            result = algo.train()
            if iteration % 10 == 0:
                reward = result.get('episode_reward_mean')
                reward_str = f"{reward:.3f}" if isinstance(reward, (float, int)) else str(reward)
                print(f"[{iteration}] reward_mean: {reward_str}")
            if iteration % 50 == 0:
                save_path = algo.save(MODELS_DIR)
                print(f"Checkpoint saved: {save_path}")
    except KeyboardInterrupt:
        print("Training interrupted.")

    algo.save(os.path.join(MODELS_DIR, "final"))
    print(f"Training complete. Models saved to {MODELS_DIR}")
    ray.shutdown()

if __name__ == "__main__":
    main()
