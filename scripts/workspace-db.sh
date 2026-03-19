#!/usr/bin/env bash
# workspace-db.sh — Dispatcher for all database operations
# Routes --action to the appropriate domain script.
#
# Usage:
#   bash scripts/workspace-db.sh --action <action-name> [--params '<json>']
#
# Examples:
#   bash scripts/workspace-db.sh --action add-todo --params '{"title":"Fix bug","priority":"high"}'
#   bash scripts/workspace-db.sh --action list-todos --params '{"status":"open"}'
#   bash scripts/workspace-db.sh --action backup
#   bash scripts/workspace-db.sh --action stats

# NOTE: We intentionally do NOT use set -euo pipefail here.
# Domain scripts need to catch errors and return structured JSON via json_error().
# set -e would cause immediate exit on any sqlite3/jq failure, bypassing error handling.
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
ACTION=""
PARAMS="{}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --action) ACTION="$2"; shift 2 ;;
        --params) PARAMS="$2"; shift 2 ;;
        *) jq -n --arg arg "$1" '{"success":false,"error":("Unknown argument: " + $arg)}'; exit 1 ;;
    esac
done

if [[ -z "$ACTION" ]]; then
    echo '{"success":false,"error":"Missing --action argument"}'
    exit 1
fi

# Source shared library and load environment
source "$SCRIPT_DIR/db-common.sh"
load_env

# Map action to function name (replace hyphens with underscores)
FUNC_NAME="${ACTION//-/_}"

# Route to domain script
case "$ACTION" in
    add-todo|update-todo|complete-todo|cancel-todo|list-todos)
        source "$SCRIPT_DIR/todos.sh" || { json_error "Failed to load todos.sh" "$ACTION"; exit 1; }
        ;;
    log-accomplishment|list-accomplishments|export-accomplishments)
        source "$SCRIPT_DIR/accomplishments.sh" || { json_error "Failed to load accomplishments.sh" "$ACTION"; exit 1; }
        ;;
    log-decision|list-decisions)
        source "$SCRIPT_DIR/decisions.sh" || { json_error "Failed to load decisions.sh" "$ACTION"; exit 1; }
        ;;
    start-run|complete-run|fail-run|list-runs)
        source "$SCRIPT_DIR/runs.sh" || { json_error "Failed to load runs.sh" "$ACTION"; exit 1; }
        ;;
    backup|stats|health)
        source "$SCRIPT_DIR/db-utils.sh" || { json_error "Failed to load db-utils.sh" "$ACTION"; exit 1; }
        ;;
    *)
        json_error "Unknown action: $ACTION" "$ACTION"
        exit 1
        ;;
esac

# Call the function
if [[ "$ACTION" == "backup" || "$ACTION" == "stats" || "$ACTION" == "health" ]]; then
    "$FUNC_NAME"
else
    "$FUNC_NAME" "$PARAMS"
fi
