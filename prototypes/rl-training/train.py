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
        self.env_config = env_config
        self._env = None
        
        # Define IDs for space initialization
        self._agent_ids = {"evan", "evelyn", "team", "enemy_0", "enemy_1", "enemy_2"}
        self.possible_agents = self._agent_ids

        # Evan/Evelyn Spaces
        obs_48 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (48,), dtype=np.float32)})
        act_party = gym.spaces.Dict({
            "action":      gym.spaces.Discrete(11),  # 0=wait,1-4=skills,5-8=movement,9=basic,10=special
            "heal_target": gym.spaces.Discrete(2),  # 0=self, 1=lowest-HP ally
        })

        # Team Spaces
        obs_33 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (33,), dtype=np.float32)})
        act_team = gym.spaces.Dict({
            "evan_target":   gym.spaces.Discrete(4),
            "evan_role":     gym.spaces.Discrete(3),
            "evelyn_target": gym.spaces.Discrete(4),
            "evelyn_role":   gym.spaces.Discrete(3),
        })

        # Enemy Hive Spaces (shared policy, 3 separate agents)
        obs_23 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (23,), dtype=np.float32)})
        act_enemy = gym.spaces.Dict({
            "action": gym.spaces.Discrete(6),  # 0=wait,1=skill0,2=skill1,3-5=movement
        })

        self.observation_space = gym.spaces.Dict({
            "evan":    obs_48,
            "evelyn":  obs_48,
            "team":    obs_33,
            "enemy_0": obs_23,
            "enemy_1": obs_23,
            "enemy_2": obs_23,
        })
        self.action_space = gym.spaces.Dict({
            "evan":    act_party,
            "evelyn":  act_party,
            "team":    act_team,
            "enemy_0": act_enemy,
            "enemy_1": act_enemy,
            "enemy_2": act_enemy,
        })

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

        return res_obs, res_rew, res_term, res_trunc, {}
    
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
                "evan_policy":       (None, None, None, {}),
                "evelyn_policy":     (None, None, None, {}),
                "team_policy":       (None, None, None, {}),
                "enemy_hive_policy": (None, None, None, {}),
            },
            policy_mapping_fn=lambda agent_id, *args, **kwargs: (
                "enemy_hive_policy" if agent_id.startswith("enemy_") else f"{agent_id}_policy"
            ),
        )
        .training(
            lr=3e-4,
            train_batch_size=4000,
            num_epochs=10,
            entropy_coeff=0.01,
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
