# AI Assistant Workspace

Turn Claude Code into your personal work assistant with persistent memory, task tracking, accomplishment logging, and daily workflow automations.

## Quick Start

1. **Prerequisites**: `bash`, `sqlite3`, `jq`, `gh` (GitHub CLI), `git`
2. **Clone**: `git clone <repo-url> && cd ai-assistant-workspace`
3. **Setup**: `bash setup/init.sh --data-dir "/path/to/your/cloud-drive/ai-assistant-data"`
4. **Personalize**: Edit `memory/stable/me.md` and `memory/stable/team.md` in your data directory (the path you passed to `--data-dir`; also stored in `.env`)
5. **Go**: Open Claude Code in this directory and say **"start my day"**

## Available Commands

| Say this | What happens |
|----------|-------------|
| "start my day" | Morning briefing with todos, PRs, incidents, priorities |
| "catch me up" | Quick delta since last check-in |
| "show todos" | Prioritized task view |
| "wrap up" | End-of-day close-out |
| "log accomplishment" | Record an achievement |
| "review accomplishments" | Performance review prep |
| "check PRs" | GitHub PR status |
| "handle interrupt" | Re-prioritize for urgent item |
| "log decision" | Record a decision with rationale |
| "weekly review" | Weekly retrospective |
| "health check" | Workspace self-audit |

## How It Works

- **CLAUDE.md** is the brain — Claude reads it automatically
- **Prompts** (`prompts/`) are single-purpose tasks
- **Automations** (`automations/`) orchestrate multi-step workflows
- **Scripts** (`scripts/`) manage SQLite databases safely
- **Data** lives in your cloud drive, not in this repo

## Docs

- [Setup Guide](docs/SETUP-GUIDE.md)
- [Customization](docs/CUSTOMIZATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Growth Path](docs/GROWTH-PATH.md)

## License

MIT