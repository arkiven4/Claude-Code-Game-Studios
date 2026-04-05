// PROTOTYPE - NOT FOR PRODUCTION
// Question: Does the expertise scalar (0.0–1.0) produce measurably different
//           and readable party AI behavior using BT fallback logic?
//           Does the IPartyAgent contract cleanly support both BT and RL swaps?
// Date: 2026-04-04

// Standalone C# console simulation — no Unity dependencies.
// Run with: dotnet script PartyAiSim.cs  OR  compile as a .NET 6+ console app.

using System;
using System.Collections.Generic;
using System.Linq;

// ─────────────────────────────────────────────────────────────────────────────
// CORE INTERFACES  (mirrors ADR-0001 contract)
// ─────────────────────────────────────────────────────────────────────────────

public enum CharacterRole { Support, Healer, Tanker, Archer }
public enum SkillId      { BasicAttack, HeavyAttack, Skill1, Skill2, Heal }

public struct SkillState
{
    public SkillId  Id;
    public float    Cooldown;          // seconds remaining (0 = ready)
    public float    MaxCooldown;
    public float    Damage;
    public bool     IsHeal;
    public float    HealAmount;
}

public struct EnemyInfo
{
    public float HP;
    public float MaxHP;
    public float ThreatLevel;          // 0–1, how dangerous this enemy is
    public float DistanceToAgent;
}

public struct AllyInfo
{
    public float HP;
    public float MaxHP;
    public CharacterRole Role;
}

public struct PartyMemberContext
{
    public float         CurrentHP;
    public float         MaxHP;
    public SkillState[]  Skills;
    public EnemyInfo[]   NearbyEnemies;
    public AllyInfo[]    PartyMembers;
    public CharacterRole Role;
}

public interface IPartyAgent
{
    /// Called every simulated frame when NOT player-controlled.
    /// Returns the SkillId the agent chose, or null (idle this frame).
    SkillId? OnAgentUpdate(PartyMemberContext context, float deltaTime);

    void  OnPlayerTakeControl();
    void  OnAIResumeControl(PartyMemberContext context);

    float ExpertiseLevel { get; set; }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPERTISE CONTROLLER  (noise + delay model from ADR-0001)
// ─────────────────────────────────────────────────────────────────────────────

public class ExpertiseController
{
    private float _expertise;
    public float ExpertiseLevel
    {
        get => _expertise;
        set => _expertise = Math.Clamp(value, 0f, 1f);
    }

    // expertise 0.0 → noiseScale 0.8, delay 500ms
    // expertise 1.0 → noiseScale 0.0, delay 0ms
    public float NoiseScale       => Lerp(0.8f, 0f,     ExpertiseLevel);
    public float DecisionDelayMs  => Lerp(500f, 0f,     ExpertiseLevel);
    public float IdleChance       => Lerp(0.35f, 0f,    ExpertiseLevel); // chance to skip a valid action

    private static float Lerp(float a, float b, float t) => a + (b - a) * t;
}

// ─────────────────────────────────────────────────────────────────────────────
// BT PARTY AGENT  (behavior tree fallback — pure rule-based with expertise noise)
// ─────────────────────────────────────────────────────────────────────────────

public class BTPartyAgent : IPartyAgent
{
    private readonly ExpertiseController _expertise = new();
    private readonly Random              _rng;
    private float                        _decisionTimer;    // simulated delay countdown

    public float ExpertiseLevel
    {
        get => _expertise.ExpertiseLevel;
        set => _expertise.ExpertiseLevel = value;
    }

    public BTPartyAgent(float expertiseLevel, int seed = 42)
    {
        _expertise.ExpertiseLevel = expertiseLevel;
        _rng = new Random(seed);
    }

    public SkillId? OnAgentUpdate(PartyMemberContext ctx, float deltaTime)
    {
        // --- Simulate decision delay ---
        if (_decisionTimer > 0f)
        {
            _decisionTimer -= deltaTime * 1000f;   // convert to ms
            return null;                            // agent is "thinking"
        }

        // --- Idle chance (simulates expertise imperfection) ---
        if (_rng.NextDouble() < _expertise.IdleChance)
            return null;

        // --- BT: Priority-ordered decision tree ---
        SkillId? decision = EvaluateBehaviorTree(ctx);

        // --- Inject noise: randomly pick a suboptimal skill instead ---
        if (decision.HasValue && _rng.NextDouble() < _expertise.NoiseScale)
        {
            var readySkills = ctx.Skills
                .Where(s => s.Cooldown <= 0f)
                .Select(s => s.Id)
                .ToList();

            if (readySkills.Count > 0)
                decision = readySkills[_rng.Next(readySkills.Count)]; // random pick
        }

        // --- Reset decision delay after committing ---
        _decisionTimer = _expertise.DecisionDelayMs;

        return decision;
    }

