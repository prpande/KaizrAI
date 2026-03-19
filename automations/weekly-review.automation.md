# Weekly Review

## Goal
End-of-week retrospective — what got done, what's trending, what needs attention next week.

## Steps

### Step 1: Record Run
- Run `bash scripts/workspace-db.sh --action start-run --params '{"automation":"weekly-review"}'`

### Step 2: Week in Numbers
- Run `bash scripts/workspace-db.sh --action stats`
- Compare against last week's run (query automation-runs for last weekly-review)
- Calculate:
  - Todos added this week vs completed this week (throughput ratio)
  - Accomplishments logged this week
  - Decisions recorded this week
  - Average todo age trend (getting better or worse?)

### Step 3: Accomplishments Summary
- Run `bash scripts/workspace-db.sh --action list-accomplishments --params '{"start_date":"<7 days ago>","end_date":"<today>"}'`
- Group by category
- Highlight top impact items

### Step 4: Stale Item Audit
- Query todos where last_touched > 14 days
- For each: recommend cancel, defer, or re-prioritize
- Ask user to make a call on each

### Step 5: Open Loop Check
- Query decisions with no recorded outcome older than 30 days
- "These decisions haven't had outcomes recorded. Any updates?"

### Step 6: Next Week Preview
- Show high and critical priority items
- Show items due next week
- Show any scheduled automations or recurring items
- Suggest a focus theme for the week based on what's pending

### Step 7: Update Context
- Refresh `memory/active/weekly-context.md`:
  - Archive this week's daily notes (move to a `### Week of [date]` section)
  - Start fresh active section for next week
- Update `memory/active/current-sprint.md` if sprint boundaries align

### Step 8: Record Completion
- Run `bash scripts/workspace-db.sh --action complete-run --params '{"id":"<id>","steps_completed":"<list>"}'` with full step details

## Error Handling
- Standard pattern — log, skip, continue

## Changelog
- 2026-03-19: Initial version
