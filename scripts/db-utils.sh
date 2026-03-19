#!/usr/bin/env bash
# db-utils.sh — Backup, stats, and health check utilities
# Sourced by workspace-db.sh dispatcher. Requires db-common.sh.

readonly ALL_DBS=("todos.db" "accomplishments.db" "decisions.db" "automation-runs.db" "changelog.db")
readonly MAX_BACKUPS=30

backup() {
    local timestamp
    timestamp="$(date '+%Y%m%d_%H%M%S')"
    local backed_up=()
    local total_size=0

    mkdir -p "$BACKUP_DIR"

    for db_name in "${ALL_DBS[@]}"; do
        local db_path="$DATA_DIR/$db_name"
        if [[ -f "$db_path" ]]; then
            local backup_name="${db_name%.db}_${timestamp}.db"
            cp "$db_path" "$BACKUP_DIR/$backup_name"
            backed_up+=("$db_name")

            local size
            size="$(wc -c < "$BACKUP_DIR/$backup_name" | xargs)"
            total_size=$((total_size + size))

            # Prune old backups for this database (keep MAX_BACKUPS most recent)
            local prefix="${db_name%.db}_"
            local count
            count="$(ls -1 "$BACKUP_DIR/${prefix}"*.db 2>/dev/null | wc -l | xargs)"
            if [[ "$count" -gt "$MAX_BACKUPS" ]]; then
                local to_delete=$((count - MAX_BACKUPS))
                ls -1t "$BACKUP_DIR/${prefix}"*.db | tail -n "$to_delete" | while read -r old_backup; do
                    rm "$old_backup"
                done
            fi
        fi
    done

    local human_size
    if [[ "$total_size" -gt 1048576 ]]; then
        human_size="$((total_size / 1048576))MB"
    elif [[ "$total_size" -gt 1024 ]]; then
        human_size="$((total_size / 1024))KB"
    else
        human_size="${total_size}B"
    fi

    local backed_json
    backed_json="$(printf '%s\n' "${backed_up[@]}" | jq -R . | jq -s .)"

    jq -n --argjson backed_up "$backed_json" \
        --arg backup_dir "$BACKUP_DIR" \
        --arg total_size "$human_size" \
        --arg timestamp "$timestamp" \
        '{"success": true, "action": "backup", "backed_up": $backed_up, "backup_dir": $backup_dir, "total_size": $total_size, "timestamp": $timestamp}'
}

