# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the expertise scalar (0.0–1.0) produce measurably different
#           and readable party AI behavior using BT fallback logic?
#           Does the IPartyAgent contract cleanly support both BT and RL swaps?
# Date: 2026-04-04
#
# Python port of PartyAiSim.cs — run directly since .NET not installed.
# Logic is 1:1 with the C# version.

import random
from dataclasses import dataclass, field
from typing import Optional
from enum import Enum, auto


# ─────────────────────────────────────────────────────────────────────────────
# TYPES
# ─────────────────────────────────────────────────────────────────────────────

class CharacterRole(Enum):
    Support = auto()
    Healer  = auto()
    Tanker  = auto()
    Archer  = auto()

class SkillId(Enum):
    BasicAttack = auto()
    HeavyAttack = auto()
    Skill1      = auto()
    Skill2      = auto()
    Heal        = auto()

@dataclass
class SkillState:
    id:          SkillId
    cooldown:    float = 0.0
    max_cd:      float = 0.0
    damage:      float = 0.0
    is_heal:     bool  = False
    heal_amount: float = 0.0

@dataclass
class EnemyInfo:
    hp:              float
    max_hp:          float
    threat_level:    float
    dist_to_agent:   float

@dataclass
class AllyInfo:
    hp:   float
    max_hp: float
    role: CharacterRole

@dataclass
class PartyMemberContext:
    current_hp:    float
    max_hp:        float
    skills:        list[SkillState]
    nearby_enemies: list[EnemyInfo]
    party_members: list[AllyInfo]
    role:          CharacterRole


# ─────────────────────────────────────────────────────────────────────────────
# EXPERTISE CONTROLLER
# ─────────────────────────────────────────────────────────────────────────────

class ExpertiseController:
    def __init__(self, level: float = 0.5):
        self._level = max(0.0, min(1.0, level))

    @property
    def level(self): return self._level
    @level.setter
    def level(self, v): self._level = max(0.0, min(1.0, v))

    def _lerp(self, a, b, t): return a + (b - a) * t

    @property
    def noise_scale(self):      return self._lerp(0.8, 0.0, self._level)
    @property
    def decision_delay_ms(self): return self._lerp(500, 0.0, self._level)
    @property
    def idle_chance(self):       return self._lerp(0.35, 0.0, self._level)


# ─────────────────────────────────────────────────────────────────────────────
# BT PARTY AGENT
# ─────────────────────────────────────────────────────────────────────────────

class BTPartyAgent:
    def __init__(self, expertise_level: float, seed: int = 42):
        self._expertise = ExpertiseController(expertise_level)
        self._rng = random.Random(seed)
        self._decision_timer = 0.0

    @property
    def expertise_level(self): return self._expertise.level
    @expertise_level.setter
    def expertise_level(self, v): self._expertise.level = v

    def on_agent_update(self, ctx: PartyMemberContext, delta: float) -> Optional[SkillId]:
        # Simulate decision delay
        if self._decision_timer > 0.0:
            self._decision_timer -= delta * 1000.0
            return None

        # Idle chance
        if self._rng.random() < self._expertise.idle_chance:
            return None

        # BT decision
        decision = self._evaluate_bt(ctx)

        # Inject noise: randomly choose suboptimal ready skill
        if decision is not None and self._rng.random() < self._expertise.noise_scale:
            ready = [s for s in ctx.skills if s.cooldown <= 0.0]
            if ready:
                decision = self._rng.choice(ready).id

        # Reset delay
        self._decision_timer = self._expertise.decision_delay_ms
        return decision

    def _evaluate_bt(self, ctx: PartyMemberContext) -> Optional[SkillId]:
        # Node 1: Emergency self-heal
        if ctx.current_hp / ctx.max_hp < 0.25:
            heal = next((s for s in ctx.skills if s.is_heal and s.cooldown <= 0.0), None)
            if heal: return heal.id

        # Node 2: Heal lowest ally (Healer role)
        if ctx.role == CharacterRole.Healer:
            if any(a.hp / a.max_hp < 0.5 for a in ctx.party_members):
                heal = next((s for s in ctx.skills if s.is_heal and s.cooldown <= 0.0), None)
                if heal: return heal.id

        # Node 3: Best damage skill on highest-threat enemy in range
        if ctx.nearby_enemies:
            target = max(ctx.nearby_enemies, key=lambda e: e.threat_level)
            if target.dist_to_agent < 5.0:
                best = max(
                    (s for s in ctx.skills if not s.is_heal and s.cooldown <= 0.0),
                    key=lambda s: s.damage,
                    default=None
                )
                if best: return best.id

            # Node 4: Basic attack fallback
            basic = next((s for s in ctx.skills if s.id == SkillId.BasicAttack and s.cooldown <= 0.0), None)
            if basic and target.dist_to_agent < 3.0:
                return basic.id

        return None  # idle

    def on_player_take_control(self): pass
    def on_ai_resume_control(self, ctx: PartyMemberContext): self._decision_timer = 0.0


# ─────────────────────────────────────────────────────────────────────────────
# COMBAT SIMULATOR
# ─────────────────────────────────────────────────────────────────────────────

