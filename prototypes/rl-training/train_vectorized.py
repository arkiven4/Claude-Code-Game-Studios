"""
Vectorized Multi-agent RL training for myvampire party AI.
Uses godot_rl v0.8.2 + Ray RLlib (multi-policy).

Instead of N Godot processes, this uses 1 process with N instanced arenas.
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
        self.n_arenas = env_config.get("n_arenas", 4)
        self.env_config = env_config
        self._env = None
        
        self.base_agent_names = ["evan", "evelyn", "team", "enemy_0", "enemy_1", "enemy_2"]
        self._agent_ids = set()
        for i in range(self.n_arenas):
            for name in self.base_agent_names:
                self._agent_ids.add(f"arena_{i}_{name}")
        
        self.possible_agents = self._agent_ids

        # Define individual agent spaces
        obs_48 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (48,), dtype=np.float32)})
        act_party = gym.spaces.Dict({
            "action":      gym.spaces.Discrete(11),
            "heal_target": gym.spaces.Discrete(2),
        })

        obs_33 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (33,), dtype=np.float32)})
        act_team = gym.spaces.Dict({
            "evan_target":   gym.spaces.Discrete(4),
            "evan_role":     gym.spaces.Discrete(3),
            "evelyn_target": gym.spaces.Discrete(4),
            "evelyn_role":   gym.spaces.Discrete(3),
        })

        obs_23 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (23,), dtype=np.float32)})
        act_enemy = gym.spaces.Dict({
            "action": gym.spaces.Discrete(6),
        })

        # Build full MultiAgent dict spaces
        obs_spaces = {}
        act_spaces = {}
        for i in range(self.n_arenas):
            obs_spaces[f"arena_{i}_evan"]    = obs_48
            obs_spaces[f"arena_{i}_evelyn"]  = obs_48
            obs_spaces[f"arena_{i}_team"]    = obs_33
            obs_spaces[f"arena_{i}_enemy_0"] = obs_23
            obs_spaces[f"arena_{i}_enemy_1"] = obs_23
            obs_spaces[f"arena_{i}_enemy_2"] = obs_23
            
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
            config = {
                "env_path": self.env_config.get("env_path"),
                "show_window": self.env_config.get("show_window", False),
                "action_repeat": 1,
                "speedup": self.env_config.get("speedup", 10),
                "user_args": [f"--n_arenas={self.n_arenas}"] if self.env_config.get("env_path") else [],
            }
            self._env = GodotEnv(
                port=self.port,
                seed=self.seed,
                **config
            )

        obs, info = self._env.reset()
        res = {}
        for i in range(self.n_arenas):
            offset = i * 6
            res[f"arena_{i}_evan"]    = {"obs": np.array(obs[offset + 0]["obs"], dtype=np.float32)}
            res[f"arena_{i}_evelyn"]  = {"obs": np.array(obs[offset + 1]["obs"], dtype=np.float32)}
            res[f"arena_{i}_team"]    = {"obs": np.array(obs[offset + 2]["obs"], dtype=np.float32)}
            res[f"arena_{i}_enemy_0"] = {"obs": np.array(obs[offset + 3]["obs"], dtype=np.float32)}
            res[f"arena_{i}_enemy_1"] = {"obs": np.array(obs[offset + 4]["obs"], dtype=np.float32)}
            res[f"arena_{i}_enemy_2"] = {"obs": np.array(obs[offset + 5]["obs"], dtype=np.float32)}
        return res, {}

    def step(self, action_dict):
        # Build flat list of actions for Godot (all arenas)
        actions = []
        for i in range(self.n_arenas):
            prefix = f"arena_{i}_"
            evan_act   = action_dict.get(prefix + "evan",    {"action": 0, "heal_target": 1})
            evelyn_act = action_dict.get(prefix + "evelyn",  {"action": 0, "heal_target": 1})
            team_act   = action_dict.get(prefix + "team",    {"evan_target": 3, "evan_role": 0, "evelyn_target": 3, "evelyn_role": 0})
            e0_act     = action_dict.get(prefix + "enemy_0", {"action": 0})
            e1_act     = action_dict.get(prefix + "enemy_1", {"action": 0})
            e2_act     = action_dict.get(prefix + "enemy_2", {"action": 0})

            actions.append([int(evan_act["action"]), int(evan_act["heal_target"])])
            actions.append([int(evelyn_act["action"]), int(evelyn_act["heal_target"])])
            actions.append([
                int(team_act["evan_target"]), int(team_act["evan_role"]),
                int(team_act["evelyn_target"]), int(team_act["evelyn_role"]),
            ])
            actions.append([int(e0_act["action"])])
            actions.append([int(e1_act["action"])])
            actions.append([int(e2_act["action"])])

        obs, reward, terminated, truncated, info = self._env.step(actions, order_ij=True)

        res_obs = {}
        res_rew = {}
        res_term = {}
        res_trunc = {}
        res_info = {}
        
        for i in range(self.n_arenas):
            offset = i * 6
            prefix = f"arena_{i}_"
            
            res_obs[prefix + "evan"]    = {"obs": np.array(obs[offset + 0]["obs"], dtype=np.float32)}
            res_obs[prefix + "evelyn"]  = {"obs": np.array(obs[offset + 1]["obs"], dtype=np.float32)}
            res_obs[prefix + "team"]    = {"obs": np.array(obs[offset + 2]["obs"], dtype=np.float32)}
            res_obs[prefix + "enemy_0"] = {"obs": np.array(obs[offset + 3]["obs"], dtype=np.float32)}
            res_obs[prefix + "enemy_1"] = {"obs": np.array(obs[offset + 4]["obs"], dtype=np.float32)}
            res_obs[prefix + "enemy_2"] = {"obs": np.array(obs[offset + 5]["obs"], dtype=np.float32)}
            
            res_rew[prefix + "evan"]    = reward[offset + 0]
            res_rew[prefix + "evelyn"]  = reward[offset + 1]
            res_rew[prefix + "team"]    = reward[offset + 2]
            res_rew[prefix + "enemy_0"] = reward[offset + 3]
            res_rew[prefix + "enemy_1"] = reward[offset + 4]
            res_rew[prefix + "enemy_2"] = reward[offset + 5]
            
            res_term[prefix + "evan"]    = terminated[offset + 0]
            res_term[prefix + "evelyn"]  = terminated[offset + 1]
            res_term[prefix + "team"]    = terminated[offset + 2]
            res_term[prefix + "enemy_0"] = terminated[offset + 3]
            res_term[prefix + "enemy_1"] = terminated[offset + 4]
            res_term[prefix + "enemy_2"] = terminated[offset + 5]
            
            res_trunc[prefix + "evan"]    = truncated[offset + 0]
            res_trunc[prefix + "evelyn"]  = truncated[offset + 1]
            res_trunc[prefix + "team"]    = truncated[offset + 2]
            res_trunc[prefix + "enemy_0"] = truncated[offset + 3]
            res_trunc[prefix + "enemy_1"] = truncated[offset + 4]
            res_trunc[prefix + "enemy_2"] = truncated[offset + 5]

            res_info[prefix + "evan"]    = info[offset + 0] if len(info) > offset + 0 else {}
            res_info[prefix + "evelyn"]  = info[offset + 1] if len(info) > offset + 1 else {}
            res_info[prefix + "team"]    = info[offset + 2] if len(info) > offset + 2 else {}
            res_info[prefix + "enemy_0"] = info[offset + 3] if len(info) > offset + 3 else {}
            res_info[prefix + "enemy_1"] = info[offset + 4] if len(info) > offset + 4 else {}
            res_info[prefix + "enemy_2"] = info[offset + 5] if len(info) > offset + 5 else {}

        # Synchronous reset: only terminate the environment when ALL agents in ALL arenas are done
        # (Though in practice, godot_rl usually resets the whole process when reset is requested)
        res_term["__all__"] = all(terminated)
        res_trunc["__all__"] = all(truncated)

        return res_obs, res_rew, res_term, res_trunc, res_info
    
    def close(self):
        if self._env:
            self._env.close()

def env_creator(env_config):
    return RayMultiAgentGodotEnv(env_config)

def main():
    if not ray.is_initialized():
        ray.init()
    
    register_env("godot_vec_multiagent", env_creator)

    # Use 4 arenas for vecenv by default
    n_arenas = 4
    print(f"Vectorized Training started with {n_arenas} arenas.")
    print("Waiting for Godot to connect on port 11008 ...")
    print(f"Launch: godot --headless -- res://prototypes/rl-training/VectorizedTraining.tscn --n_arenas={n_arenas}")

    config = (
        PPOConfig()
        .api_stack(
            enable_rl_module_and_learner=False,
            enable_env_runner_and_connector_v2=False,
        )
        .environment("godot_vec_multiagent", env_config={"port": 11008, "n_arenas": n_arenas})
        .multi_agent(
            policies={
                "evan_policy":       (None, None, None, {}),
                "evelyn_policy":     (None, None, None, {}),
                "team_policy":       (None, None, None, {}),
                "enemy_hive_policy": (None, None, None, {}),
            },
            policy_mapping_fn=lambda agent_id, *args, **kwargs: (
                "enemy_hive_policy" if "_enemy_" in agent_id else 
                "evan_policy" if "_evan" in agent_id else
                "evelyn_policy" if "_evelyn" in agent_id else
                "team_policy"
            ),
        )
        .training(
            lr=3e-4,
            train_batch_size=4000 * n_arenas, # Scale batch size with arenas
            num_epochs=10,
            entropy_coeff=0.01,
        )
        .env_runners(num_env_runners=0)
        .resources(num_gpus=1)
    )

    from ray.tune.logger import UnifiedLogger
    import datetime

    def custom_logger_creator(config):
        base_logdir = os.path.join(os.path.dirname(__file__), "ray_results")
        os.makedirs(base_logdir, exist_ok=True)
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        run_logdir = os.path.join(base_logdir, f"PPO_vec_{timestamp}")
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

    algo.save(os.path.join(MODELS_DIR, "final_vec"))
    print(f"Training complete. Models saved to {MODELS_DIR}")
    ray.shutdown()

if __name__ == "__main__":
    main()
