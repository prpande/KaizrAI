#!/usr/bin/env bash
# db-common.sh — Shared functions for all workspace database scripts
# Sourced by domain scripts and the dispatcher. Never run directly.
#
# NOTE: We do NOT use `set -euo pipefail` here because we need structured
# JSON error output. If set -e is active, failures in sqlite3/jq calls
# crash the script before json_error() can run. Instead, we check return
# codes explicitly where needed.

# Resolve the repo root (directory containing .env)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Environment ---

load_env() {
    local env_file="$REPO_ROOT/.env"
    if [[ ! -f "$env_file" ]]; then
        json_error "Missing .env file. Run: bash setup/init.sh"
        exit 1
    fi

    # Source .env safely (only WORKSPACE_DATA_DIR expected)
    WORKSPACE_DATA_DIR=""
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        # Trim whitespace via bash parameter expansion (safe, no xargs edge cases)
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        if [[ "$key" == "WORKSPACE_DATA_DIR" ]]; then
            WORKSPACE_DATA_DIR="$value"
        fi
    done < "$env_file"

    if [[ -z "$WORKSPACE_DATA_DIR" ]]; then
        json_error "WORKSPACE_DATA_DIR not set in .env"
        exit 1
    fi

    # Expand tilde
    WORKSPACE_DATA_DIR="${WORKSPACE_DATA_DIR/#\~/$HOME}"

    if [[ ! -d "$WORKSPACE_DATA_DIR" ]]; then
        json_error "Data directory does not exist: $WORKSPACE_DATA_DIR"
        exit 1
    fi

    DATA_DIR="$WORKSPACE_DATA_DIR/data"
    BACKUP_DIR="$DATA_DIR/backups"
    export WORKSPACE_DATA_DIR DATA_DIR BACKUP_DIR
}

# --- Database Execution ---

# Ensure journal_mode=DELETE is set. This is persistent per database file,
# so we set it once and suppress output. Separated from queries to avoid
# PRAGMA output corrupting JSON results.
_ensure_journal_mode() {
    local db_path="$1"
    sqlite3 "$db_path" "PRAGMA journal_mode=DELETE;" > /dev/null 2>&1
}

# Read-only query. Returns JSON array via sqlite3 -json.
db_query() {
    local db_path="$1"
    local sql="$2"
    _ensure_journal_mode "$db_path"
    local result
    if ! result="$(sqlite3 -json "$db_path" "$sql" 2>&1)"; then
        json_error "Database query failed: $result"
        return 1
    fi
    # sqlite3 -json returns empty string for no results; normalize to []
    if [[ -z "$result" ]]; then
        echo "[]"
    else
        echo "$result"
    fi
}

# Read-only count query. Returns a plain integer.
db_count() {
    local db_path="$1"
    local sql="$2"
    _ensure_journal_mode "$db_path"
    sqlite3 "$db_path" "$sql" 2>/dev/null || echo "0"
}

# Write operation. Wraps in BEGIN IMMEDIATE transaction automatically.
db_write() {
    local db_path="$1"
    local sql="$2"
    _ensure_journal_mode "$db_path"
    if ! sqlite3 "$db_path" "BEGIN IMMEDIATE; $sql; COMMIT;" > /dev/null 2>&1; then
        json_error "Database write failed"
        return 1
    fi
}

# Write + return the affected row as JSON. Runs write in transaction,
# then selects the result separately (still same connection via heredoc).
db_write_and_return() {
    local db_path="$1"
    local write_sql="$2"
    local select_sql="$3"
    _ensure_journal_mode "$db_path"
    local result
    if ! result="$(sqlite3 -json "$db_path" <<EOF
BEGIN IMMEDIATE;
$write_sql
COMMIT;
$select_sql
EOF
    2>&1)"; then
        json_error "Database write failed: $result"
        return 1
    fi
    if [[ -z "$result" ]]; then
        echo "[]"
    else
        echo "$result"
    fi
}

# --- Changelog ---

write_changelog() {
    local database_name="$1"
    local table_name="$2"
    local operation="$3"
    local record_id="$4"
    local changed_fields="${5:-}"
    local old_values="${6:-}"
    local new_values="${7:-}"

    # Validate record_id is numeric
    if [[ ! "$record_id" =~ ^[0-9]+$ ]]; then
        return 1  # silently skip — don't break the main operation over changelog
    fi

    local changelog_db="$DATA_DIR/changelog.db"
    local sql="INSERT INTO changelog (database_name, table_name, operation, record_id, changed_fields, old_values, new_values)
        VALUES ($(sql_nullable "$database_name"), $(sql_nullable "$table_name"), $(sql_nullable "$operation"), $record_id,
                $(sql_nullable "$changed_fields"),
                $(sql_nullable "$old_values"),
                $(sql_nullable "$new_values"));"
    db_write "$changelog_db" "$sql" > /dev/null 2>&1 || true
}

