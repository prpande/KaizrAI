#!/usr/bin/env bash
# todos.sh — Todo CRUD operations
# Sourced by workspace-db.sh dispatcher. Requires db-common.sh.

TODOS_DB="$DATA_DIR/todos.db"

readonly TODO_STATUSES="open|in-progress|done|cancelled"
readonly TODO_PRIORITIES="critical|high|medium|low"
readonly TODO_SOURCES="manual|notion|jira|github|slack|standup|automation"
readonly TODO_CATEGORIES="technical|process|project|admin|personal"

add_todo() {
    local params="$1"
    local title; title="$(param "$params" "title")"
    local priority; priority="$(param "$params" "priority")"
    local category; category="$(param "$params" "category")"
    local due_date; due_date="$(param "$params" "due_date")"
    local source; source="$(param "$params" "source")"
    local source_ref; source_ref="$(param "$params" "source_ref")"
    local notes; notes="$(param "$params" "notes")"
    local parent_id; parent_id="$(param "$params" "parent_id")"

    validate_required "title" "$title" "add-todo"

    # Defaults
    [[ -z "$priority" ]] && priority="medium"
    [[ -z "$source" ]] && source="manual"

    validate_enum "priority" "$priority" "$TODO_PRIORITIES" "add-todo"
    validate_enum "source" "$source" "$TODO_SOURCES" "add-todo"
    [[ -n "$category" ]] && validate_enum "category" "$category" "$TODO_CATEGORIES" "add-todo"

    local now; now="$(now_local)"
    local today; today="$(today_local)"
    local parent_sql; parent_sql="$(if [[ -n "$parent_id" ]]; then echo "$parent_id"; else echo "NULL"; fi)"

    local sql="INSERT INTO todos (title, status, priority, owner, source, source_ref, category, created_date, due_date, last_touched, notes, parent_id)
        VALUES ($(sql_nullable "$title"), 'open', $(sql_nullable "$priority"), NULL, $(sql_nullable "$source"), $(sql_nullable "$source_ref"), $(sql_nullable "$category"), '$today', $(sql_nullable "$due_date"), '$now', $(sql_nullable "$notes"), $parent_sql);"

    local select_sql="SELECT * FROM todos WHERE id = last_insert_rowid();"

    local record
    record="$(db_write_and_return "$TODOS_DB" "$sql" "$select_sql")"

    local new_id
    new_id="$(echo "$record" | jq -r '.[0].id')"

    write_changelog "todos" "todos" "INSERT" "$new_id" \
        '["title","status","priority","source","category","due_date","notes"]' \
        "" \
        "$(echo "$record" | jq -c '.[0]')"

    json_success "add-todo" "Todo #$new_id created" "$record"
}

update_todo() {
    local params="$1"
    local id; id="$(param "$params" "id")"
    validate_required "id" "$id" "update-todo"

    # Fetch current record for changelog
    local old_record
    old_record="$(db_query "$TODOS_DB" "SELECT * FROM todos WHERE id = $id;")"

    if [[ "$(echo "$old_record" | jq 'length')" == "0" ]]; then
        json_error "Todo #$id not found" "update-todo"
        exit 1
    fi

    local status; status="$(param "$params" "status")"
    local priority; priority="$(param "$params" "priority")"
    local category; category="$(param "$params" "category")"
    local due_date; due_date="$(param "$params" "due_date")"
    local notes; notes="$(param "$params" "notes")"

    [[ -n "$status" ]] && validate_enum "status" "$status" "$TODO_STATUSES" "update-todo"
    [[ -n "$priority" ]] && validate_enum "priority" "$priority" "$TODO_PRIORITIES" "update-todo"
    [[ -n "$category" ]] && validate_enum "category" "$category" "$TODO_CATEGORIES" "update-todo"

    local now; now="$(now_local)"
    local set_clauses="last_touched = '$now'"
    local changed_fields="[\"last_touched\""

    [[ -n "$status" ]] && set_clauses="$set_clauses, status = $(sql_nullable "$status")" && changed_fields="$changed_fields,\"status\""
    [[ -n "$priority" ]] && set_clauses="$set_clauses, priority = $(sql_nullable "$priority")" && changed_fields="$changed_fields,\"priority\""
    [[ -n "$category" ]] && set_clauses="$set_clauses, category = $(sql_nullable "$category")" && changed_fields="$changed_fields,\"category\""
    [[ -n "$due_date" ]] && set_clauses="$set_clauses, due_date = $(sql_nullable "$due_date")" && changed_fields="$changed_fields,\"due_date\""
    [[ -n "$notes" ]] && set_clauses="$set_clauses, notes = $(sql_nullable "$notes")" && changed_fields="$changed_fields,\"notes\""

    changed_fields="$changed_fields]"

    local sql="UPDATE todos SET $set_clauses WHERE id = $id;"
    local select_sql="SELECT * FROM todos WHERE id = $id;"

    local record
    record="$(db_write_and_return "$TODOS_DB" "$sql" "$select_sql")"

    write_changelog "todos" "todos" "UPDATE" "$id" \
        "$changed_fields" \
        "$(echo "$old_record" | jq -c '.[0]')" \
        "$(echo "$record" | jq -c '.[0]')"

    json_success "update-todo" "Todo #$id updated" "$record"
}

