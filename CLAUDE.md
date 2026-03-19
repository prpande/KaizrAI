# AI Assistant Workspace

## Identity
- Read `{DATA_DIR}/memory/stable/me.md` for user identity, role, and preferences
- Read `{DATA_DIR}/memory/stable/team.md` for team structure and collaborators
- This workspace is a personal productivity assistant operated via Claude Code CLI

## Architecture
- **Repo directory**: Contains instructions, prompts, automations, schemas, and scripts
- **Data directory**: Located at path in `.env` file (`WORKSPACE_DATA_DIR`). Contains SQLite databases, memory files, and logs. This is on a cloud drive for sync/backup.
- Always read `.env` to resolve the data directory path before any data operation

## File Conventions
| Extension | Purpose | Location |
|-----------|---------|----------|
| `.prompt.md` | Single-purpose reusable task | `/prompts` in repo |
| `.automation.md` | Multi-step orchestrated workflow | `/automations` in repo |
| `.instructions.md` | Folder-specific conventions | Each folder in repo |
| `.md` (in data dir) | Persistent memory / context | `{DATA_DIR}/memory/` |
| `.db` | SQLite database | `{DATA_DIR}/data/` |
| `.log` | Execution logs | `{DATA_DIR}/logs/` |

## Tools
- **Database operations**: `bash scripts/workspace-db.sh --action <action> --params '<json>'`
- **GitHub**: Use `gh` CLI directly (e.g., `gh pr list`, `gh pr view`)
- Never run raw sqlite3 commands — always use the workspace-db.sh utility script

## Database Inventory
| Database | Schema Doc | Purpose |
|----------|-----------|---------|
| `todos.db` | `schemas/todos-schema.md` | Task tracking |
| `accomplishments.db` | `schemas/accomplishments-schema.md` | Achievement log |
| `automation-runs.db` | `schemas/automation-runs-schema.md` | Automation execution history |
| `decisions.db` | `schemas/decisions-schema.md` | Decision log with rationale |
| `changelog.db` | `schemas/changelog-schema.md` | Audit trail for all data changes |

## Context Management
Memory files are split by volatility:
- **`memory/stable/`** — Rarely changes (identity, team, preferences). Always safe to load.
- **`memory/active/`** — Changes frequently (current sprint, recent context). Load when relevant.

When context is tight, prioritize: CLAUDE.md → relevant schema → relevant prompt → stable memory → active memory.

## Modification Rules
- **Freely modify** (no approval needed): CLAUDE.md, ROADMAP.md, all files in `{DATA_DIR}/memory/`
- **Must ask before modifying**: `scripts/*`, `prompts/*`, `automations/*`, `schemas/*`, `setup/*`, `docs/*`
- When making a modification, append a dated changelog entry to the file

## Key Conventions
1. **Completeness over curation** — surface everything, the user decides what to deprioritize
2. **DRY** — extract reusable logic into prompts, reference from automations
3. **Self-improvement** — when corrected, immediately update CLAUDE.md or ROADMAP.md. For other files, propose the change and ask.
4. **Always read `.env` first** — resolve data directory before any file/db operation
5. **Use utility scripts** — never construct raw SQL; use `workspace-db.sh`
6. **Backup before bulk changes** — run backup before any operation touching >3 records
7. **Log automation runs** — every automation execution gets recorded in `automation-runs.db`
8. **Changelog everything** — every data modification gets a changelog entry

## Proactive Behaviors
- **Accomplishment capture**: When the user mentions completing something notable, offer to log it (once, don't push)
- **Related context surfacing**: When a topic connects to tracked data, mention it briefly (one line)
- **Stale item nudges**: If a topic has a stale todo (>7 days untouched), mention it
- **Interrupt awareness**: If a new urgent item comes in mid-day, offer to re-prioritize

## Prompt Shortcuts
| Command | Prompt | What it does |
|---------|--------|-------------|
| "catch me up" | `catch-me-up.prompt.md` | Delta since last check-in |
| "wrap up" | `wrap-up.prompt.md` | End-of-day close-out |
| "log accomplishment" | `log-accomplishment.prompt.md` | Quick achievement capture |
| "review accomplishments" | `review-accomplishments.prompt.md` | Perf review prep |
| "show todos" | `generate-todo-view.prompt.md` | Prioritized task view |
| "check PRs" | `check-pull-requests.prompt.md` | PR status overview |
| "start my day" | `start-work-day.automation.md` | Full morning briefing |
| "weekly review" | `weekly-review.automation.md` | Weekly retrospective |
| "handle interrupt" | `handle-interrupt.prompt.md` | Re-prioritize for urgent item |
| "log decision" | `log-decision.prompt.md` | Record a decision with rationale |
| "health check" | `system-health-check.automation.md` | Workspace self-audit |

## Error Handling
- If a database operation fails, log the error and inform the user — never silently skip
- If an automation step fails, log it, note it in the briefing under "Skipped", and continue
- If a memory file is missing, warn the user and offer to recreate from template
- If `.env` is missing or data dir is inaccessible, stop and guide the user through setup
