# Accomplishments Database Schema

## Table: accomplishments

```sql
CREATE TABLE accomplishments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    category TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    impact TEXT,
    links TEXT,
    tags TEXT,
    related_todo_id INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);

CREATE INDEX idx_accomplishments_date ON accomplishments(date);
CREATE INDEX idx_accomplishments_category ON accomplishments(category);
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

### Category
| Value | Description |
|-------|-------------|
| `project-delivery` | Shipped features, completed milestones, met deadlines |
| `technical-leadership` | Architecture decisions, technical strategy, code quality improvements |
| `incident-response` | Outage resolution, root cause analysis, reliability improvements |
| `mentoring` | Helped teammates grow, conducted reviews, onboarding |
| `process-improvement` | Made workflows better, reduced toil, improved documentation |
| `collaboration` | Cross-team projects, stakeholder alignment, communication wins |

## Example Queries

```sql
-- Last 6 months grouped by category
SELECT category, COUNT(*) as count FROM accomplishments
WHERE date >= date('now', 'localtime', '-6 months')
GROUP BY category;

-- Full export for performance review
SELECT date, category, title, impact, description FROM accomplishments
WHERE date BETWEEN '2026-01-01' AND '2026-06-30'
ORDER BY date ASC;

-- Search by tags
SELECT * FROM accomplishments WHERE tags LIKE '%keyword%';

-- Monthly trend
SELECT strftime('%Y-%m', date) as month, COUNT(*) as count
FROM accomplishments GROUP BY month ORDER BY month;
```