complete_todo() {
    local params="$1"
    local id; id="$(param "$params" "id")"
    local notes; notes="$(param "$params" "notes")"
    validate_required "id" "$id" "complete-todo"

    local old_record
    old_record="$(db_query "$TODOS_DB" "SELECT * FROM todos WHERE id = $id;")"

    if [[ "$(echo "$old_record" | jq 'length')" == "0" ]]; then
        json_error "Todo #$id not found" "complete-todo"
        exit 1
    fi

    local now; now="$(now_local)"
    local today; today="$(today_local)"

    local notes_sql=""
    if [[ -n "$notes" ]]; then
        local old_notes
        old_notes="$(echo "$old_record" | jq -r '.[0].notes // ""')"
        if [[ -n "$old_notes" ]]; then
            local combined
            combined="$(printf '%s\n%s' "$old_notes" "$notes")"
            notes_sql=", notes = $(sql_nullable "$combined")"
        else
            notes_sql=", notes = $(sql_nullable "$notes")"
        fi
    fi

    local sql="UPDATE todos SET status = 'done', completed_date = '$today', last_touched = '$now'$notes_sql WHERE id = $id;"
    local select_sql="SELECT * FROM todos WHERE id = $id;"

    local record
    record="$(db_write_and_return "$TODOS_DB" "$sql" "$select_sql")"

    write_changelog "todos" "todos" "UPDATE" "$id" \
        '["status","completed_date","last_touched","notes"]' \
        "$(echo "$old_record" | jq -c '.[0]')" \
        "$(echo "$record" | jq -c '.[0]')"

    json_success "complete-todo" "Todo #$id completed" "$record"
}

cancel_todo() {
    local params="$1"
    local id; id="$(param "$params" "id")"
    local reason; reason="$(param "$params" "reason")"
    validate_required "id" "$id" "cancel-todo"

    local old_record
    old_record="$(db_query "$TODOS_DB" "SELECT * FROM todos WHERE id = $id;")"

    if [[ "$(echo "$old_record" | jq 'length')" == "0" ]]; then
        json_error "Todo #$id not found" "cancel-todo"
        exit 1
    fi

    local now; now="$(now_local)"
    local today; today="$(today_local)"

    local notes_sql=""
    if [[ -n "$reason" ]]; then
        local old_notes
        old_notes="$(echo "$old_record" | jq -r '.[0].notes // ""')"
        local new_notes="Cancelled: $reason"
        if [[ -n "$old_notes" ]]; then
            new_notes="$(printf '%s\n%s' "$old_notes" "$new_notes")"
        fi
        notes_sql=", notes = $(sql_nullable "$new_notes")"
    fi

    local sql="UPDATE todos SET status = 'cancelled', cancelled_date = '$today', last_touched = '$now'$notes_sql WHERE id = $id;"
    local select_sql="SELECT * FROM todos WHERE id = $id;"

    local record
    record="$(db_write_and_return "$TODOS_DB" "$sql" "$select_sql")"

    write_changelog "todos" "todos" "UPDATE" "$id" \
        '["status","cancelled_date","last_touched","notes"]' \
        "$(echo "$old_record" | jq -c '.[0]')" \
        "$(echo "$record" | jq -c '.[0]')"

    json_success "cancel-todo" "Todo #$id cancelled" "$record"
}

list_todos() {
    local params="$1"
    local status; status="$(param "$params" "status")"
    local priority; priority="$(param "$params" "priority")"
    local category; category="$(param "$params" "category")"
    local stale_days; stale_days="$(param "$params" "stale_days")"
    local search; search="$(param "$params" "search")"
    local limit; limit="$(param "$params" "limit")"

    [[ -z "$limit" ]] && limit=50

    # Validate inputs that go into SQL to prevent injection
    [[ -n "$status" ]] && validate_enum "status" "$status" "$TODO_STATUSES" "list-todos"
    [[ -n "$priority" ]] && validate_enum "priority" "$priority" "$TODO_PRIORITIES" "list-todos"
    [[ -n "$category" ]] && validate_enum "category" "$category" "$TODO_CATEGORIES" "list-todos"
    [[ -n "$stale_days" ]] && validate_integer "stale_days" "$stale_days" "list-todos"
    validate_integer "limit" "$limit" "list-todos"

    local where_clauses=""
    [[ -n "$status" ]] && where_clauses="$where_clauses AND status = '$status'"
    [[ -n "$priority" ]] && where_clauses="$where_clauses AND priority = '$priority'"
    [[ -n "$category" ]] && where_clauses="$where_clauses AND category = '$category'"
    [[ -n "$stale_days" ]] && where_clauses="$where_clauses AND last_touched < datetime('now', 'localtime', '-$stale_days days')"
    if [[ -n "$search" ]]; then
        local escaped_search
        escaped_search="$(sql_escape_like "$search")"
        where_clauses="$where_clauses AND (title LIKE '%$escaped_search%' ESCAPE '\\' OR notes LIKE '%$escaped_search%' ESCAPE '\\')"
    fi

    # Remove leading " AND "
    if [[ -n "$where_clauses" ]]; then
        where_clauses="WHERE ${where_clauses# AND }"
    fi

    local sql="SELECT * FROM todos $where_clauses
        ORDER BY
            CASE priority WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 END,
            last_touched ASC
        LIMIT $limit;"

    local count_sql="SELECT COUNT(*) FROM todos $where_clauses;"

    local records
    records="$(db_query "$TODOS_DB" "$sql")"

    local count
    count="$(db_count "$TODOS_DB" "$count_sql")"

    json_success_list "list-todos" "$records" "$count"
}
