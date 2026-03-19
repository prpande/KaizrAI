# Todos Database Schema

## Table: todos

```sql
CREATE TABLE todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open',
    priority TEXT NOT NULL DEFAULT 'medium',
    owner TEXT,
    source TEXT,
    source_ref TEXT,
    category TEXT,
    created_date TEXT NOT NULL,
    due_date TEXT,
    completed_date TEXT,
    cancelled_date TEXT,
    last_touched TEXT NOT NULL,
    notes TEXT,
    parent_id INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (parent_id) REFERENCES todos(id)
);

CREATE INDEX idx_todos_status ON todos(status);
CREATE INDEX idx_todos_priority ON todos(priority);
CREATE INDEX idx_todos_category ON todos(category);
CREATE INDEX idx_todos_due_date ON todos(due_date);
CREATE INDEX idx_todos_last_touched ON todos(last_touched);
```

## Meta Table

```sql
CREATE TABLE IF NOT EXISTS _meta (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
INSERT INTO _meta (key, value) VALUES ('schema_version', '1');
```

## Enum Values

### Status
| Value | Description |
|-------|-------------|
| `open` | Not started |
| `in-progress` | Actively working on it |
| `done` | Completed |
| `cancelled` | No longer needed |

### Priority
| Value | Description |
|-------|-------------|
| `critical` | Drop everything |
| `high` | Today |
| `medium` | This week |
| `low` | When possible |

### Source
Where the todo originated: `manual`, `notion`, `jira`, `github`, `slack`, `standup`, `automation`

### Category
What domain the work falls into: `technical`, `process`, `project`, `admin`, `personal`

## Example Queries

```sql
-- All open todos sorted by priority then staleness
SELECT * FROM todos
WHERE status IN ('open', 'in-progress')
ORDER BY
    CASE priority WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 END,
    last_touched ASC;

-- Stale items (last_touched > 7 days ago)
SELECT * FROM todos
WHERE status IN ('open', 'in-progress')
AND last_touched < datetime('now', 'localtime', '-7 days');

-- Completed this week
SELECT * FROM todos
WHERE status = 'done'
AND completed_date >= date('now', 'localtime', '-7 days');

-- Load by category
SELECT category, COUNT(*) as count FROM todos
WHERE status IN ('open', 'in-progress')
GROUP BY category;

-- Overdue items
SELECT * FROM todos
WHERE due_date < date('now', 'localtime')
AND status NOT IN ('done', 'cancelled');
```

## Indexing Notes
- `idx_todos_status`: Most queries filter by status (open/in-progress)
- `idx_todos_priority`: Sorting and filtering by priority in todo views
- `idx_todos_category`: Grouping by category for load analysis
- `idx_todos_due_date`: Finding overdue items efficiently
- `idx_todos_last_touched`: Staleness detection queries
