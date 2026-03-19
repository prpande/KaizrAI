#!/usr/bin/env bash
# decisions.sh — Decision CRUD operations
# Sourced by workspace-db.sh dispatcher. Requires db-common.sh.

DECISIONS_DB="$DATA_DIR/decisions.db"

log_decision() {
    local params="$1"
    local context; context="$(param "$params" "context")"
    local decision; decision="$(param "$params" "decision")"
    local rationale; rationale="$(param "$params" "rationale")"
    local dec_date; dec_date="$(param "$params" "date")"
    local alternatives; alternatives="$(param "$params" "alternatives")"
    local stakeholders; stakeholders="$(param "$params" "stakeholders")"
    local tags; tags="$(param "$params" "tags")"
    local related_todo_id; related_todo_id="$(param "$params" "related_todo_id")"

    validate_required "context" "$context" "log-decision"
    validate_required "decision" "$decision" "log-decision"
    validate_required "rationale" "$rationale" "log-decision"

    [[ -z "$dec_date" ]] && dec_date="$(today_local)"

    local rtid_sql; rtid_sql="$(sql_nullable "$related_todo_id")"

    local sql="INSERT INTO decisions (date, context, decision, rationale, alternatives, stakeholders, tags, related_todo_id)
        VALUES ('$dec_date', $(sql_nullable "$context"), $(sql_nullable "$decision"), $(sql_nullable "$rationale"), $(sql_nullable "$alternatives"), $(sql_nullable "$stakeholders"), $(sql_nullable "$tags"), $rtid_sql);"

    local select_sql="SELECT * FROM decisions WHERE id = last_insert_rowid();"

    local record
    record="$(db_write_and_return "$DECISIONS_DB" "$sql" "$select_sql")" || exit 1

    local new_id
    new_id="$(echo "$record" | jq -r '.[0].id')"

    write_changelog "decisions" "decisions" "INSERT" "$new_id" \
        '["date","context","decision","rationale","alternatives","stakeholders","tags"]' \
        "" \
        "$(echo "$record" | jq -c '.[0]')"

    json_success "log-decision" "Decision #$new_id logged" "$record"
}

list_decisions() {
    local params="$1"
    local start_date; start_date="$(param "$params" "start_date")"
    local end_date; end_date="$(param "$params" "end_date")"
    local search; search="$(param "$params" "search")"
    local limit; limit="$(param "$params" "limit")"

    [[ -z "$limit" ]] && limit=50

    validate_integer "limit" "$limit" "list-decisions"

    local where_clauses=""
    [[ -n "$start_date" ]] && where_clauses="$where_clauses AND date >= '$start_date'"
    [[ -n "$end_date" ]] && where_clauses="$where_clauses AND date <= '$end_date'"
    if [[ -n "$search" ]]; then
        local escaped_search
        escaped_search="$(sql_escape_like "$search")"
        where_clauses="$where_clauses AND (context LIKE '%$escaped_search%' ESCAPE '\\' OR decision LIKE '%$escaped_search%' ESCAPE '\\' OR rationale LIKE '%$escaped_search%' ESCAPE '\\')"
    fi

    if [[ -n "$where_clauses" ]]; then
        where_clauses="WHERE ${where_clauses# AND }"
    fi

    local sql="SELECT * FROM decisions $where_clauses ORDER BY date DESC LIMIT $limit;"
    local count_sql="SELECT COUNT(*) FROM decisions $where_clauses;"

    local records
    records="$(db_query "$DECISIONS_DB" "$sql")"

    local count
    count="$(db_count "$DECISIONS_DB" "$count_sql")"

    json_success_list "list-decisions" "$records" "$count"
}
