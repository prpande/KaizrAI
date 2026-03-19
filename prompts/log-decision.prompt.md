# Log Decision

## Goal
Record a decision with its rationale and alternatives for future reference.

## Context
- Database: `decisions.db` via `bash scripts/workspace-db.sh --action log-decision`

## Instructions
1. Ask for (or extract from conversation):
   - **Context**: What situation prompted this? (required)
   - **Decision**: What was decided? (required)
   - **Rationale**: Why this option? (required)
   - **Alternatives**: What else was considered? (optional)
   - **Stakeholders**: Who was involved? (optional)
2. Auto-fill date to today unless specified
3. If a related todo exists, link it
4. Log via `bash scripts/workspace-db.sh --action log-decision`

## Output
"📝 Decision logged:"
"**Context**: [context]"
"**Decision**: [decision]"
"**Rationale**: [rationale]"

"You can revisit this later with 'list decisions' or search by keyword."

## Changelog
- 2026-03-19: Initial version
