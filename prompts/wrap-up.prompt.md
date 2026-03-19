# Wrap Up Day

## Goal
End-of-day close-out — review what got done, flag what slipped, capture accomplishments. 2 minutes max.

## Context
- Database: `todos.db` via `bash scripts/workspace-db.sh --action list-todos`
- Database: `accomplishments.db` via `bash scripts/workspace-db.sh --action log-accomplishment`
- Memory: `{DATA_DIR}/memory/active/weekly-context.md`

## Instructions
1. Read `.env` to get `WORKSPACE_DATA_DIR`
2. Query todos completed today (`completed_date = today`)
3. Query todos that were in-progress but not completed (carried over)
4. Check for any items that became overdue today
5. For each completed todo, assess if it's worth logging as an accomplishment:
   - Was it high-priority or critical?
   - Did it involve cross-team collaboration?
   - Was it a multi-day effort?
   - If yes to any, offer to log it (once, don't push)
6. Update `memory/active/weekly-context.md` with a brief end-of-day note:
   - Append a date header and 2-3 bullet points on what happened today
   - Never overwrite existing content — always append

## Output
**✅ Completed Today** (list with brief notes)
**➡️ Carrying Over** (in-progress items rolling to tomorrow)
**⚠️ Slipped** (items that were due today but not done — skip if none)
**💡 Worth Logging?** (suggested accomplishments — ask, don't auto-log)

End with: "Have a good evening. Tomorrow's top priority looks like: [highest priority open item]"

## Changelog
- 2026-03-19: Initial version
