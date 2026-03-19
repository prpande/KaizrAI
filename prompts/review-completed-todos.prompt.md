# Review Completed Todos

## Goal
Surface recently completed work that might deserve an accomplishment log entry.

## Context
- Database: `todos.db` via `bash scripts/workspace-db.sh --action list-todos`
- Database: `accomplishments.db` via `bash scripts/workspace-db.sh --action list-accomplishments`

## Instructions
1. Query todos completed since last check-in (or last 24 hours if no prior run data)
2. Cross-reference with accomplishments — skip any that are already logged
3. For each unlogged completed todo, assess if it's accomplishment-worthy:
   - Priority was high or critical
   - Category is project or technical
   - Title suggests meaningful work (not just "reply to email")
4. Present candidates to the user

## Output
"Found [N] completed todos since your last check-in. [M] look worth logging:"

List each candidate with a brief reason why it might be notable. Ask: "Want me to log any of these?"

## Changelog
- 2026-03-19: Initial version