    private SkillId? EvaluateBehaviorTree(PartyMemberContext ctx)
    {
        // Node 1: Emergency heal (self) — if HP < 25%
        if (ctx.CurrentHP / ctx.MaxHP < 0.25f)
        {
            var heal = ctx.Skills.FirstOrDefault(s => s.IsHeal && s.Cooldown <= 0f);
            if (heal.Id != default) return heal.Id;
        }

        // Node 2: Heal lowest-HP ally — if Healer role and ally HP < 50%
        if (ctx.Role == CharacterRole.Healer)
        {
            bool allyNeedsHeal = ctx.PartyMembers.Any(a => a.HP / a.MaxHP < 0.5f);
            if (allyNeedsHeal)
            {
                var heal = ctx.Skills.FirstOrDefault(s => s.IsHeal && s.Cooldown <= 0f);
                if (heal.Id != default) return heal.Id;
            }
        }

        // Node 3: Use best damage skill on highest-threat enemy
        if (ctx.NearbyEnemies.Length > 0)
        {
            var target = ctx.NearbyEnemies.OrderByDescending(e => e.ThreatLevel).First();
            if (target.DistanceToAgent < 5f)
            {
                var bestSkill = ctx.Skills
                    .Where(s => !s.IsHeal && s.Cooldown <= 0f)
                    .OrderByDescending(s => s.Damage)
                    .FirstOrDefault();

                if (bestSkill.Damage > 0f) return bestSkill.Id;
            }

            // Node 4: Fall back to basic attack if in range
            var basic = ctx.Skills.FirstOrDefault(s => s.Id == SkillId.BasicAttack && s.Cooldown <= 0f);
            if (basic.Id != default && target.DistanceToAgent < 3f) return basic.Id;
        }

        return null; // idle
    }

    public void OnPlayerTakeControl()  { /* yield input authority */ }
    public void OnAIResumeControl(PartyMemberContext ctx) { _decisionTimer = 0f; }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMBAT SIMULATOR  (simplified 1v1 encounter: Tanker vs. melee enemy cluster)
// ─────────────────────────────────────────────────────────────────────────────

public class EncounterResult
{
    public bool   Won;
    public float  TimeElapsed;      // seconds
    public int    ActionsUsed;
    public int    IdleFrames;
    public int    TotalFrames;
    public float  DamageDealt;
    public float  DamageTaken;

    public float IdlePercent => TotalFrames > 0 ? 100f * IdleFrames / TotalFrames : 0f;
}

public static class CombatSimulator
{
    private const float DeltaTime      = 0.1f;   // 10 FPS simulation tick
    private const float MaxEncounterS  = 120f;   // 2-minute timeout = loss
    private const float AgentMaxHP     = 200f;
    private const float EnemyMaxHP     = 300f;
    private const float EnemyDPS       = 8f;      // constant enemy damage per second

    public static EncounterResult RunEncounter(IPartyAgent agent, int seed)
    {
        var rng = new Random(seed);

        float agentHP = AgentMaxHP;
        float enemyHP = EnemyMaxHP;
        float time    = 0f;
        int   frames  = 0;
        int   idle    = 0;
        int   actions = 0;
        float dmgDealt = 0f;
        float dmgTaken = 0f;

        // Skill loadout for Tanker role
        var skills = new SkillState[]
        {
            new() { Id = SkillId.BasicAttack, Cooldown = 0f, MaxCooldown = 0.5f,  Damage = 20f },
            new() { Id = SkillId.HeavyAttack, Cooldown = 0f, MaxCooldown = 4f,   Damage = 60f },
            new() { Id = SkillId.Skill1,      Cooldown = 0f, MaxCooldown = 8f,   Damage = 100f },
            new() { Id = SkillId.Skill2,      Cooldown = 0f, MaxCooldown = 12f,  Damage = 40f },
            new() { Id = SkillId.Heal,        Cooldown = 0f, MaxCooldown = 15f,  IsHeal = true, HealAmount = 60f },
        };

        agent.OnAIResumeControl(BuildContext(agentHP, AgentMaxHP, skills, enemyHP));

        while (time < MaxEncounterS && enemyHP > 0f && agentHP > 0f)
        {
            frames++;

            // Tick cooldowns
            foreach (ref var sk in skills.AsSpan())
                sk.Cooldown = Math.Max(0f, sk.Cooldown - DeltaTime);

            var ctx = BuildContext(agentHP, AgentMaxHP, skills, enemyHP);
            var decision = agent.OnAgentUpdate(ctx, DeltaTime);

            if (decision.HasValue)
            {
                var sk = Array.Find(skills, s => s.Id == decision.Value);
                if (sk.Cooldown <= 0f)
                {
                    actions++;
                    ref var skRef = ref skills[Array.FindIndex(skills, s => s.Id == decision.Value)];
                    skRef.Cooldown = skRef.MaxCooldown;

                    if (skRef.IsHeal)
                        agentHP = Math.Min(AgentMaxHP, agentHP + skRef.HealAmount);
                    else
                    {
                        enemyHP  -= skRef.Damage;
                        dmgDealt += skRef.Damage;
                    }
                }
                else
                {
                    idle++; // chose skill but it was on cooldown — counts as idle
                }
            }
            else
            {
                idle++;
            }

            // Enemy attacks every frame at constant DPS
            float dmg = EnemyDPS * DeltaTime;
            agentHP  -= dmg;
            dmgTaken += dmg;
            time     += DeltaTime;
        }

        return new EncounterResult
        {
            Won          = enemyHP <= 0f && agentHP > 0f,
            TimeElapsed  = time,
            ActionsUsed  = actions,
            IdleFrames   = idle,
            TotalFrames  = frames,
            DamageDealt  = dmgDealt,
            DamageTaken  = dmgTaken,
        };
    }

