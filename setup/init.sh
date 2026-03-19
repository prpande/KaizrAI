#!/usr/bin/env bash
# init.sh — Setup script for AI Assistant Workspace
# Creates data directory, initializes databases, copies templates.
#
# Usage:
#   bash setup/init.sh                                    # Interactive
#   bash setup/init.sh --data-dir "/path/to/data"         # Non-interactive

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Argument Parsing ---
DATA_DIR_ARG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --data-dir) DATA_DIR_ARG="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# --- Welcome ---
echo "========================================"
echo "  AI Assistant Workspace — Setup"
echo "========================================"
echo ""

# --- Step 1: Get data directory ---
if [[ -n "$DATA_DIR_ARG" ]]; then
    WORKSPACE_DATA_DIR="$DATA_DIR_ARG"
    echo "Using data directory: $WORKSPACE_DATA_DIR"
else
    DEFAULT_DIR="$HOME/OneDrive/ai-assistant-data"
    echo "Where should your data directory be created?"
    echo "This should be in a cloud-synced folder (OneDrive, Google Drive, Dropbox)."
    echo ""
    read -rp "Data directory [$DEFAULT_DIR]: " WORKSPACE_DATA_DIR
    WORKSPACE_DATA_DIR="${WORKSPACE_DATA_DIR:-$DEFAULT_DIR}"
fi

# Expand tilde
WORKSPACE_DATA_DIR="${WORKSPACE_DATA_DIR/#\~/$HOME}"

echo ""

# --- Step 2: Check prerequisites ---
echo "Checking prerequisites..."
MISSING=()

command -v sqlite3 >/dev/null 2>&1 || MISSING+=("sqlite3")
command -v jq >/dev/null 2>&1 || MISSING+=("jq")
command -v gh >/dev/null 2>&1 || MISSING+=("gh (GitHub CLI)")
command -v git >/dev/null 2>&1 || MISSING+=("git")

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "ERROR: Missing required tools:"
    for tool in "${MISSING[@]}"; do
        echo "  - $tool"
    done
    echo ""
    echo "Install them and re-run this script."
    exit 1
fi
echo "  All prerequisites found."
echo ""

# --- Step 3: Create .env ---
echo "Creating .env file..."
cat > "$REPO_ROOT/.env" <<EOF
WORKSPACE_DATA_DIR=$WORKSPACE_DATA_DIR
EOF
echo "  Created: $REPO_ROOT/.env"
echo ""

# --- Step 4: Create directory structure ---
echo "Creating data directory structure..."
mkdir -p "$WORKSPACE_DATA_DIR/memory/stable"
mkdir -p "$WORKSPACE_DATA_DIR/memory/active"
mkdir -p "$WORKSPACE_DATA_DIR/data"
mkdir -p "$WORKSPACE_DATA_DIR/data/backups"
mkdir -p "$WORKSPACE_DATA_DIR/logs"
echo "  Created directory tree at: $WORKSPACE_DATA_DIR"
echo ""

# --- Step 5: Initialize databases ---
echo "Initializing databases..."

init_db() {
    local db_name="$1"
    local schema_sql="$2"
    local db_path="$WORKSPACE_DATA_DIR/data/$db_name"

    if [[ -f "$db_path" ]]; then
        echo "  $db_name already exists, skipping."
        return
    fi

    sqlite3 "$db_path" "$schema_sql"
    # Verify
    local check
    check="$(sqlite3 "$db_path" "PRAGMA integrity_check;")"
    if [[ "$check" == "ok" ]]; then
        echo "  Initialized: $db_name"
    else
        echo "  ERROR: $db_name failed integrity check!"
        exit 1
    fi
}

# todos.db
init_db "todos.db" "
PRAGMA journal_mode=DELETE;
CREATE TABLE todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'open',
    priority TEXT NOT NULL DEFAULT 'medium', owner TEXT, source TEXT, source_ref TEXT, category TEXT,
    created_date TEXT NOT NULL, due_date TEXT, completed_date TEXT, cancelled_date TEXT,
    last_touched TEXT NOT NULL, notes TEXT, parent_id INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (parent_id) REFERENCES todos(id)
);
CREATE INDEX idx_todos_status ON todos(status);
CREATE INDEX idx_todos_priority ON todos(priority);
CREATE INDEX idx_todos_category ON todos(category);
CREATE INDEX idx_todos_due_date ON todos(due_date);
CREATE INDEX idx_todos_last_touched ON todos(last_touched);
CREATE TABLE IF NOT EXISTS _meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
INSERT INTO _meta (key, value) VALUES ('schema_version', '1');
"

# accomplishments.db
init_db "accomplishments.db" "
PRAGMA journal_mode=DELETE;
CREATE TABLE accomplishments (
    id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, category TEXT NOT NULL,
    title TEXT NOT NULL, description TEXT, impact TEXT, links TEXT, tags TEXT,
    related_todo_id INTEGER, created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);
CREATE INDEX idx_accomplishments_date ON accomplishments(date);
CREATE INDEX idx_accomplishments_category ON accomplishments(category);
CREATE TABLE IF NOT EXISTS _meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
INSERT INTO _meta (key, value) VALUES ('schema_version', '1');
"