stats() {
    local todos_db="$DATA_DIR/todos.db"
    local acc_db="$DATA_DIR/accomplishments.db"
    local dec_db="$DATA_DIR/decisions.db"
    local runs_db="$DATA_DIR/automation-runs.db"

    local todo_open=0 todo_in_progress=0 todo_done_week=0 todo_overdue=0 todo_stale=0
    local acc_month=0 acc_quarter=0 acc_total=0
    local dec_month=0 dec_open_loops=0
    local runs_today=0 runs_failed_week=0

    if [[ -f "$todos_db" ]]; then
        todo_open="$(db_count "$todos_db" "SELECT COUNT(*) FROM todos WHERE status = 'open';")"
        todo_in_progress="$(db_count "$todos_db" "SELECT COUNT(*) FROM todos WHERE status = 'in-progress';")"
        todo_done_week="$(db_count "$todos_db" "SELECT COUNT(*) FROM todos WHERE status = 'done' AND completed_date >= date('now', 'localtime', '-7 days');")"
        todo_overdue="$(db_count "$todos_db" "SELECT COUNT(*) FROM todos WHERE due_date < date('now', 'localtime') AND status NOT IN ('done', 'cancelled');")"
        todo_stale="$(db_count "$todos_db" "SELECT COUNT(*) FROM todos WHERE status IN ('open', 'in-progress') AND last_touched < datetime('now', 'localtime', '-7 days');")"
    fi

    if [[ -f "$acc_db" ]]; then
        acc_month="$(db_count "$acc_db" "SELECT COUNT(*) FROM accomplishments WHERE date >= date('now', 'localtime', 'start of month');")"
        acc_quarter="$(db_count "$acc_db" "SELECT COUNT(*) FROM accomplishments WHERE date >= date('now', 'localtime', '-3 months');")"
        acc_total="$(db_count "$acc_db" "SELECT COUNT(*) FROM accomplishments;")"
    fi

    if [[ -f "$dec_db" ]]; then
        dec_month="$(db_count "$dec_db" "SELECT COUNT(*) FROM decisions WHERE date >= date('now', 'localtime', 'start of month');")"
        dec_open_loops="$(db_count "$dec_db" "SELECT COUNT(*) FROM decisions WHERE outcome IS NULL AND date < date('now', 'localtime', '-30 days');")"
    fi

    if [[ -f "$runs_db" ]]; then
        runs_today="$(db_count "$runs_db" "SELECT COUNT(*) FROM runs WHERE date = date('now', 'localtime');")"
        runs_failed_week="$(db_count "$runs_db" "SELECT COUNT(*) FROM runs WHERE status IN ('failed', 'partial') AND date >= date('now', 'localtime', '-7 days');")"
    fi

    jq -n \
        --argjson todo_open "$todo_open" \
        --argjson todo_in_progress "$todo_in_progress" \
        --argjson todo_done_week "$todo_done_week" \
        --argjson todo_overdue "$todo_overdue" \
        --argjson todo_stale "$todo_stale" \
        --argjson acc_month "$acc_month" \
        --argjson acc_quarter "$acc_quarter" \
        --argjson acc_total "$acc_total" \
        --argjson dec_month "$dec_month" \
        --argjson dec_open_loops "$dec_open_loops" \
        --argjson runs_today "$runs_today" \
        --argjson runs_failed_week "$runs_failed_week" \
        '{
            "success": true,
            "action": "stats",
            "todos": {"open": $todo_open, "in_progress": $todo_in_progress, "done_this_week": $todo_done_week, "overdue": $todo_overdue, "stale": $todo_stale},
            "accomplishments": {"this_month": $acc_month, "this_quarter": $acc_quarter, "total": $acc_total},
            "decisions": {"this_month": $dec_month, "open_loops": $dec_open_loops},
            "automation_runs": {"today": $runs_today, "failed_this_week": $runs_failed_week}
        }'
}

health() {
    local results=()
    local all_healthy=true

    for db_name in "${ALL_DBS[@]}"; do
        local db_path="$DATA_DIR/$db_name"
        local status="healthy"
        local details=""

        if [[ ! -f "$db_path" ]]; then
            status="missing"
            details="Database file not found"
            all_healthy=false
        else
            # Integrity check
            local integrity
            integrity="$(sqlite3 "$db_path" "PRAGMA integrity_check;" 2>&1)"
            if [[ "$integrity" != "ok" ]]; then
                status="corrupt"
                details="Integrity check failed: $integrity"
                all_healthy=false
            else
                # Check schema version
                local version
                version="$(sqlite3 "$db_path" "SELECT value FROM _meta WHERE key = 'schema_version';" 2>/dev/null || echo "missing")"
                if [[ "$version" == "missing" ]]; then
                    status="warning"
                    details="Missing _meta table or schema_version"
                else
                    details="schema_version=$version, integrity=ok"
                fi
            fi
        fi

        results+=("$(jq -n --arg name "$db_name" --arg status "$status" --arg details "$details" \
            '{"database": $name, "status": $status, "details": $details}')")
    done

    local databases_json
    databases_json="$(printf '%s\n' "${results[@]}" | jq -s .)"

    jq -n --argjson databases "$databases_json" --argjson all_healthy "$all_healthy" \
        '{"success": true, "action": "health", "all_healthy": $all_healthy, "databases": $databases}'
}
