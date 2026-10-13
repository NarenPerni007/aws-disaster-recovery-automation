# DR Audit Checklist

Work through this checklist quarterly. Each item needs evidence, not a
verbal "yes." Evidence means a drill log, a backup report, an alarm history,
or a screenshot with a date.

## RTO and RPO evidence

- [ ] Last full failover drill completed within the RTO target (evidence: drill log)
- [ ] Data loss in the last drill stayed within the RPO target (evidence: drill log)
- [ ] RTO and RPO targets still match business needs (evidence: review note)

## Backup verification

- [ ] Backups ran successfully in the last 30 days with no unreviewed failures (evidence: backup job report)
- [ ] At least one restore test completed in the last month (evidence: drill log)
- [ ] Backup copies exist in the DR region vault (evidence: vault contents)
- [ ] Backup retention matches policy (evidence: plan configuration)

## Replication health

- [ ] RDS replica lag stayed under the alarm threshold for the last 30 days (evidence: alarm history)
- [ ] S3 replication backlog alarm has no unreviewed firings (evidence: alarm history)
- [ ] Cross-region replication is enabled on all critical buckets (evidence: bucket configuration)

## Access review

- [ ] DR operator role assumptions reviewed: only current on-call staff can assume it (evidence: IAM review)
- [ ] No standing broad access to DR resources (evidence: IAM review)
- [ ] DR role policies still least-privilege after any recent changes (evidence: policy diff)

## Documentation

- [ ] Failover and failback runbooks reviewed and current (evidence: review date)
- [ ] Drill log template and schedule still accurate (evidence: review date)
- [ ] Contact list and escalation path current (evidence: review date)
- [ ] Known gaps from the last drill have owners and due dates (evidence: gap tracker)

## Cost check

- [ ] Idle DR resources reviewed: replica sizing and retention still justified (evidence: cost report)
- [ ] No forgotten resources from the last drill or real event still running (evidence: resource list)
