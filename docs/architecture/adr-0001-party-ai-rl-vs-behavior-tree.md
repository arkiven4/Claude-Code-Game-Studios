# ADR-0001: Party AI — Reinforcement Learning vs. Behavior Tree

## Status
Accepted

## Date
2026-04-03

---

## Context

### Problem Statement

Non-active party members must behave competently during real-time hack & slash combat
without player input. The AI governing these companions is one of the most player-visible
systems in the game — janky AI companions are listed as a top dealbreaker for the target
audience. The system must also support a tunable "expertise" level so companion quality
can be adjusted per-character and per-chapter to reflect narrative progression (a new
recruit fights worse than a veteran).

Two viable approaches exist: **Reinforcement Learning** (train agents to optimal play,
then degrade deliberately) or **Behavior Trees** (hand-author decision logic, then add
simulated noise). This ADR documents the decision between them.

### Constraints

- **Timeline**: 3 months total; Party AI must be Alpha-ready by Month 2
- **Resources**: Solo/small team — limited engineering hours for training infrastructure
- **Engine**: Unity 6.3 LTS with Unity ML-Agents package
- **Prototype gate**: Month 1 prototype must validate feasibility before Alpha commitment
- **Fallback required**: If RL proves infeasible, a non-RL path must exist without
  redesigning dependent systems (Character State Manager, Combat System)

### Requirements

- Party members must behave competently at `expertise = 1.0` (veteran level)
- Party members must behave noticeably worse at `expertise = 0.0` (new recruit level)
- The expertise parameter must be settable at runtime (not baked into separate models)
- Party AI must not require player attention to stay alive in normal encounters
- AI handoff must be seamless when the player switches INTO a character (takes control)
  and OUT of a character (AI resumes)
- System must work for all party roles: Support, Healer, Tanker, Archer
- Training (if RL) must be reproducible and not require manual reward shaping per boss

---

## Decision

**Use Reinforcement Learning (Unity ML-Agents) as the primary approach, with a
mandatory Month 1 prototype gate. If the prototype fails the gate, fall back to
Behavior Trees with noise simulation.**

