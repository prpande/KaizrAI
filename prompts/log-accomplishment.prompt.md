# Log Accomplishment

## Goal
Quick capture of a notable achievement. Under 30 seconds.

## Context
- Database: `accomplishments.db` via `bash scripts/workspace-db.sh --action log-accomplishment`
- Reference: `schemas/accomplishments-schema.md` for valid categories

## Instructions
1. Ask for (or extract from conversation):
   - **Title**: What was accomplished (required)
   - **Category**: One of: project-delivery, technical-leadership, incident-response, mentoring, process-improvement, collaboration (required)
   - **Impact**: Business or team impact statement (optional but encouraged)
   - **Description**: Additional detail (optional)
2. Auto-fill date to today unless the user specifies otherwise
3. If a related todo exists, link it via related_todo_id
4. Run `bash scripts/workspace-db.sh --action log-accomplishment` with the collected data
5. Confirm what was logged

## Output
"✅ Logged: **[title]** under [category] on [date]."
If impact was provided: "Impact noted: [impact]"

## Changelog
- 2026-03-19: Initial version
