"""
Unified agent configuration for training and inference.
Single source of truth for observation/action spaces, agent IDs, and policies.
"""

import gymnasium as gym
import numpy as np
import json
import os


# =============================================================================
# SPACE DEFINITIONS (edit here, everywhere uses it automatically)
# =============================================================================

def get_observation_spaces():
    """Return dict of observation spaces for all agents."""
    # Party agents: 54 = self(10) + casting(2) + allies×3(15) + enemies×4(20) + directive(7)
    obs_54 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (54,), dtype=np.float32)})

    # Team coordinator: 33 = evan(3) + evelyn(3) + enemies×4(20) + combat(3) + memory(4)
    obs_33 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (33,), dtype=np.float32)})

    # Enemies: 29 = self(5) + party×2(14: hp,dist,alive,rel_x,rel_z,is_casting,mp_ratio) + enemy_allies×2(10)
    obs_29 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (29,), dtype=np.float32)})

    return {
        "evan":    obs_54,
        "evelyn":  obs_54,
        "team":    obs_33,
        "enemy_0": obs_29,
        "enemy_1": obs_29,
        "enemy_2": obs_29,
        "enemy_3": obs_29,
        "enemy_4": obs_29,
        "enemy_5": obs_29,
    }


def get_action_spaces():
    """Return dict of action spaces for all agents."""
    # Party character actions
    #   0      = wait
    #   1-4    = skill slots 1-4
    #   5      = move toward directive enemy
    #   6      = move away from nearest enemy
    #   7      = move toward lowest-HP ally
    #   8      = hold (no-op, penalised like wait)
    #   9      = basic attack
    #   10     = special attack
    #   11-18  = 8-way cardinal movement (N, NE, E, SE, S, SW, W, NW)
    #   19     = dash (consumes MP, invincible for dash_duration)
    act_party = gym.spaces.Dict({
        "action":      gym.spaces.Discrete(20),
        "heal_target": gym.spaces.Discrete(2),   # 0=self, 1=lowest-HP ally
    })

    # Team coordinator actions
    act_team = gym.spaces.Dict({
        "evan_target":   gym.spaces.Discrete(4),
        "evan_role":     gym.spaces.Discrete(3),
        "evelyn_target": gym.spaces.Discrete(4),
        "evelyn_role":   gym.spaces.Discrete(3),
    })

    # Enemy hive actions (shared policy)
    act_enemy = gym.spaces.Dict({
        "action": gym.spaces.Discrete(6),  # 0=wait, 1=skill0, 2=skill1, 3-5=movement
    })

    return {
        "evan":    act_party,
        "evelyn":  act_party,
        "team":    act_team,
        "enemy_0": act_enemy,
        "enemy_1": act_enemy,
        "enemy_2": act_enemy,
        "enemy_3": act_enemy,
        "enemy_4": act_enemy,
        "enemy_5": act_enemy,
    }


def get_agent_ids():
    """Return the set of all agent IDs."""
    return {"evan", "evelyn", "team", "enemy_0", "enemy_1", "enemy_2", "enemy_3", "enemy_4", "enemy_5"}


def get_base_agents():
    """Return list of base agent names (for vectorized training)."""
    return ["evan", "evelyn", "team", "enemy_0", "enemy_1", "enemy_2", "enemy_3", "enemy_4", "enemy_5"]


def get_policy_mapping_fn():
    """Return the policy mapping function for multi-agent setup."""
    return lambda agent_id, *args, **kwargs: (
        "enemy_hive_policy" if agent_id.startswith("enemy_") else f"{agent_id}_policy"
    )


def get_policies():
    """Return policy definitions for RLlib (training mode - spaces are None)."""
    return {
        "evan_policy":       (None, None, None, {}),
        "evelyn_policy":     (None, None, None, {}),
        "team_policy":       (None, None, None, {}),
        "enemy_hive_policy": (None, None, None, {}),
    }


def get_policies_with_spaces(obs_spaces=None, act_spaces=None):
    """Return policy definitions with explicit spaces (inference mode).
    Pass loaded spaces from load_config() or leave None to use current definitions.
    """
    if obs_spaces is None:
        obs_spaces = get_observation_spaces()
    if act_spaces is None:
        act_spaces = get_action_spaces()

    return {
        "evan_policy":       (None, obs_spaces["evan"],    act_spaces["evan"],    {}),
        "evelyn_policy":     (None, obs_spaces["evelyn"],  act_spaces["evelyn"],  {}),
        "team_policy":       (None, obs_spaces["team"],    act_spaces["team"],    {}),
        "enemy_hive_policy": (None, obs_spaces["enemy_0"], act_spaces["enemy_0"], {}),
    }


