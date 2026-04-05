# Prototype: Party AI — Expertise Scalar Validation

**Status**: Concluded — PROCEED verdict
**Date**: 2026-04-04
**ADR reference**: [ADR-0001](../../docs/architecture/adr-0001-party-ai-rl-vs-behavior-tree.md)
**Full report**: [REPORT.md](REPORT.md)

---

## Hypothesis

The expertise scalar (0.0–1.0) produces meaningfully different, readable party AI behavior
using the BT fallback implementation. Specifically:

1. Agents at expertise 0.0 fail at least 30% of encounters (ADR-0001 gate criterion)
2. Agents at expertise 1.0 defeat encounters clearly faster than expertise 0.0
3. The `IPartyAgent` interface cleanly supports implementation swapping (BT ↔ RL)
   without changing any call site

---

## How to Run

**Python simulation** (standalone — no Unity required):

```bash
cd prototypes/party-ai
python party_ai_sim.py
```

Requires Python 3.x. No external dependencies. Simulates 100 encounters per expertise
level and prints a results table.

**C# simulation** (logic mirror of the Python version):

```bash
cd prototypes/party-ai
dotnet run
```

Requires .NET 9 SDK.

---

## Findings (Summary)

| Expertise | Win % | Avg Time-to-Kill | Idle % |
|-----------|-------|-----------------|--------|
| 0.0       | 100%  | 5.2s            | 83.1%  |
| 0.5       | 100%  | 4.7s            | 81.5%  |
| 1.0       | 100%  | 2.8s            | 71.4%  |

**Interface contract**: PASS — BT ↔ RL swap requires zero call-site changes.

**Verdict: PROCEED** — Architecture is sound. Time-to-kill shows 1.86× differentiation
across the expertise range. The `IPartyAgent` interface works exactly as designed.

**Critical gap found**: Encounter is undertuned (100% win rate at all expertise levels).
The ADR gate criterion ("fails 30% at expertise 0.3") cannot be verified until the
encounter is hardened (target enemy DPS ≈ 35–40; current DPS = 8). This is a tuning
problem, not an architectural one.

See [REPORT.md](REPORT.md) for full metrics, root cause analysis, and production
architecture requirements.

---

## Current State

Concluded. Production implementations (`BTPartyAgent.cs`, `RLPartyAgent.cs`,
`IPartyAgent.cs`) live in `Assets/Scripts/AI/` — written to production standards,
not migrated from this prototype.

**Remaining before Month 1 RL gate:**
1. Build hardened encounter scene in Unity with corrected DPS tuning
2. Verify ML-Agents package compatibility with Unity 6.3 LTS before writing training code
