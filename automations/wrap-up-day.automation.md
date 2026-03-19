# Wrap Up Day

## Goal
End-of-day close-out — review, log, prepare for tomorrow.

## Steps

### Step 1: Record Run
- Run `bash scripts/workspace-db.sh --action start-run --params '{"automation":"wrap-up-day"}'`

### Step 2: Day Review
- Execute `wrap-up.prompt.md`

### Step 3: Accomplishment Capture
- Based on wrap-up results, offer to log accomplishments for notable completions
- Execute `log-accomplishment.prompt.md` for each the user confirms

### Step 4: Tomorrow Preview
- Show top 3 priority items for tomorrow
- Flag any items due tomorrow

### Step 5: Update Weekly Context
- Append a day-end summary to `memory/active/weekly-context.md`
- Format: `### [Day, Date]\n- [2-3 bullets on what happened]\n`

### Step 6: Record Completion
- Run `bash scripts/workspace-db.sh --action complete-run --params '{"id":"<id>","steps_completed":"<list>"}'`

## Error Handling
- Same pattern as morning automation — log, skip, continue, never fail silently

## Changelog
- 2026-03-19: Initial version