# =============================================================================
# CONFIG SERIALIZATION (for checkpoint persistence)
# =============================================================================

def _serialize_space_to_dict(space):
    """Convert a gym.spaces object to a JSON-serializable dict."""
    if isinstance(space, gym.spaces.Dict):
        return {
            "type": "Dict",
            "spaces": {k: _serialize_space_to_dict(v) for k, v in space.spaces.items()},
        }
    elif isinstance(space, gym.spaces.Box):
        return {
            "type": "Box",
            "low": float(space.low.flat[0]) if np.all(space.low == space.low.flat[0]) else space.low.tolist(),
            "high": float(space.high.flat[0]) if np.all(space.high == space.high.flat[0]) else space.high.tolist(),
            "shape": list(space.shape),
            "dtype": str(space.dtype),
        }
    elif isinstance(space, gym.spaces.Discrete):
        return {
            "type": "Discrete",
            "n": int(space.n),
        }
    else:
        raise ValueError(f"Unsupported space type: {type(space)}")


def _deserialize_space_from_dict(d):
    """Reconstruct a gym.spaces object from a dict."""
    if d["type"] == "Dict":
        return gym.spaces.Dict({k: _deserialize_space_from_dict(v) for k, v in d["spaces"].items()})
    elif d["type"] == "Box":
        return gym.spaces.Box(low=d["low"], high=d["high"], shape=tuple(d["shape"]), dtype=d["dtype"])
    elif d["type"] == "Discrete":
        return gym.spaces.Discrete(n=d["n"])
    else:
        raise ValueError(f"Unsupported space type: {d['type']}")


def _extract_checkpoint_path(checkpoint_dir):
    """Normalize whatever algo.save() returned into a filesystem path string.

    Ray's Algorithm.save() return type changed across versions:
      - Ray  < 2.10: returns str path directly.
      - Ray >= 2.10: returns a TrainingResult / _TrainingResult with
                     .checkpoint.path (Checkpoint object) or sometimes .path.
    This helper handles all known shapes so callers don't have to care.
    """
    if isinstance(checkpoint_dir, (str, bytes, os.PathLike)):
        return checkpoint_dir
    # Newer Ray: _TrainingResult wraps a Checkpoint
    checkpoint = getattr(checkpoint_dir, "checkpoint", None)
    if checkpoint is not None:
        path = getattr(checkpoint, "path", None)
        if path is not None:
            return path
    # Some versions return a Checkpoint directly (has .path)
    path = getattr(checkpoint_dir, "path", None)
    if path is not None:
        return path
    # Last resort — will at least produce a debuggable error later
    return str(checkpoint_dir)


def save_config(checkpoint_dir):
    """
    Save agent configuration to checkpoint directory as agent_config.json.
    Called after training creates a checkpoint.

    Accepts either a string path (older Ray) or a TrainingResult / Checkpoint
    object (newer Ray). The return type of algo.save() is normalized here.
    """
    checkpoint_dir = _extract_checkpoint_path(checkpoint_dir)

    config = {
        "agent_ids": sorted(list(get_agent_ids())),
        "observation_spaces": {
            agent_id: _serialize_space_to_dict(space)
            for agent_id, space in get_observation_spaces().items()
        },
        "action_spaces": {
            agent_id: _serialize_space_to_dict(space)
            for agent_id, space in get_action_spaces().items()
        },
    }

    config_path = os.path.join(checkpoint_dir, "agent_config.json")
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)

    return config_path


def load_config(checkpoint_dir):
    """
    Load agent configuration from checkpoint directory.
    Returns (observation_spaces, action_spaces, agent_ids).
    """
    config_path = os.path.join(checkpoint_dir, "agent_config.json")

    if not os.path.exists(config_path):
        # Fallback: use current definitions
        print(f"Warning: {config_path} not found. Using current agent_config.py definitions.")
        return get_observation_spaces(), get_action_spaces(), get_agent_ids()

    with open(config_path, "r") as f:
        config = json.load(f)

    obs_spaces = {
        agent_id: _deserialize_space_from_dict(space_dict)
        for agent_id, space_dict in config["observation_spaces"].items()
    }
    act_spaces = {
        agent_id: _deserialize_space_from_dict(space_dict)
        for agent_id, space_dict in config["action_spaces"].items()
    }
    agent_ids = set(config["agent_ids"])

    return obs_spaces, act_spaces, agent_ids
