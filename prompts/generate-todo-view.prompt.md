# Todo View

## Goal
Generate a clean, prioritized, scannable view of all open todos.

## Context
- Database: `todos.db` via `bash scripts/workspace-db.sh --action list-todos`

## Instructions
1. Read `.env` to get `WORKSPACE_DATA_DIR`
2. Query all open and in-progress todos
3. Sort: critical first, then high, medium, low. Within each priority, sort by staleness (oldest last_touched first)
4. Flag stale items (>7 days untouched) with ⚠️
5. Flag very stale items (>14 days) with 🚨
6. Flag overdue items (past due_date) with 🔴
7. Show a load summary at the top

## Output
**📋 Open Todos: [N total] | 🔴 [N] critical | 🟡 [N] in-progress | ⚠️ [N] stale**

| # | Priority | Status | Title | Age | Due | Category |
|---|----------|--------|-------|-----|-----|----------|
| ... rows ... |

If total open items > 20, add a note: "You have [N] open items. Consider reviewing low-priority items for cancellation."

## Changelog
- 2026-03-19: Initial version
