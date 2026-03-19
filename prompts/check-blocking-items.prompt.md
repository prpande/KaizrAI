# Check Blocking Items

## Goal
Find items where you're blocking others — PRs awaiting your review, questions in Slack, action items others depend on.

## Context
- GitHub: `gh` CLI (for PR reviews requested)
- MCP: Slack (if configured — for unanswered questions)
- Database: `todos.db` for items others depend on

## Instructions
> **This is a stub.** Customize based on your collaboration tools:
>
> 1. Check GitHub for PRs where you're a requested reviewer:
>    `gh pr list --search "review-requested:@me" --state open --json number,title,author,url`
> 2. If Slack MCP is available, check for unanswered DMs or mentions
> 3. Check todos with notes mentioning "blocks [person]" or "waiting on me"

If relevant integrations are not configured, check only the todos database and output a note about enabling more integrations.

## Output
**🚧 You're Blocking** (items others are waiting on you for)
**✅ No Blockers** (if nothing to report)

## Changelog
- 2026-03-19: Initial stub
