#!/usr/bin/env bash
# accomplishments.sh — Accomplishment CRUD operations
# Sourced by workspace-db.sh dispatcher. Requires db-common.sh.

ACCOMPLISHMENTS_DB="$DATA_DIR/accomplishments.db"

readonly ACCOMPLISHMENT_CATEGORIES="project-delivery|technical-leadership|incident-response|mentoring|process-improvement|collaboration"

log_accomplishment() {
    local params="$1"
    local title; title="$(param "$params" "title")"
    local category; category="$(param "$params" "category")"
    local acc_date; acc_date="$(param "$params" "date")"
    local description; description="$(param "$params" "description")"
    local impact; impact="$(param "$params" "impact")"
    local links; links="$(param "$params" "links")"
    local tags; tags="$(param "$params" "tags")"
    local related_todo_id; related_todo_id="$(param "$params" "related_todo_id")"

    validate_required "title" "$title" "log-accomplishment"
    validate_required "category" "$category" "log-accomplishment"
    validate_enum "category" "$category" "$ACCOMPLISHMENT_CATEGORIES" "log-accomplishment"

    [[ -z "$acc_date" ]] && acc_date="$(today_local)"

    local rtid_sql; rtid_sql="$(sql_nullable "$related_todo_id")"

    local sql="INSERT INTO accomplishments (date, category, title, description, impact, links, tags, related_todo_id)
        VALUES ($(sql_nullable "$acc_date"), $(sql_nullable "$category"), $(sql_nullable "$title"), $(sql_nullable "$description"), $(sql_nullable "$impact"), $(sql_nullable "$links"), $(sql_nullable "$tags"), $rtid_sql);"

    local select_sql="SELECT * FROM accomplishments WHERE id = last_insert_rowid();"

    local record
    record="$(db_write_and_return "$ACCOMPLISHMENTS_DB" "$sql" "$select_sql")" || exit 1

    local new_id
    new_id="$(echo "$record" | jq -r '.[0].id')"

    write_changelog "accomplishments" "accomplishments" "INSERT" "$new_id" \
        '["date","category","title","description","impact","links","tags"]' \
        "" \
        "$(echo "$record" | jq -c '.[0]')"

    json_success "log-accomplishment" "Accomplishment #$new_id logged" "$record"
}

list_accomplishments() {
    local params="$1"
    local start_date; start_date="$(param "$params" "start_date")"
    local end_date; end_date="$(param "$params" "end_date")"
    local category; category="$(param "$params" "category")"
    local tags; tags="$(param "$params" "tags")"
    local limit; limit="$(param "$params" "limit")"

    [[ -z "$limit" ]] && limit=100

    [[ -n "$category" ]] && validate_enum "category" "$category" "$ACCOMPLISHMENT_CATEGORIES" "list-accomplishments"
    validate_integer "limit" "$limit" "list-accomplishments"

    local where_clauses=""
    [[ -n "$start_date" ]] && where_clauses="$where_clauses AND date >= $(sql_nullable "$start_date")"
    [[ -n "$end_date" ]] && where_clauses="$where_clauses AND date <= $(sql_nullable "$end_date")"
    [[ -n "$category" ]] && where_clauses="$where_clauses AND category = $(sql_nullable "$category")"
    if [[ -n "$tags" ]]; then
        local escaped_tags
        escaped_tags="$(sql_escape_like "$tags")"
        where_clauses="$where_clauses AND tags LIKE '%$escaped_tags%' ESCAPE '\\'"
    fi

    if [[ -n "$where_clauses" ]]; then
        where_clauses="WHERE ${where_clauses# AND }"
    fi

    local sql="SELECT * FROM accomplishments $where_clauses ORDER BY date DESC LIMIT $limit;"
    local count_sql="SELECT COUNT(*) FROM accomplishments $where_clauses;"

    local records
    records="$(db_query "$ACCOMPLISHMENTS_DB" "$sql")"

    local count
    count="$(db_count "$ACCOMPLISHMENTS_DB" "$count_sql")"

    json_success_list "list-accomplishments" "$records" "$count"
}

export_accomplishments() {
    local params="$1"
    local start_date; start_date="$(param "$params" "start_date")"
    local end_date; end_date="$(param "$params" "end_date")"

    validate_required "start_date" "$start_date" "export-accomplishments"
    validate_required "end_date" "$end_date" "export-accomplishments"

    local sql="SELECT date, category, title, impact, description FROM accomplishments
        WHERE date BETWEEN $(sql_nullable "$start_date") AND $(sql_nullable "$end_date")
        ORDER BY category, date ASC;"

    local records
    records="$(db_query "$ACCOMPLISHMENTS_DB" "$sql")"

    local count
    count="$(echo "$records" | jq 'length')"

    json_success_list "export-accomplishments" "$records" "$count"
}
