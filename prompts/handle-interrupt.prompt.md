# Handle Interrupt

## Goal
Capture an urgent incoming item and re-prioritize the day's plan.

## Context
- Database: `todos.db` via `bash scripts/workspace-db.sh`
- Memory: `{DATA_DIR}/memory/active/weekly-context.md`

## Instructions
1. Ask for (or extract from conversation):
   - What's the urgent item?
   - Why is it urgent? (blocking someone? deadline? incident?)
   - Estimated time to handle?
2. Add it as a new todo with priority=critical or high
3. Query current open todos sorted by priority
4. Suggest what to defer or deprioritize to make room:
   - Look for medium/low priority items that can wait
   - Look for items with flexible due dates
   - Never suggest deferring other critical items without explicit confirmation
5. Update `memory/active/weekly-context.md` with a note about the interrupt

## Output
"Added: **[urgent item]** as [priority]."
"To make room, I suggest deferring:"
- [item] — [reason it can wait]

"Your updated priority stack for today:"
1. [item]
2. [item]
...

## Changelog
- 2026-03-19: Initial version
