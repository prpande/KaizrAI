# Changelog Database Schema

This is the audit trail. Every write operation to any database gets logged here.

## Table: changelog

```sql
CREATE TABLE changelog (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    database_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    record_id INTEGER,
    changed_fields TEXT,
    old_values TEXT,
    new_values TEXT,
    source TEXT DEFAULT 'workspace-db'
);

CREATE INDEX idx_changelog_timestamp ON changelog(timestamp);
CREATE INDEX idx_changelog_database ON changelog(database_name);
CREATE INDEX idx_changelog_record ON changelog(database_name, record_id);
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
- **operation**: `INSERT`, `UPDATE`, or `DELETE`
- **changed_fields**: JSON array of field names that changed
- **old_values**: JSON object of previous values (null for INSERT)
- **new_values**: JSON object of new values (null for DELETE)
- **source**: What wrote the entry (default: `workspace-db`)
