# System Health Check

## Goal
Periodic self-audit — verify workspace consistency, fix issues, suggest improvements.

## Steps

### Step 1: Record Run
- Run `bash scripts/workspace-db.sh --action start-run --params '{"automation":"system-health-check"}'`

### Step 2: Database Health
- Run `bash scripts/workspace-db.sh --action health`
- Check each database passes integrity_check
- Verify schema versions match expected
- Check for orphaned records (e.g., todos referencing non-existent parents)

### Step 3: File Consistency
- Verify all files referenced in CLAUDE.md exist
- Verify all schema docs match their corresponding databases
- Verify all prompts referenced in automations exist
- Check for naming convention violations
- Check that `.env` points to a valid, accessible directory

### Step 4: Memory File Freshness
- Check last-modified dates on all memory files
- Flag any stable files not updated in >90 days (may be outdated)
- Flag any active files not updated in >14 days (may be stale)

### Step 5: Prompt Usage Analysis
- Query automation-runs.db for which automations ran this month
- Identify prompts that are never referenced (candidates for removal)
- Identify patterns in ad-hoc requests that could become new prompts

### Step 6: Auto-Fix
Apply fixes for clear issues:
- Update broken file paths in docs
- Fix typos in enum values
- Correct formatting inconsistencies
- Report each fix made

### Step 7: Improvement Suggestions
Categorize findings:
- **🔴 Critical**: Broken references, corrupt databases, inaccessible data dir
- **🟡 Warning**: Stale files, unused prompts, growing todo backlog
- **🟢 Suggestion**: New prompt ideas, workflow optimizations, roadmap items

### Step 8: Update ROADMAP.md
- Add any new improvement ideas to the Backlog section
- Move completed items to Completed section

### Step 9: Record Completion
- Run `bash scripts/workspace-db.sh --action complete-run --params '{"id":"<id>","steps_completed":"<list>"}'`

## Error Handling
- If databases are inaccessible, report as critical and stop — don't attempt fixes
- For all other issues, categorize and report

## Changelog
- 2026-03-19: Initial version
