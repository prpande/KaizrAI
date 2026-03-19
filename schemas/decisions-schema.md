# Decisions Database Schema

## Table: decisions

```sql
CREATE TABLE decisions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    context TEXT NOT NULL,
    decision TEXT NOT NULL,
    rationale TEXT NOT NULL,
    alternatives TEXT,
    stakeholders TEXT,
    outcome TEXT,
    outcome_date TEXT,
    tags TEXT,
    related_todo_id INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);

CREATE INDEX idx_decisions_date ON decisions(date);
CREATE INDEX idx_decisions_tags ON decisions(tags);
```

## Meta Table

```sql
CREATE TABLE IF NOT EXISTS _meta (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
INSERT INTO _meta (key, value) VALUES ('schema_version', '1');
```

## Field Descriptions
- **context**: What situation prompted this decision
- **decision**: What was decided
- **rationale**: Why this option was chosen
- **alternatives**: What other options were considered (comma-separated or freeform)
- **stakeholders**: Who was involved or affected
- **outcome**: How it turned out (filled in later)
- **outcome_date**: When the outcome was recorded

## Example Queries

```sql
-- Decisions in a date range
SELECT * FROM decisions WHERE date BETWEEN '2026-01-01' AND '2026-03-31';

-- Search by keyword
SELECT * FROM decisions
WHERE context LIKE '%keyword%' OR decision LIKE '%keyword%' OR rationale LIKE '%keyword%';

-- Open loops (no recorded outcome, older than 30 days)
SELECT * FROM decisions
WHERE outcome IS NULL AND date < date('now', 'localtime', '-30 days');

-- Decisions by stakeholder
SELECT * FROM decisions WHERE stakeholders LIKE '%person-name%';
```
