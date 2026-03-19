# Review Accomplishments

## Goal
Generate a performance-review-ready summary of accomplishments for a given period.

## Context
- Database: `accomplishments.db` via `bash scripts/workspace-db.sh --action list-accomplishments` and `--action export-accomplishments`

## Instructions
1. Ask for date range (default: last 6 months)
2. Run `bash scripts/workspace-db.sh --action list-accomplishments` with the date range
3. Group by category
4. For each category, list accomplishments chronologically with impact statements
5. Add a summary section with:
   - Total accomplishments
   - Count per category
   - Highlights: top 3-5 highest-impact items across categories
6. Run `bash scripts/workspace-db.sh --action export-accomplishments` to get a copyable version

## Output
Full review-ready document in markdown. Should be directly pasteable into a performance review form. Include both the detailed breakdown and the executive summary.

## Changelog
- 2026-03-19: Initial version
