# Start Work Day

## Goal
Morning kickoff — gather context, review status, produce a prioritized daily briefing.

## Steps

### Step 1: Record Run
- Run `bash scripts/workspace-db.sh --action start-run --params '{"automation":"start-work-day"}'`
- Save the returned run ID for later

### Step 2: Gather Todos
- Run `bash scripts/workspace-db.sh --action list-todos --params '{"status":"open"}'`
- Also run with `{"status":"in-progress"}`
- Present as a formatted markdown table sorted by priority then staleness
- Ask: "Any new tasks to add, priority changes, or updates?"
- If user provides updates, process them before continuing
- **On failure**: Log error, show "Could not load todos — database may be inaccessible. Check .env and data directory." Continue to next step.

### Step 3: Check for Incidents
- Execute `check-incidents.prompt.md`
- **On failure**: Note "Incident check skipped (monitoring not configured or unavailable)" and continue

### Step 4: Check Pull Requests
- Execute `check-pull-requests.prompt.md`
- **On failure**: Note "PR check skipped (GitHub CLI not configured or unavailable)" and continue

### Step 5: Yesterday Close-Out
- Execute `review-completed-todos.prompt.md` scoped to yesterday
- Check for todos completed yesterday that weren't logged as accomplishments
- Offer to log any notable ones (once, don't push)
- **On failure**: Note "Yesterday review skipped" and continue

### Step 6: Stale In-Progress Cleanup
- Query todos with status=in-progress AND last_touched > 3 days ago
- For each: "⚠️ [title] has been in-progress for [N] days — is it stuck, still active, or should we update it?"
- **On failure**: Note "Stale check skipped" and continue

### Step 7: Priority Briefing
- Synthesize all gathered information into a ranked daily focus:

**🔴 URGENT** — Active incidents, blocked PRs, overdue items
**🟠 IMPORTANT** — High-priority todos, items blocking teammates
**📅 SCHEDULED** — Meetings with prep needed (if calendar integration exists)
**🔵 BACKGROUND** — PRs in normal flow, low-priority todos

- Include a load assessment: total open items, added vs completed this week
- **Be opinionated** — if there are too many open items (>25), say so and suggest what to drop or cancel
- If nothing is urgent, say so clearly — don't manufacture urgency

### Step 8: Record Completion
- Run `bash scripts/workspace-db.sh --action complete-run --params '{"id":"<id>","steps_completed":"<list>","steps_skipped":"<list>"}'` with the run ID, listing all steps completed and any skipped
- If any steps failed, use `bash scripts/workspace-db.sh --action fail-run --params '{"id":"<id>","error":"<details>","steps_completed":"<list>"}'` instead with error details

## Error Handling
- If Step 1 fails (can't record run): warn the user and continue — don't block the briefing over logging
- If the data directory is completely inaccessible: stop and guide user through troubleshooting
- For all other step failures: log, note in briefing under "⚠️ Skipped Steps", continue
- Never fail silently — always tell the user what was skipped and why

## Changelog
- 2026-03-19: Initial version