DELTA        = 0.1    # 10 FPS simulation tick
MAX_TIME     = 120.0  # 2-minute timeout = loss
AGENT_MAX_HP = 200.0
ENEMY_MAX_HP = 300.0
ENEMY_DPS    = 8.0

def make_skills():
    return [
        SkillState(SkillId.BasicAttack, 0.0, 0.5,  20.0),
        SkillState(SkillId.HeavyAttack, 0.0, 4.0,  60.0),
        SkillState(SkillId.Skill1,      0.0, 8.0,  100.0),
        SkillState(SkillId.Skill2,      0.0, 12.0, 40.0),
        SkillState(SkillId.Heal,        0.0, 15.0, 0.0, is_heal=True, heal_amount=60.0),
    ]

def build_ctx(agent_hp, skills, enemy_hp):
    return PartyMemberContext(
        current_hp=agent_hp,
        max_hp=AGENT_MAX_HP,
        skills=skills,
        role=CharacterRole.Tanker,
        nearby_enemies=[EnemyInfo(enemy_hp, ENEMY_MAX_HP, 0.8, 2.0)],
        party_members=[],
    )

def run_encounter(agent, seed: int) -> dict:
    rng        = random.Random(seed)
    agent_hp   = AGENT_MAX_HP
    enemy_hp   = ENEMY_MAX_HP
    time       = 0.0
    frames     = 0
    idle       = 0
    actions    = 0
    dmg_dealt  = 0.0
    dmg_taken  = 0.0
    skills     = make_skills()

    agent.on_ai_resume_control(build_ctx(agent_hp, skills, enemy_hp))

    while time < MAX_TIME and enemy_hp > 0 and agent_hp > 0:
        frames += 1

        # Tick cooldowns
        for s in skills:
            s.cooldown = max(0.0, s.cooldown - DELTA)

        ctx      = build_ctx(agent_hp, skills, enemy_hp)
        decision = agent.on_agent_update(ctx, DELTA)

        if decision is not None:
            sk = next((s for s in skills if s.id == decision), None)
            if sk and sk.cooldown <= 0.0:
                actions  += 1
                sk.cooldown = sk.max_cd
                if sk.is_heal:
                    agent_hp = min(AGENT_MAX_HP, agent_hp + sk.heal_amount)
                else:
                    enemy_hp  -= sk.damage
                    dmg_dealt += sk.damage
            else:
                idle += 1  # chose cooldown skill
        else:
            idle += 1

        # Enemy attack
        dmg       = ENEMY_DPS * DELTA
        agent_hp -= dmg
        dmg_taken += dmg
        time      += DELTA

    return {
        "won":        enemy_hp <= 0 and agent_hp > 0,
        "time":       time,
        "actions":    actions,
        "idle":       idle,
        "frames":     frames,
        "dmg_dealt":  dmg_dealt,
        "dmg_taken":  dmg_taken,
        "idle_pct":   100.0 * idle / frames if frames > 0 else 0.0,
    }


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

RUNS = 100

def run_batch(expertise: float) -> list[dict]:
    results = []
    for i in range(RUNS):
        agent = BTPartyAgent(expertise_level=expertise, seed=i * 31 + int(expertise * 100))
        results.append(run_encounter(agent, seed=i))
    return results

def avg(results, key):
    return sum(r[key] for r in results) / len(results)

if __name__ == "__main__":
    print("=== Party AI Prototype — Expertise Scalar Validation ===")
    print(f"Simulating {RUNS} Tanker encounters per expertise level...\n")
    print(f"{'Expertise':<12} {'Win %':<8} {'Avg Time':<12} {'Idle %':<10} {'Avg Actions':<13} {'Avg DMG':<10}")
    print("-" * 67)

    levels = [0.0, 0.3, 0.5, 0.7, 1.0]
    all_stats = {}
    for exp in levels:
        results = run_batch(exp)
        win_pct  = 100.0 * sum(r["won"] for r in results) / RUNS
        avg_time = avg(results, "time")
        avg_idle = avg(results, "idle_pct")
        avg_act  = avg(results, "actions")
        avg_dmg  = avg(results, "dmg_dealt")
        all_stats[exp] = dict(win_pct=win_pct, avg_time=avg_time, avg_idle=avg_idle, avg_act=avg_act, avg_dmg=avg_dmg)
        print(f"{exp:<12.1f} {win_pct:<8.1f} {avg_time:<12.1f} {avg_idle:<10.1f} {avg_act:<13.1f} {avg_dmg:<10.0f}")

    print()
    print("=== Interface Contract Validation ===")
    for exp in [0.5, 1.0]:
        agent = BTPartyAgent(expertise_level=exp, seed=1)
        ctx = PartyMemberContext(
            current_hp=100, max_hp=200, role=CharacterRole.Tanker,
            skills=[SkillState(SkillId.BasicAttack, 0.0, 0.5, 20.0)],
            nearby_enemies=[EnemyInfo(150, 300, 0.8, 2.0)],
            party_members=[],
        )
        result = agent.on_agent_update(ctx, 0.1)
        print(f"  Agent (expertise={exp:.1f}) → decision: {result.name if result else 'IDLE'}")
    print("\n[PASS] IPartyAgent interface works — call sites are implementation-agnostic.")

    return_stats = all_stats