# --- JSON Output ---

json_success() {
    local action="$1"
    local message="$2"
    local record="${3:-null}"
    if [[ "$record" == "null" || -z "$record" || "$record" == "[]" ]]; then
        jq -n --arg action "$action" --arg message "$message" \
            '{"success": true, "action": $action, "message": $message}'
    else
        echo "$record" | jq --arg action "$action" --arg message "$message" \
            '{"success": true, "action": $action, "message": $message, "record": (if type == "array" then .[0] else . end)}'
    fi
}

json_success_list() {
    local action="$1"
    local records="$2"
    local count="$3"
    echo "$records" | jq --arg action "$action" --argjson count "$count" \
        '{"success": true, "action": $action, "count": $count, "records": .}'
}

json_error() {
    local message="$1"
    local action="${2:-unknown}"
    jq -n --arg action "$action" --arg error "$message" \
        '{"success": false, "action": $action, "error": $error}'
}

# --- Validation ---

validate_required() {
    local field_name="$1"
    local value="$2"
    local action="$3"
    if [[ -z "$value" || "$value" == "null" ]]; then
        json_error "Missing required field: $field_name" "$action"
        exit 1
    fi
}

validate_enum() {
    local field_name="$1"
    local value="$2"
    local allowed="$3"  # pipe-separated: "open|in-progress|done|cancelled"
    local action="$4"

    if [[ -z "$value" || "$value" == "null" ]]; then
        return 0  # null/empty is OK for optional enums
    fi

    if [[ ! "$value" =~ ^($allowed)$ ]]; then
        json_error "Invalid $field_name: '$value'. Allowed: $(echo "$allowed" | tr '|' ', ')" "$action"
        exit 1
    fi
}

# Validate that a value is a positive integer (for IDs, stale_days, etc.)
validate_integer() {
    local field_name="$1"
    local value="$2"
    local action="$3"
    if [[ -n "$value" && "$value" != "null" && ! "$value" =~ ^[0-9]+$ ]]; then
        json_error "Invalid $field_name: '$value' (must be a positive integer)" "$action"
        exit 1
    fi
}

# --- Param Parsing ---

# Extract a field from JSON params. Returns empty string if not found.
param() {
    local params="$1"
    local field="$2"
    local value
    value="$(echo "$params" | jq -r --arg f "$field" '.[$f] // empty' 2>/dev/null)"
    echo "$value"
}

# --- SQL Helpers ---

# Wrap a value in SQL quotes, or return NULL if empty.
sql_nullable() {
    local value="$1"
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "NULL"
    else
        # Escape single quotes for SQL
        local escaped="${value//\'/\'\'}"
        echo "'$escaped'"
    fi
}

# Escape a value for use in SQL LIKE patterns. Escapes %, _, and '.
# IMPORTANT: Callers MUST include ESCAPE '\' in the LIKE expression, e.g.:
#   sql_escape_like "$term" → escaped
#   WHERE col LIKE '%' || '$escaped' || '%' ESCAPE '\'
# Without ESCAPE '\', backslash-escaped wildcards are NOT treated as literals.
sql_escape_like() {
    local value="$1"
    # Escape single quotes
    value="${value//\'/\'\'}"
    # Escape LIKE wildcards (we add our own % around the value)
    value="${value//%/\\%}"
    value="${value//_/\\_}"
    echo "$value"
}

# Current datetime in local time, formatted for SQLite.
now_local() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Current date in local time.
today_local() {
    date '+%Y-%m-%d'
}

# Parse a datetime string to epoch seconds. Cross-platform (GNU date + BSD date fallback).
datetime_to_epoch() {
    local dt="$1"
    # GNU date (Linux, most Git Bash on Windows)
    date -d "$dt" +%s 2>/dev/null && return
    # BSD date (macOS)
    date -j -f '%Y-%m-%d %H:%M:%S' "$dt" +%s 2>/dev/null && return
    # Fallback: return 0 (duration will be 0)
    echo 0
}
