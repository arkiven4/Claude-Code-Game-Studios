"""
Shared training utilities for train.py, train_vectorized.py, and inference.py.
"""

import os
import datetime

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")
os.makedirs(MODELS_DIR, exist_ok=True)


def init_ray(logging_level: str = "warning") -> None:
    """Initialize Ray (if not already running) and print CUDA info."""
    import ray
    if not ray.is_initialized():
        ray.init(logging_level=logging_level)

    try:
        import torch
        print(f"CUDA available: {torch.cuda.is_available()}")
        if torch.cuda.is_available():
            print(f"Using GPU: {torch.cuda.get_device_name(0)}")
    except ImportError:
        pass


def make_logger_creator(run_prefix: str = "PPO"):
    """Return an RLlib logger creator that saves logs under ray_results/."""
    from ray.tune.logger import UnifiedLogger

    def _creator(config):
        base = os.path.join(os.path.dirname(__file__), "ray_results")
        os.makedirs(base, exist_ok=True)
        ts = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        run_dir = os.path.join(base, f"{run_prefix}_{ts}")
        os.makedirs(run_dir, exist_ok=True)
        return UnifiedLogger(config, run_dir)

    return _creator


def build_base_ppo_config():
    """Return a PPOConfig with the legacy API stack (godot_rl compatibility)."""
    from ray.rllib.algorithms.ppo import PPOConfig

    return PPOConfig().api_stack(
        enable_rl_module_and_learner=False,
        enable_env_runner_and_connector_v2=False,
    )
