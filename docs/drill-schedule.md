# DR Drill Schedule

A DR plan that has never been drilled is a document, not a capability.
Drills exist to find the gaps while nothing is on fire.

## Cadence

| Drill | Frequency | Scope |
| --- | --- | --- |
| Backup restore test | Monthly | Restore one backup to an isolated sandbox and verify the data by hand |
| Failover walkthrough | Quarterly | Tabletop: walk the failover runbook end to end, no changes made |
| Full failover drill | Twice a year | Real failover to DR in a maintenance window, then failback |
| Audit review | Quarterly | Work through the audit checklist and close gaps |

## Rules

- Every drill gets a log entry using `drill-log-template.md`. A drill without
  a log entry did not happen.
- Drills happen in maintenance windows with stakeholders informed. A drill
  that surprises the business is an incident, not a drill.
- The person who wrote the runbook should not be the only person who has
  run it. Rotate drill operators.
- Any gap found in a drill becomes a tracked action item with an owner and
  a date. Gaps that are found and forgotten are worse than gaps never found.

## What success looks like

Success is not "the drill passed." Success is: failover completed within
the RTO target, data loss stayed within the RPO target, the runbook was
accurate, and every gap found has an owner and a date.
