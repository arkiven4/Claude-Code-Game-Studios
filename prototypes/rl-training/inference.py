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

# Add current script directory to path so we can import modules
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.append(script_dir)

from train import RayMultiAgentGodotEnv
from agent_config import (
    get_observation_spaces,
    get_action_spaces,
    get_agent_ids,
    get_policies_with_spaces,
    get_policy_mapping_fn,
    load_config,
)

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

    # Load agent config from checkpoint (or use current if not found)
    print(f"DEBUG: Loading agent config from {args.checkpoint}...")
    obs_spaces, act_spaces, agent_ids = load_config(args.checkpoint)
    print(f"DEBUG: Loaded config for agents: {agent_ids}")

    # Build policies with loaded spaces
    policies = {}
    for policy_name in ["evan_policy", "evelyn_policy", "team_policy", "enemy_hive_policy"]:
        if policy_name == "evan_policy":
            policies[policy_name] = (None, obs_spaces["evan"], act_spaces["evan"], {})
        elif policy_name == "evelyn_policy":
            policies[policy_name] = (None, obs_spaces["evelyn"], act_spaces["evelyn"], {})
        elif policy_name == "team_policy":
            policies[policy_name] = (None, obs_spaces["team"], act_spaces["team"], {})
        elif policy_name == "enemy_hive_policy":
            policies[policy_name] = (None, obs_spaces["enemy_0"], act_spaces["enemy_0"], {})

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
            policies=policies,
            policy_mapping_fn=get_policy_mapping_fn(),
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
