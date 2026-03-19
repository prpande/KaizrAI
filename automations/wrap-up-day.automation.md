# Wrap Up Day

## Goal
End-of-day close-out — review, log, prepare for tomorrow.

## Steps

### Step 1: Record Run
- Run `bash scripts/workspace-db.sh --action start-run --params '{"automation":"wrap-up-day"}'`
- Save the returned run ID for later
- **On failure**: Warn the user and continue — don't block the review over logging

### Step 2: Day Review
- Execute `wrap-up.prompt.md`
- **On failure**: Note "Day review skipped" and continue

### Step 3: Accomplishment Capture
- Based on wrap-up results, offer to log accomplishments for notable completions
- Execute `log-accomplishment.prompt.md` for each the user confirms
- **On failure**: Note "Accomplishment capture skipped" and continue

### Step 4: Tomorrow Preview
- Show top 3 priority items for tomorrow
- Flag any items due tomorrow
- **On failure**: Note "Tomorrow preview skipped" and continue

### Step 5: Update Weekly Context
- Append a day-end summary to `memory/active/weekly-context.md`
- Format: `### [Day, Date]\n- [2-3 bullets on what happened]\n`
- If today's entry already exists (same date header), overwrite it rather than appending a duplicate
- **On failure**: Note "Weekly context update skipped" and continue

### Step 6: Record Completion
- Run `bash scripts/workspace-db.sh --action complete-run --params '{"id":"<id>","steps_completed":"<list>","steps_skipped":"<list>"}'`

## Error Handling
- Same pattern as morning automation — log, note under "⚠️ Skipped Steps", continue, never fail silently
- If the data directory is completely inaccessible: stop and guide user through troubleshooting

## Changelog
- 2026-03-19: Initial version
