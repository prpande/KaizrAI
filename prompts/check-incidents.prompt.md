# Check Incidents

## Goal
Check monitoring tools for recent incidents affecting your services.

## Context
- MCP: Monitoring tool (configure one of: New Relic, Datadog, PagerDuty)
- Memory: `{DATA_DIR}/memory/stable/me.md` for services owned

## Instructions
> **This is a stub.** Customize for your monitoring setup:
>
> 1. Identify which MCP monitoring tool you use
> 2. Add your service names, account IDs, and query patterns
> 3. Define what "recent" means for your context (last 12 hours? 24 hours?)
> 4. Define severity thresholds worth surfacing
>
> Example for New Relic:
> - Query NRQL for open incidents on [your services]
> - Flag any P1/P2 incidents in the last 24 hours
> - Show recent deployments that correlate with incident timing

If no monitoring MCP is configured, output: "Monitoring MCP not configured. See docs/CUSTOMIZATION.md to add New Relic, Datadog, or PagerDuty."

## Output
**🔴 Active Incidents** (currently open — skip if none)
**🟡 Recent Incidents** (resolved in last 24h — skip if none)
**🟢 All Clear** (if nothing to report)

## Changelog
- 2026-03-19: Initial stub