# decisions.db
init_db "decisions.db" "
PRAGMA journal_mode=DELETE;
CREATE TABLE decisions (
    id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, context TEXT NOT NULL,
    decision TEXT NOT NULL, rationale TEXT NOT NULL, alternatives TEXT, stakeholders TEXT,
    outcome TEXT, outcome_date TEXT, tags TEXT, related_todo_id INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);
CREATE INDEX idx_decisions_date ON decisions(date);
CREATE INDEX idx_decisions_tags ON decisions(tags);
CREATE TABLE IF NOT EXISTS _meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
INSERT INTO _meta (key, value) VALUES ('schema_version', '1');
"

# automation-runs.db
init_db "automation-runs.db" "
PRAGMA journal_mode=DELETE;
CREATE TABLE runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, automation TEXT NOT NULL,
    started_at TEXT NOT NULL, completed_at TEXT, status TEXT NOT NULL DEFAULT 'running',
    steps_completed TEXT, steps_skipped TEXT, error_details TEXT, notes TEXT,
    duration_seconds INTEGER, created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);
CREATE INDEX idx_runs_date ON runs(date);
CREATE INDEX idx_runs_automation ON runs(automation);
CREATE INDEX idx_runs_status ON runs(status);
CREATE TABLE IF NOT EXISTS _meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
INSERT INTO _meta (key, value) VALUES ('schema_version', '1');
"

# changelog.db
init_db "changelog.db" "
PRAGMA journal_mode=DELETE;
CREATE TABLE changelog (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    database_name TEXT NOT NULL, table_name TEXT NOT NULL, operation TEXT NOT NULL,
    record_id INTEGER, changed_fields TEXT, old_values TEXT, new_values TEXT,
    source TEXT DEFAULT 'workspace-db'
);
CREATE INDEX idx_changelog_timestamp ON changelog(timestamp);
CREATE INDEX idx_changelog_database ON changelog(database_name);
CREATE INDEX idx_changelog_record ON changelog(database_name, record_id);
CREATE TABLE IF NOT EXISTS _meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
INSERT INTO _meta (key, value) VALUES ('schema_version', '1');
"

echo ""

# --- Step 6: Copy templates ---
echo "Copying memory templates..."
TEMPLATE_DIR="$SCRIPT_DIR/templates"

copy_template() {
    local src="$1"
    local dest="$2"
    if [[ -f "$dest" ]]; then
        echo "  $(basename "$dest") already exists, skipping."
    else
        cp "$src" "$dest"
        echo "  Copied: $(basename "$dest")"
    fi
}

copy_template "$TEMPLATE_DIR/me.md" "$WORKSPACE_DATA_DIR/memory/stable/me.md"
copy_template "$TEMPLATE_DIR/team.md" "$WORKSPACE_DATA_DIR/memory/stable/team.md"
copy_template "$TEMPLATE_DIR/preferences.md" "$WORKSPACE_DATA_DIR/memory/stable/preferences.md"
copy_template "$TEMPLATE_DIR/current-sprint.md" "$WORKSPACE_DATA_DIR/memory/active/current-sprint.md"
copy_template "$TEMPLATE_DIR/weekly-context.md" "$WORKSPACE_DATA_DIR/memory/active/weekly-context.md"

echo ""

# --- Step 7: Verify ---
echo "Verifying setup..."
ERRORS=()

[[ -f "$REPO_ROOT/.env" ]] || ERRORS+=(".env file missing")
[[ -d "$WORKSPACE_DATA_DIR/memory/stable" ]] || ERRORS+=("memory/stable dir missing")
[[ -d "$WORKSPACE_DATA_DIR/memory/active" ]] || ERRORS+=("memory/active dir missing")
[[ -d "$WORKSPACE_DATA_DIR/data" ]] || ERRORS+=("data dir missing")
[[ -d "$WORKSPACE_DATA_DIR/data/backups" ]] || ERRORS+=("data/backups dir missing")
[[ -d "$WORKSPACE_DATA_DIR/logs" ]] || ERRORS+=("logs dir missing")

for db in todos.db accomplishments.db decisions.db automation-runs.db changelog.db; do
    if [[ ! -f "$WORKSPACE_DATA_DIR/data/$db" ]]; then
        ERRORS+=("$db missing")
    else
        local_check="$(sqlite3 "$WORKSPACE_DATA_DIR/data/$db" "PRAGMA integrity_check;" 2>&1)"
        [[ "$local_check" == "ok" ]] || ERRORS+=("$db integrity check failed")
    fi
done

if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "  ERRORS found:"
    for err in "${ERRORS[@]}"; do
        echo "    - $err"
    done
    exit 1
fi

echo "  All checks passed!"
echo ""

# --- Done ---
echo "========================================"
echo "  Setup complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Fill in your details:  $WORKSPACE_DATA_DIR/memory/stable/me.md"
echo "  2. Add team info:         $WORKSPACE_DATA_DIR/memory/stable/team.md"
echo "  3. Review preferences:    $WORKSPACE_DATA_DIR/memory/stable/preferences.md"
echo "  4. Start Claude Code in this directory and say 'start my day'"
echo ""
