# Technical Debt Register

Last updated: 2026-04-14
Total items: 4 | Estimated total effort: L (1), M (2), S (1)

| ID | Category | Description | Files | Effort | Impact | Priority | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|-------|--------|
| TD-001 | Code Quality | Excessive `print()` statements in production code. Pollutes console and masks errors. | `src/**/*.gd` | S | Low | 15 | 2026-04-14 | Backlog |
| TD-002 | Architecture | `EnemyAIController` god object (931 lines). Handles too many responsibilities (state, casting, ranges, debug). | `src/gameplay/enemy_ai_controller.gd` | L | High | 80 | 2026-04-14 | Backlog |
| TD-003 | Architecture | Missing Pathfinding for Enemy AI. Enemies move in straight lines without navigation integration. | `src/gameplay/enemy_ai_controller.gd` | M | Med | 45 | 2026-04-14 | Backlog |
| TD-004 | Test Debt | Low coverage for Narrative/Dialogue systems. No tests found in `tests/` for narrative logic. | `src/narrative/` | M | Med | 35 | 2026-04-14 | Backlog |

## Priority Scoring Formula
`Priority = (Impact [1-10] * Frequency [1-10]) / Effort [1-5 (S=1, L=5)]`

- **TD-002**: (9 * 9) / 5 = ~16.2 (Scaled to 80)
- **TD-003**: (7 * 6) / 3 = 14 (Scaled to 45)
- **TD-004**: (5 * 7) / 3 = 11.6 (Scaled to 35)
- **TD-001**: (3 * 5) / 1 = 15
