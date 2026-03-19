# Automation Runs Database Schema

## Table: runs

```sql
CREATE TABLE runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    automation TEXT NOT NULL,
    started_at TEXT NOT NULL,
    completed_at TEXT,
    status TEXT NOT NULL DEFAULT 'running',
    steps_completed TEXT,
    steps_skipped TEXT,
    error_details TEXT,
    notes TEXT,
    duration_seconds INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);

CREATE INDEX idx_runs_date ON runs(date);
CREATE INDEX idx_runs_automation ON runs(automation);
CREATE INDEX idx_runs_status ON runs(status);
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
| `running` | Currently executing |
| `completed` | Finished successfully |
| `partial` | Some steps succeeded before failure (set by fail-run when steps_completed is non-empty) |
| `failed` | Failed with no successful steps |

## Example Queries

```sql
-- All runs today
SELECT * FROM runs WHERE date = date('now', 'localtime') ORDER BY started_at DESC;

-- Last run of a specific automation
SELECT * FROM runs WHERE automation = 'start-work-day'
ORDER BY started_at DESC LIMIT 1;

-- Failed/partial runs this week
SELECT * FROM runs
WHERE status IN ('failed', 'partial')
AND date >= date('now', 'localtime', '-7 days')
ORDER BY date DESC;

-- Run history for an automation with duration
SELECT date, automation, status, duration_seconds, steps_skipped
FROM runs ORDER BY started_at DESC LIMIT 20;
```
