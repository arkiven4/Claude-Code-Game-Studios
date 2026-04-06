"""
Inference script for myvampire party AI.
Loads a trained checkpoint and runs the InferenceArena.tscn.

Usage:
  Terminal 1:
    python3.10 prototypes/rl-training/inference.py --checkpoint prototypes/rl-training/models/checkpoint_XXXXXX

  Terminal 2:
    godot -- res://prototypes/rl-training/InferenceArena.tscn
"""

import os
import argparse
import ray
import numpy as np
from ray.rllib.algorithms.ppo import PPOConfig
from ray.tune.registry import register_env
import sys
# Add current script directory to path so we can import train.py
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.append(script_dir)

from train import RayMultiAgentGodotEnv

def env_creator(env_config):
    # Set show_window=True for inference and speedup=1.0
    env_config["show_window"] = True
    env_config["speedup"] = 1.0
    return RayMultiAgentGodotEnv(env_config)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--checkpoint", type=str, required=True, help="Path to the checkpoint folder")
    parser.add_argument("--port", type=int, default=11008, help="Port to connect to Godot")
    args = parser.parse_args()

    if not ray.is_initialized():
        ray.init()

    register_env("godot_multiagent", env_creator)

    # Reconstruct the config (must match train.py)
    config = (
        PPOConfig()
        .api_stack(
            enable_rl_module_and_learner=False,
            enable_env_runner_and_connector_v2=False,
        )
        .environment("godot_multiagent", env_config={"port": args.port})
        .multi_agent(
            policies={
                "evan_policy":   (None, None, None, {}),
                "evelyn_policy": (None, None, None, {}),
                "team_policy":   (None, None, None, {}),
            },
            policy_mapping_fn=lambda agent_id, *args, **kwargs: f"{agent_id}_policy",
        )
        .env_runners(num_env_runners=0)
    )

    # Build the algorithm and restore from checkpoint
    algo = config.build_algo()
    
    checkpoint_path = os.path.abspath(args.checkpoint)
    if not os.path.exists(checkpoint_path):
        print(f"ERROR: Checkpoint path does not exist: {checkpoint_path}")
        return
        
    algo.restore(checkpoint_path)

    print(f"Checkpoint restored from {args.checkpoint}")
    print(f"Waiting for Godot to connect on port {args.port} ...")
    print("Launch: godot -- res://prototypes/rl-training/InferenceArena.tscn")

    env = RayMultiAgentGodotEnv({"port": args.port, "speedup": 1.0, "show_window": True})
    obs, info = env.reset()

    print("Running inference. Close Godot window to stop.")
    try:
        while True:
            # Compute actions for all agents
            action_dict = {}
            for agent_id, agent_obs in obs.items():
                policy_id = f"{agent_id}_policy"
                action_dict[agent_id] = algo.compute_single_action(
                    agent_obs, 
                    policy_id=policy_id,
                    explore=False # No exploration during inference
                )
            
            obs, rewards, terminated, truncated, info = env.step(action_dict)
            
            if terminated["__all__"] or truncated["__all__"]:
                obs, info = env.reset()
    except KeyboardInterrupt:
        print("Inference stopped.")
    finally:
        env.close()
        ray.shutdown()

if __name__ == "__main__":
    main()
