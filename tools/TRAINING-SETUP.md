# Training Scene Setup Guide
**For: Unity 6.3 LTS + ML-Agents**

This guide walks you through setting up `TrainingScene.unity` in the Unity Editor.
You only need to do this once.

---

## Part 1 — Open the Scene

1. Open Unity Editor
2. In the **Project** window (bottom panel), navigate to:
   `Assets → Scenes → TrainingScene`
3. Double-click `TrainingScene` to open it

---

## Part 2 — Create the Training Arena

You need a flat floor for the agent and enemy to stand on.

1. In the **Hierarchy** window (left panel), right-click → **3D Object → Plane**
2. Name it `Floor`
3. In the **Inspector** (right panel), set Transform:
   - Position: `0, 0, 0`
   - Scale: `3, 1, 3`

---

## Part 3 — Create the Party Member (Tanker)

This is the AI agent that learns.

### 3a. Create the GameObject
1. Right-click in Hierarchy → **Create Empty**
2. Name it `PartyMember_Tanker`
3. Set Position: `-2, 0, 0`

### 3b. Add the required components
Click on `PartyMember_Tanker` in the Hierarchy, then in the Inspector click **Add Component** for each of these:

| Component | Notes |
|-----------|-------|
| `Party Member State` | Manages HP, MP, cooldowns |
| `Skill Execution System` | Fires skills |
| `RL Party Agent` | The ML-Agents AI brain |
| `Decision Requester` | Controls how often the AI decides |

### 3c. Configure components

**Party Member State:**
- Character Data → drag `Assets/ScriptableObjects/CharacterDataSO.asset`
- Character Level → `1`

**Decision Requester:**
- Decision Period → `5`  *(AI decides every 5 frames)*
- Take Actions Between Decisions → **checked**

**Behavior Parameters** (auto-created when you add RL Party Agent):
- Behavior Name → `PartyAI`  *(MUST match exactly — capital P, capital A, no space)*
- Behavior Type → `Default`  *(switches to Inference when you have a trained model)*
- Vector Observation → Space Size: `39`
- Actions → Discrete Branches: `1`, Branch 0 Size: `5`

**RL Party Agent:**
- State → drag `PartyMember_Tanker` itself (the same GameObject)
- Skill Execution → drag the `Skill Execution System` component from the same object

---

## Part 4 — Create the Enemy

### 4a. Create the GameObject
1. Right-click in Hierarchy → **Create Empty**
2. Name it `Enemy_Grunt`
3. Set Position: `2, 0, 0`

### 4b. Add component
- Add Component → `Enemy AI Controller`

### 4c. Configure
**Enemy AI Controller:**
- Enemy Data → drag `Assets/ScriptableObjects/EnemyDataSO.asset`
- Player Layer → select the `Default` layer (or whichever layer the party member is on)

---

## Part 5 — Create the Training Manager

This is the "director" that resets and restarts each episode automatically.

### 5a. Create the GameObject
1. Right-click in Hierarchy → **Create Empty**
2. Name it `TrainingManager`
3. Position doesn't matter (it's invisible)

### 5b. Add components

| Component | Notes |
|-----------|-------|
| `Combat Encounter Manager` | Orchestrates the fight |
| `Training Orchestrator` | Auto-restarts episodes (training only) |

### 5c. Configure Combat Encounter Manager
- **Enemies** → set Size to `1`, then drag `Enemy_Grunt` into Element 0
- **Party Members** → set Size to `1`, then drag `PartyMember_Tanker` into Element 0
- Max Encounter Duration → `120`

### 5d. Configure Training Orchestrator
- Encounter → drag `TrainingManager` itself (it has `Combat Encounter Manager` on it)
- Episode Restart Delay → `0.2`

---

## Part 6 — Wire up RL Party Agent references

Click on `PartyMember_Tanker` again:

**RL Party Agent — Enemies array:**
- Set Size to `1`
- Drag `Enemy_Grunt` into Element 0

**RL Party Agent — Allies array:**
- Leave Size at `0` (solo training — no party members yet)

---

## Part 7 — Save the scene

Press `Ctrl+S` to save.

---

## Part 8 — Run training

Open a terminal in the project root, then run:

```bash
./tools/train.sh
```

Follow the on-screen instructions. The script will tell you exactly when to press **Play** in Unity.

---

## Verification — Is it working?

After pressing Play, you should see in the terminal:
```
[INFO] Connected to Unity environment with package version 2.0.2
[INFO] 'PartyAI' started. Training.
```

In Unity, the `PartyMember_Tanker` should start moving (or visually doing something).
The Console window should show no red errors.

---

## Common Errors

| Error | Fix |
|-------|-----|
| `No Behavior with name PartyAI` | Behavior Parameters → Behavior Name must be exactly `PartyAI` |
| `Connected but then disconnected` | Check that Behavior Type is `Default`, not `Inference Only` |
| `NullReferenceException on PartyMemberState` | Assign CharacterDataSO in Inspector |
| `NullReferenceException on EnemyAIController` | Assign EnemyDataSO in Inspector |
| Port 5004 in use | Close any other Unity instances or previous mlagents-learn processes |

---

## After Training

When training finishes (or you stop it), the model is saved to:
```
training-results/[run-id]/PartyAI.onnx
```

To use it:
1. Copy the `.onnx` file to `Assets/Models/PartyAI.onnx`
2. In Unity: click `PartyMember_Tanker` → RL Party Agent → **Model** field → assign the `.onnx`
3. Set **Behavior Type** → `Inference Only`
4. Press Play — the AI now runs the trained model (no Python needed)