Both approaches are architected behind a shared `IPartyAgent` interface so the
game never directly depends on which implementation is active. This allows swapping
RL for BT without changing any dependent system (Combat, Character Switching, HUD).

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Combat System                         │
│   (doesn't know or care which AI implementation runs)   │
└───────────────────────┬─────────────────────────────────┘
                        │ IPartyAgent
            ┌───────────┴───────────┐
            │                       │
   ┌────────▼────────┐   ┌─────────▼────────┐
   │  RLPartyAgent   │   │  BTPartyAgent    │
   │ (ML-Agents)     │   │ (Behavior Tree)  │
   │                 │   │  [FALLBACK]      │
   └────────┬────────┘   └─────────┬────────┘
            │                       │
            └──────────┬────────────┘
                       │
              ┌────────▼────────┐
              │ ExpertiseScalar │
              │  float [0..1]   │
              │  per-character  │
              └─────────────────┘

Training (RL only — separate from runtime):
┌─────────────────────────────────────────┐
│         TrainingEnvironment             │
│  Isolated Unity scene per encounter     │
│  ML-Agents Academy + Agent components   │
│  Trains to: maximize damage output,     │
│  survival rate, skill uptime            │
│  Output: .onnx model per role           │
└─────────────────────────────────────────┘

Runtime (RL):
  Model (.onnx) loaded via ML-Agents Inference
  ExpertiseScalar → injects action noise + decision delay
  expertise 0.0 = max noise + 500ms delay
  expertise 1.0 = no noise, no delay (pure model output)
```

### Key Interfaces

```csharp
// All party AI implementations must implement this interface.
// Combat System, Character Switching, and HUD depend on this — NOT on RL or BT directly.
public interface IPartyAgent
{
    // Called every frame when this character is NOT player-controlled
    void OnAgentUpdate(PartyMemberContext context);

    // Called when player switches INTO this character (AI yields control)
    void OnPlayerTakeControl();

    // Called when player switches OUT of this character (AI resumes)
    void OnAIResumeControl(PartyMemberContext context);

    // 0.0 = new recruit behavior, 1.0 = veteran behavior
    float ExpertiseLevel { get; set; }
}

// Passed to OnAgentUpdate each frame — the agent's view of the world
public struct PartyMemberContext
{
    public Vector3 Position;
    public float CurrentHP;
    public float MaxHP;
    public SkillState[] Skills;           // cooldowns, availability
    public EnemyInfo[] NearbyEnemies;     // position, HP, threat level
    public AllyInfo[] PartyMembers;       // position, HP, role
    public CharacterRole Role;            // Support, Healer, Tanker, Archer
}

// The expertise controller — used by designers to tune NPC quality
public class ExpertiseController : MonoBehaviour
{
    [Range(0f, 1f)]
    [SerializeField] private float _expertiseLevel = 0.5f;

    // Noise injected into RL model outputs at runtime
    // expertise 0.0 → noiseScale 0.8, decisionDelay 500ms
    // expertise 1.0 → noiseScale 0.0, decisionDelay 0ms
    public float NoiseScale => Mathf.Lerp(0.8f, 0f, _expertiseLevel);
    public float DecisionDelayMs => Mathf.Lerp(500f, 0f, _expertiseLevel);
}
```

### Expertise Scalar Behavior

| Expertise | Noise Scale | Decision Delay | Observed Behavior |
|-----------|-------------|----------------|-------------------|
| 0.0–0.3 | 0.5–0.8 | 300–500ms | Mistimed skills, poor targeting, idle gaps |
| 0.4–0.6 | 0.2–0.5 | 100–300ms | Competent but not optimal; reads as "learning" |
| 0.7–0.9 | 0.05–0.2 | 0–100ms | Reliable; player can trust them |
| 1.0 | 0.0 | 0ms | Fully optimal; reserved for story showcases |

### RL Training Approach (if prototype passes gate)

- **One training scene per encounter archetype** (not per boss — group similar encounters)
- **Reward signal**: damage dealt + survival time + skill uptime − friendly fire
- **One .onnx model per role** (Support, Healer, Tanker, Archer) — not per character
- **Expertise**: injected at inference time via noise + delay on the model output;
  the model itself always runs at full quality
- **Training tool**: Unity ML-Agents 3.x (verify version in Package Manager for Unity 6.3)

---

## Alternatives Considered

### Alternative 1: Pure Behavior Tree (no RL)

- **Description**: Hand-author a decision tree for each party role. Expertise is
  simulated by randomly skipping decisions, adding aim error, and reducing reaction speed.
- **Pros**:
  - Predictable, debuggable, no training infrastructure needed
  - Works on Day 1, no prototype gate required
  - Easier to tune specific behaviors ("healer always prioritizes lowest HP ally")
  - No GPU/training time cost
- **Cons**:
  - Hand-authored trees feel scripted and mechanical
  - Adding new encounter types requires manual tree updates
  - "Expertise" simulation is obviously fake at close inspection
  - Does not scale gracefully to new enemy patterns or mechanics
- **Rejection Reason**: The RL approach offers a qualitatively better companion feel
  AND solves the expertise problem more elegantly. Selected as primary; BT retained
  as fallback if RL prototype fails the Month 1 gate.

### Alternative 2: Hybrid — BT for structure, RL for leaf decisions

- **Description**: Behavior Tree handles high-level role behavior (engage, heal,
  retreat) while RL policies govern low-level execution (which skill to use, where
  to position).
- **Pros**: More controllable than pure RL; better than pure BT feel
- **Cons**:
  - More complex architecture than either pure approach
  - Requires both BT authoring AND RL training expertise
  - Hardest to debug — failures could come from either layer
  - Doubles the implementation scope
- **Rejection Reason**: Complexity is too high for a 3-month solo project. If pure
  RL fails the prototype gate, pure BT is the fallback — not this hybrid.

### Alternative 3: Scripted state machine per character

- **Description**: Each character has a hand-authored state machine (idle → engage →
  use skill → disengage) with explicit transitions.
- **Pros**: Simple, fast to implement, completely predictable
- **Cons**:
  - No generalization — every encounter type needs explicit states
  - Expertise simulation is crude (skip every Nth action)
  - Feels robotic; breaks immersion quickly
- **Rejection Reason**: This is the weakest option for player perception. Dismissed early.

---

## Consequences

### Positive

- Party AI can genuinely improve with character progression (expertise scalar maps
  to narrative growth, not just stat numbers)
- RL models generalize to new encounter patterns without manual re-authoring
- `IPartyAgent` interface means the game never hard-depends on RL — swap is transparent
  to all dependent systems
- Expertise scalar is a designer-friendly float; no code changes to tune NPC quality

### Negative

- **Training infrastructure cost**: Separate training scenes must be built and
  maintained; this is non-game-code work
- **Iteration time**: RL training loops take hours; bugs in reward signals waste days
- **Black box behavior**: RL agents can produce unexpected behaviors that are hard
  to diagnose ("why did the healer run into the boss?")
- **ML-Agents API risk**: ML-Agents package version may have breaking changes in
  Unity 6.3 — must be verified before writing training code

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Training environment too complex to build in Month 1 | Medium | High | Fallback to BT immediately — don't over-invest in fixing a failing prototype |
| RL training takes too long per iteration | Medium | Medium | Time-box training runs; use smaller encounter scopes for early training |
| ML-Agents incompatible with Unity 6.3 | Low | High | Verify package version on Day 1 before writing any ML code |
| RL agent produces unreadable behavior at low expertise | Medium | Medium | Tune noise/delay parameters; add a minimum-competence floor at expertise > 0.0 |
| Black-box agent fails specific narrative-critical moments | Low | High | Override agent with scripted behavior for story beats; use `OnPlayerTakeControl` hook |

---

## Performance Implications

- **CPU**: RL inference via .onnx is fast (~0.1–0.5ms per agent per frame); BT
  fallback is similar. 4 party members = ~2ms worst case. Acceptable.
- **Memory**: .onnx models are small (~1–5MB per role). 4 models = ~20MB. Negligible.
- **GPU**: ML-Agents inference runs on CPU by default in Unity; no GPU budget impact.
- **Training** (offline only): Training uses GPU compute; this happens outside the
  game build and does not affect runtime performance.
- **Load Time**: Models loaded once at scene start; no per-frame load cost.

---

## Migration Plan

This is a new system with no existing code. No migration required.

**Implementation order**:
1. Define `IPartyAgent` interface and `PartyMemberContext` struct (Day 1)
2. Build `BTPartyAgent` stub (simple rule-based) — this is the working fallback
3. Build training scene for one encounter type (Tanker vs. melee enemy cluster)
4. Train first .onnx model; evaluate quality vs. BT stub
5. **Month 1 Gate**: If RL model clearly outperforms BT and training took < 1 week —
   proceed with RL. If not — ship with BT, close this prototype, move on.
6. If RL proceeds: build `RLPartyAgent`, integrate `ExpertiseController`, train
   remaining role models

---

## Validation Criteria

**Prototype gate (Month 1):**
- [ ] At least one .onnx model trained for one party role (Tanker recommended as first)
- [ ] Agent defeats target encounter in < 90 seconds at expertise 1.0
- [ ] Agent visibly performs worse at expertise 0.3 (fails at least 30% of encounters)
- [ ] Training a new model for a new encounter type takes < 1 week
- [ ] `IPartyAgent` interface works with both RL and BT implementations

**Alpha gate (Month 2):**
- [ ] All 4 role models trained and integrated
- [ ] Expertise scalar produces readable quality differences across all roles
- [ ] AI handoff (player switch in/out) is seamless — no animation glitches or
  state corruption
- [ ] Player testers describe companions as "competent" at expertise 0.7+

---

## Related Decisions

- **Systems Index**: `design/gdd/systems-index.md` — Party AI System (#23),
  Character State Manager (#21), Character Switching System (#22)
- **Game Concept**: `design/gdd/game-concept.md` — Party AI Architecture section
- **Next ADR**: ADR-0002 should cover Character Switching state synchronization
  (how HP, buffs, and cooldowns transfer on swap — the other high-risk Party system)
