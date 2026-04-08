# Unified Agent Configuration

## Problem Solved

Previously, agent spaces (observations/actions) were **duplicated across three files**:
- `train.py` — defined spaces locally
- `train_vectorized.py` — redefined spaces (with inconsistency: obs_29 vs obs_25 for enemies)
- `inference.py` — redefined spaces (hardcoded in setup)

Any change to spaces required editing **all three files**, risking inconsistencies.

## Solution

### Single Source of Truth: `agent_config.py`

All space definitions now live in one place:

```python
from agent_config import (
    get_observation_spaces(),    # Returns dict of observation spaces
    get_action_spaces(),         # Returns dict of action spaces
    get_agent_ids(),             # Returns set of agent IDs
    get_base_agents(),           # Returns list of base agent names
    get_policy_mapping_fn(),     # Returns policy mapping function
    get_policies(),              # For training (spaces=None)
    get_policies_with_spaces(),  # For inference (spaces explicit)
    save_config(checkpoint_dir), # Save config to checkpoint
    load_config(checkpoint_dir), # Load config from checkpoint
)
```

### How It Works

#### Training

```bash
# train.py
from agent_config import get_observation_spaces, get_action_spaces, save_config

# ... define env using unified spaces ...

if iteration % 50 == 0:
    save_path = algo.save(MODELS_DIR)
    save_config(save_path)  # Saves agent_config.json to checkpoint
```

The training script saves `agent_config.json` with each checkpoint, persisting the exact spaces used during training.

#### Inference

```bash
# inference.py
from agent_config import load_config

# Load config from checkpoint (or use current if not found)
obs_spaces, act_spaces, agent_ids = load_config(args.checkpoint)

# Use loaded spaces to configure policies
policies = {
    "evan_policy": (None, obs_spaces["evan"], act_spaces["evan"], {}),
    ...
}
```

The inference script **loads the spaces from the checkpoint**, ensuring perfect alignment with how the model was trained.

### What Gets Saved

Each checkpoint now includes `agent_config.json`:

```json
{
  "agent_ids": ["evan", "evelyn", "team", "enemy_0", "enemy_1", "enemy_2"],
  "observation_spaces": {
    "evan": {"type": "Dict", "spaces": {...}},
    "evelyn": {...},
    ...
  },
  "action_spaces": {
    "evan": {...},
    ...
  }
}
```

## Workflow

### To Add/Change a Space

1. Edit `agent_config.py` only:

```python
# Example: change enemy observation size from 25 to 30
obs_30 = gym.spaces.Dict({"obs": gym.spaces.Box(-10.0, 10.0, (30,), dtype=np.float32)})

return {
    ...
    "enemy_0": obs_30,  # ← changed
    ...
}
```

2. Train a new checkpoint:

```bash
python3.10 train.py
# or
python3.10 train_vectorized.py
```

The config is automatically saved with the checkpoint.

3. Inference automatically loads the new spaces:

```bash
python3.10 inference.py --checkpoint prototypes/rl-training/models/checkpoint_XXXXX
# Loads agent_config.json from checkpoint, uses correct spaces
```

**No need to edit `inference.py` or `train_vectorized.py`.**

## Backward Compatibility

If you restore an **old checkpoint** without `agent_config.json`:

```python
obs_spaces, act_spaces, agent_ids = load_config(old_checkpoint)
# Returns current agent_config.py definitions + warning
```

The loader falls back to current `agent_config.py` definitions with a warning, ensuring old checkpoints can still be used.

## Files Modified

- ✅ Created `agent_config.py` — unified configuration
- ✅ Updated `train.py` — uses `agent_config.py`, saves config
- ✅ Updated `train_vectorized.py` — uses `agent_config.py`, saves config
- ✅ Updated `inference.py` — loads config from checkpoint

## Benefits

| Before | After |
|--------|-------|
| Change space = edit 3 files | Change space = edit 1 file |
| Risk of inconsistency | Single source of truth |
| Inference guesses spaces | Inference loads exact training spaces |
| Config lost after training | Config persisted with checkpoint |
