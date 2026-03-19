#!/usr/bin/env bash
# runs.sh — Automation run tracking
# Sourced by workspace-db.sh dispatcher. Requires db-common.sh.

RUNS_DB="$DATA_DIR/automation-runs.db"

readonly RUN_STATUSES="running|completed|partial|failed"

start_run() {
    local params="$1"
    local automation; automation="$(param "$params" "automation")"
    validate_required "automation" "$automation" "start-run"

    local now; now="$(now_local)"
    local today; today="$(today_local)"

    local sql="INSERT INTO runs (date, automation, started_at, status)
        VALUES ($(sql_nullable "$today"), $(sql_nullable "$automation"), $(sql_nullable "$now"), 'running');"

    local select_sql="SELECT * FROM runs WHERE id = last_insert_rowid();"

    local record
    record="$(db_write_and_return "$RUNS_DB" "$sql" "$select_sql")" || exit 1

    local new_id
    new_id="$(echo "$record" | jq -r '.[0].id')"

    write_changelog "automation-runs" "runs" "INSERT" "$new_id" \
        '["date","automation","started_at","status"]' \
        "" \
        "$(echo "$record" | jq -c '.[0]')"

    json_success "start-run" "Run #$new_id started for $automation" "$record"
}

complete_run() {
    local params="$1"
    local id; id="$(param "$params" "id")"
    local steps_completed; steps_completed="$(param "$params" "steps_completed")"
    local steps_skipped; steps_skipped="$(param "$params" "steps_skipped")"
    local notes; notes="$(param "$params" "notes")"

    validate_required "id" "$id" "complete-run"
    validate_integer "id" "$id" "complete-run"
    validate_required "steps_completed" "$steps_completed" "complete-run"

    local old_record
    old_record="$(db_query "$RUNS_DB" "SELECT * FROM runs WHERE id = $id;")"

    if [[ "$(echo "$old_record" | jq 'length')" == "0" ]]; then
        json_error "Run #$id not found" "complete-run"
        exit 1
    fi

    local now; now="$(now_local)"
    local started_at
    started_at="$(echo "$old_record" | jq -r '.[0].started_at')"

    # Calculate duration in seconds (cross-platform via datetime_to_epoch helper)
    local now_epoch started_epoch duration
    now_epoch="$(datetime_to_epoch "$now")"
    started_epoch="$(datetime_to_epoch "$started_at")"
    duration=$(( now_epoch - started_epoch ))

    local sql="UPDATE runs SET status = 'completed', completed_at = $(sql_nullable "$now"), steps_completed = $(sql_nullable "$steps_completed"), steps_skipped = $(sql_nullable "$steps_skipped"), notes = $(sql_nullable "$notes"), duration_seconds = $duration WHERE id = $id;"
    local select_sql="SELECT * FROM runs WHERE id = $id;"

    local record
    record="$(db_write_and_return "$RUNS_DB" "$sql" "$select_sql")" || exit 1

    write_changelog "automation-runs" "runs" "UPDATE" "$id" \
        '["status","completed_at","steps_completed","steps_skipped","notes","duration_seconds"]' \
        "$(echo "$old_record" | jq -c '.[0]')" \
        "$(echo "$record" | jq -c '.[0]')"

    json_success "complete-run" "Run #$id completed" "$record"
}

fail_run() {
    local params="$1"
    local id; id="$(param "$params" "id")"
    local error; error="$(param "$params" "error")"
    local steps_completed; steps_completed="$(param "$params" "steps_completed")"

    validate_required "id" "$id" "fail-run"
    validate_integer "id" "$id" "fail-run"
    validate_required "error" "$error" "fail-run"

    local old_record
    old_record="$(db_query "$RUNS_DB" "SELECT * FROM runs WHERE id = $id;")"

    if [[ "$(echo "$old_record" | jq 'length')" == "0" ]]; then
        json_error "Run #$id not found" "fail-run"
        exit 1
    fi

    local now; now="$(now_local)"

    # partial if some steps completed, failed if none
    local new_status="failed"
    [[ -n "$steps_completed" ]] && new_status="partial"

    local started_at
    started_at="$(echo "$old_record" | jq -r '.[0].started_at')"

    # Calculate duration in seconds (cross-platform via datetime_to_epoch helper)
    local now_epoch started_epoch duration
    now_epoch="$(datetime_to_epoch "$now")"
    started_epoch="$(datetime_to_epoch "$started_at")"
    duration=$(( now_epoch - started_epoch ))

    local sql="UPDATE runs SET status = '$new_status', completed_at = $(sql_nullable "$now"), error_details = $(sql_nullable "$error"), steps_completed = $(sql_nullable "$steps_completed"), duration_seconds = $duration WHERE id = $id;"
    local select_sql="SELECT * FROM runs WHERE id = $id;"

    local record
    record="$(db_write_and_return "$RUNS_DB" "$sql" "$select_sql")" || exit 1

    write_changelog "automation-runs" "runs" "UPDATE" "$id" \
        '["status","completed_at","error_details","steps_completed","duration_seconds"]' \
        "$(echo "$old_record" | jq -c '.[0]')" \
        "$(echo "$record" | jq -c '.[0]')"

    json_success "fail-run" "Run #$id marked as $new_status" "$record"
}

list_runs() {
    local params="$1"
    local automation; automation="$(param "$params" "automation")"
    local start_date; start_date="$(param "$params" "start_date")"
    local end_date; end_date="$(param "$params" "end_date")"
    local status; status="$(param "$params" "status")"
    local limit; limit="$(param "$params" "limit")"

    [[ -z "$limit" ]] && limit=50

    [[ -n "$status" ]] && validate_enum "status" "$status" "$RUN_STATUSES" "list-runs"
    validate_integer "limit" "$limit" "list-runs"

    local where_clauses=""
    [[ -n "$automation" ]] && where_clauses="$where_clauses AND automation = $(sql_nullable "$automation")"
    [[ -n "$start_date" ]] && where_clauses="$where_clauses AND date >= $(sql_nullable "$start_date")"
    [[ -n "$end_date" ]] && where_clauses="$where_clauses AND date <= $(sql_nullable "$end_date")"
    [[ -n "$status" ]] && where_clauses="$where_clauses AND status = $(sql_nullable "$status")"

    if [[ -n "$where_clauses" ]]; then
        where_clauses="WHERE ${where_clauses# AND }"
    fi

    local sql="SELECT * FROM runs $where_clauses ORDER BY date DESC, started_at DESC LIMIT $limit;"
    local count_sql="SELECT COUNT(*) FROM runs $where_clauses;"

    local records
    records="$(db_query "$RUNS_DB" "$sql")"

    local count
    count="$(db_count "$RUNS_DB" "$count_sql")"

    json_success_list "list-runs" "$records" "$count"
}
