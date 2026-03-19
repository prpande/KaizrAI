# Customization Guide

How to extend and modify the workspace to fit your workflow.

> Content will be expanded after personal use validates the design.

## Adding a New Prompt

Create a file in `prompts/` following this template:

```markdown
# [Title]
## Goal
[One sentence]
## Context
- Database: [which databases, via workspace-db.sh actions]
- Memory: [which memory files to read — omit if not needed]
## Instructions
1. [If the prompt reads memory files or data paths: Read `.env` to get `WORKSPACE_DATA_DIR`]
2. [Steps]
## Output
[Format]
## Changelog
- [Date]: Initial version
```