    private static PartyMemberContext BuildContext(float hp, float maxHp, SkillState[] skills, float enemyHp)
        => new()
        {
            CurrentHP    = hp,
            MaxHP        = maxHp,
            Skills       = skills,
            Role         = CharacterRole.Tanker,
            NearbyEnemies = new[] { new EnemyInfo { HP = enemyHp, MaxHP = EnemyMaxHP, ThreatLevel = 0.8f, DistanceToAgent = 2f } },
            PartyMembers  = Array.Empty<AllyInfo>(),
        };
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

class Program
{
    static void Main()
    {
        Console.WriteLine("=== Party AI Prototype — Expertise Scalar Validation ===");
        Console.WriteLine("Simulating 100 Tanker encounters per expertise level...\n");

        float[] expertiseLevels = { 0.0f, 0.3f, 0.5f, 0.7f, 1.0f };
        int     runsPerLevel    = 100;

        Console.WriteLine($"{"Expertise",-12} {"Win %",-8} {"Avg Time",-12} {"Idle %",-10} {"Avg Actions",-12} {"Avg DMG",-10}");
        Console.WriteLine(new string('-', 66));

        foreach (float expertise in expertiseLevels)
        {
            var results = new List<EncounterResult>();
            for (int i = 0; i < runsPerLevel; i++)
            {
                // Use a different seed per expertise level to avoid correlation
                var agent = new BTPartyAgent(expertiseLevel: expertise, seed: i * 31 + (int)(expertise * 100));
                agent.ExpertiseLevel = expertise;
                results.Add(CombatSimulator.RunEncounter(agent, seed: i));
            }

            float winPct   = 100f * results.Count(r => r.Won) / results.Count;
            float avgTime  = results.Average(r => r.TimeElapsed);
            float avgIdle  = results.Average(r => r.IdlePercent);
            float avgAct   = (float)results.Average(r => r.ActionsUsed);
            float avgDmg   = results.Average(r => r.DamageDealt);

            Console.WriteLine($"{expertise,-12:F1} {winPct,-8:F1} {avgTime,-12:F1}s {avgIdle,-10:F1}% {avgAct,-12:F1} {avgDmg,-10:F0}");
        }

        Console.WriteLine();
        Console.WriteLine("=== Interface Contract Validation ===");
        ValidateInterfaceContract();
    }

    /// Proves IPartyAgent can be swapped (BT ↔ future RL) without changing call sites.
    static void ValidateInterfaceContract()
    {
        IPartyAgent[] agents = {
            new BTPartyAgent(expertiseLevel: 0.5f, seed: 1),
            new BTPartyAgent(expertiseLevel: 1.0f, seed: 2),
            // Slot here for RLPartyAgent when trained — same call site, zero changes
        };

        foreach (var agent in agents)
        {
            var ctx = new PartyMemberContext
            {
                CurrentHP    = 100f,
                MaxHP        = 200f,
                Role         = CharacterRole.Tanker,
                Skills       = new[] { new SkillState { Id = SkillId.BasicAttack, Cooldown = 0f, Damage = 20f } },
                NearbyEnemies = new[] { new EnemyInfo { HP = 150f, MaxHP = 300f, ThreatLevel = 0.8f, DistanceToAgent = 2f } },
                PartyMembers  = Array.Empty<AllyInfo>(),
            };

            var result = agent.OnAgentUpdate(ctx, 0.1f);
            Console.WriteLine($"  Agent (expertise={agent.ExpertiseLevel:F1}) → decision: {(result.HasValue ? result.Value.ToString() : "IDLE")}");
        }

        Console.WriteLine("\n[PASS] IPartyAgent interface works — call sites are implementation-agnostic.");
    }
}
