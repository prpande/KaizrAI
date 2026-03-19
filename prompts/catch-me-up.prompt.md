# Catch Me Up

## Goal
Provide a delta-based status summary since the last check-in, readable in 30 seconds.

## Context
- Database: `todos.db` via `bash scripts/workspace-db.sh --action list-todos`
- Database: `automation-runs.db` via `bash scripts/workspace-db.sh --action list-runs`
- Memory: `{DATA_DIR}/memory/active/weekly-context.md`
- GitHub: via `gh` CLI (if `gh` is authenticated)

## Instructions
1. Read `.env` to get `WORKSPACE_DATA_DIR`
2. Run `bash scripts/workspace-db.sh --action stats` for a quick overview
3. Check for todos that changed status since last automation run:
   - New todos added
   - Todos completed or cancelled
   - Todos that became overdue
4. Check for stale items (last_touched > 7 days)
5. If `gh` CLI is authenticated, check for:
   - Open PRs authored by the user: `gh pr list --author @me --state open --json number,title,createdAt,reviewDecision,statusCheckRollup`
   - PRs awaiting the user's review: `gh pr list --search "review-requested:@me" --state open --json number,title,author`
   - Flag: stale >3 days, failing CI, missing reviews
6. Check `automation-runs.db` for last run — note how long ago it was
7. Read `memory/active/weekly-context.md` for current sprint context

## Output
Structure the response as:

**🔴 Needs Attention Now** (critical/overdue/blocked items — skip if none)
**🟡 Updates Since Last Check** (what changed)
**🟢 On Track** (brief — things moving normally)
**📊 Quick Stats** (open todos: N | completed this week: N | stale: N)

Keep it tight. No fluff. If there's nothing notable, just say "All clear — nothing urgent since your last check-in" with the stats.

## Changelog
- 2026-03-19: Initial version
