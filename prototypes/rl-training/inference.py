"""
Inference script for myvampire party AI.
Loads a trained checkpoint and runs the InferenceArena.tscn.

Usage:
  Terminal 1 (Python):
    python3.10 prototypes/rl-training/inference.py --checkpoint prototypes/rl-training/models/checkpoint_XXXXXX

  Terminal 2 (Godot):
        godot res://prototypes/rl-training/InferenceArena.tscn -- --port=11008 --speedup=10
"""

import os
import argparse
import ray
import numpy as np
import gymnasium as gym
from ray.rllib.algorithms.ppo import PPOConfig
from ray.tune.registry import register_env
import sys

# Add current script directory to path so we can import train.py
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.append(script_dir)

from train import RayMultiAgentGodotEnv

def env_creator(env_config):
    # This creator is used by RLlib internally to initialize spaces
    # We use a dummy mode or just return the env class
    return RayMultiAgentGodotEnv(env_config)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--checkpoint", type=str, required=True, help="Path to the checkpoint folder")
    parser.add_argument("--port", type=int, default=11008, help="Port to connect to Godot")
    parser.add_argument("--speedup", type=float, default=10.0, help="Godot simulation speedup")
    args = parser.parse_args()

    print("DEBUG: Initializing Ray...")
    if not ray.is_initialized():
        ray.init(logging_level="error")
    print("DEBUG: Ray initialized.")

    # Define spaces explicitly — must match train.py exactly
    # 54 = self(10) + casting(2) + allies×3(15) + enemies×4(20) + directive(7)
    obs_54 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (54,), dtype=np.float32)})
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
    # 25 = self(5) + party×2(10) + enemy_allies×2(10: added dist)
    obs_25 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (25,), dtype=np.float32)})
    act_enemy = gym.spaces.Dict({
        "action": gym.spaces.Discrete(6),
    })

    print("DEBUG: Registering environment...")
    register_env("godot_multiagent", env_creator)

    print("DEBUG: Setting up PPOConfig...")
    config = (
        PPOConfig()
        .api_stack(
            enable_rl_module_and_learner=False,
            enable_env_runner_and_connector_v2=False,
        )
        .environment("godot_multiagent", env_config={"port": args.port})
        .multi_agent(
            policies={
                "evan_policy":       (None, obs_54, act_party, {}),
                "evelyn_policy":     (None, obs_54, act_party, {}),
                "team_policy":       (None, obs_33, act_team, {}),
                "enemy_hive_policy": (None, obs_25, act_enemy, {}),
            },
            policy_mapping_fn=lambda agent_id, *args, **kwargs: (
                "enemy_hive_policy" if agent_id.startswith("enemy_") else f"{agent_id}_policy"
            ),
        )
        .env_runners(num_env_runners=0)
    )

    print("DEBUG: Building algorithm (this should not wait for Godot)...")
    algo = config.build_algo()
    print("DEBUG: Algorithm built.")
    
    checkpoint_path = os.path.abspath(args.checkpoint)
    if not os.path.exists(checkpoint_path):
        # Try finding it if user passed a folder containing the checkpoint
        if os.path.exists(os.path.join(checkpoint_path, "checkpoint_000000")): # Example
             checkpoint_path = os.path.join(checkpoint_path, "checkpoint_000000")

    print(f"Restoring checkpoint from {checkpoint_path} ...")
    algo.restore(checkpoint_path)

    print(f"Waiting for Godot to connect on port {args.port} ...")
    print(
        "RUN THIS: godot res://prototypes/rl-training/InferenceArena.tscn "
        f"-- --port={args.port} --speedup={args.speedup:g}"
    )

    # Now create the actual environment that connects to Godot
    env = RayMultiAgentGodotEnv({"port": args.port, "speedup": args.speedup, "show_window": True})
    obs, info = env.reset()

    total_episodes = 0
    party_wins = 0

    print("Running inference. Close Godot window to stop.")
    try:
        while True:
            action_dict = {}
            for agent_id, agent_obs in obs.items():
                policy_id = (
                    "enemy_hive_policy" if agent_id.startswith("enemy_") 
                    else f"{agent_id}_policy"
                )
                action_dict[agent_id] = algo.compute_single_action(
                    agent_obs, 
                    policy_id=policy_id,
                    explore=False
                )
            
            obs, rewards, terminated, truncated, info = env.step(action_dict)
            
            if terminated["__all__"] or truncated["__all__"]:
                total_episodes += 1
                if rewards.get("team", 0) > 0:
                    party_wins += 1
                
                wr = (party_wins / total_episodes) * 100
                print(f"Episode {total_episodes} finished. Win: {rewards.get('team', 0) > 0}. Win Rate: {wr:.1f}%")
                
                obs, info = env.reset()
    except KeyboardInterrupt:
        print("Inference stopped.")
    finally:
        env.close()
        ray.shutdown()

if __name__ == "__main__":
    main()
