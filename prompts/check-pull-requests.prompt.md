# Check Pull Requests

## Goal
Overview of open PRs — what needs action, what's on track.

## Context
- GitHub: `gh` CLI (required — skip gracefully if not authenticated)
- Memory: `{DATA_DIR}/memory/stable/me.md` for GitHub username
- Memory: `{DATA_DIR}/memory/stable/team.md` for team repos and teammates

## Instructions
1. Read user identity and team info from memory files
2. If `gh auth status` fails, output: "GitHub CLI not authenticated. Run: gh auth login"
3. If authenticated, query for:
   - `gh pr list --author @me --state open --json number,title,createdAt,reviewDecision,statusCheckRollup,url`
   - `gh pr list --search "review-requested:@me" --state open --json number,title,author,url`
   - `gh pr list --state open --json number,title,author,url` (for team awareness, filter by team repos from memory)
4. For each PR, flag:
   - 🔴 Stale (>3 days no activity)
   - 🔴 Failing CI
   - 🟡 Missing reviews (no approvals yet)
   - 🟡 Changes requested
   - 🟢 Approved, ready to merge

## Output
**🎯 Action Required**
[PRs that need the user to do something — review, fix CI, address feedback]

**👀 Authored — In Progress**
[User's PRs that are in normal flow]

**📋 Team Activity**
[Teammates' PRs — brief awareness list]

If no PRs in any category, say so clearly.

## Changelog
- 2026-03-19: Initial version
