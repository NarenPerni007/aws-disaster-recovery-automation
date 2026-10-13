# AWS Disaster Recovery Automation

Complete disaster recovery automation and setup on AWS: Terraform for the
multi-region infrastructure, Ansible playbooks that wrap the failover,
failback, and backup verification steps, plus the runbooks, audit checklist,
and drill templates that make DR a practiced capability instead of a
document.

The core idea is simple: a backup nobody has restored is a hope, not a
recovery plan. Everything in this repo is built around proving recovery
works, on a schedule, before an outage forces the issue.

## Architecture

```
                        +-----------------------+
                        |   Route 53            |
                        |   Health check +      |
                        |   DNS failover        |
                        +-----------+-----------+
                                    |
              Primary answers       |        Secondary answers
              (health check OK)     |        (health check fails)
                                    v
+-----------------------------+   +-----------------------------+
| PRIMARY REGION              |   | DR REGION                   |
|                             |   |                             |
|  VPC                        |   |  VPC                        |
|  S3 bucket (versioned)      |   |  S3 bucket (versioned)      |
|    |  cross-region          |   |    ^  replication           |
|    |  replication           |   |    |                        |
|    v                        |   |  RDS read replica           |
|  RDS primary                |   |    ^  async replication      |
|    |  async replication     |   |    |                        |
|    |                        |   |  Backup vault (copies)      |
|  Backup vault + daily plan  +---+  CloudWatch alarms          |
|    |  copy to DR vault      |   |  (lag, backlog, failures)   |
+-----------------------------+   +-----------------------------+
```

## RTO and RPO targets

These are targets, not guarantees. A target is only real once a drill has
proven it. See `docs/drill-schedule.md`.

| Objective | Target | What it covers |
| --- | --- | --- |
| RTO | 60 minutes | Time from the failover decision to the application answering from DR |
| RPO | 15 minutes | Maximum data loss window, bounded by replication lag at failover time |

Both targets are configurable in `terraform/variables.tf` (`rto_minutes`,
`rpo_minutes`) and in the alarm thresholds.

## What is in this repo

| Path | Contents |
| --- | --- |
| `terraform/` | VPCs in both regions, S3 with cross-region replication, RDS primary plus cross-region read replica, AWS Backup plan with cross-region copy, Route 53 health checks and DNS failover, CloudWatch alarms, least-privilege IAM roles |
| `ansible/playbooks/` | `failover.yml`, `failback.yml`, `verify-backups.yml` |
| `docs/` | Failover and failback runbooks, drill schedule, drill log template, audit checklist, real-time DR health guide |

## What is automated vs what stays manual

Automation handles the mechanical steps. Humans keep the decisions.

| Automated | Manual |
| --- | --- |
| Infrastructure provisioning (Terraform) | The decision to fail over or fail back |
| Replica promotion, DNS flip, health checks (Ansible) | Stakeholder communication |
| Backup scheduling and cross-region copy | Application-level verification (login, smoke test) |
| Failure and lag alerting | Data reconciliation after an event |
| Backup job listing and restore-test scaffolding | Judging whether restored data is correct |

Failover and failback playbooks both stop and ask for explicit confirmation
before doing anything irreversible. That is deliberate.

## Best practices this repo follows

- **Test restores, not just backups.** The verify-backups playbook includes
  an optional restore test into an isolated sandbox. A backup you have
  never restored is unproven.
- **Keep runbooks short and practiced.** Long runbooks do not get read
  during outages. These runbooks are short, and the drill schedule exists
  so they get used before they are needed.
- **Separate DR state.** Primary and DR Terraform state live in separate
  state files. One state file holding both regions is a single point of
  failure for the setup meant to survive a region outage.
- **Least-privilege DR roles.** The DR operator role covers only the
  actions in this repo. Nobody gets standing broad access to DR resources.
- **Watch the quiet failures.** A backup job that silently stops running is
  worse than no backup plan, because it looks like coverage. The
  EventBridge rule on failed backup jobs exists for exactly this.
- **Cost honesty.** Idle DR resources cost money: the replica, the DR
  bucket, and retained backups. The audit checklist includes a cost review
  so DR does not quietly grow into a second production bill.

## Deployment

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Fill in real values: db_password, hosted zone, domain, IPs, alert email.
terraform init
terraform plan
terraform apply
```

After the first apply, confirm the SNS email subscription, then run the
backup verification playbook to confirm backups are actually running.

## Running a drill

```bash
cd ansible
ansible-playbook playbooks/verify-backups.yml -e backup_vault_name=app-primary-vault
```

For a full failover drill, follow `docs/runbook-failover.md` in a
maintenance window, then fail back with `docs/runbook-failback.md`. Log the
drill with `docs/drill-log-template.md`.

## Future ideas

The following are ideas under consideration for the future, depending on
what real situations demand. None of this is implemented in this repo, and
nothing here should be read as an existing capability.

- **Anomaly detection on backup and replication metrics.** Flag silent DR
  drift, such as backup durations creeping up or replica lag trending
  worse over weeks, before it becomes an outage-day surprise.
- **AI-assisted drafting of post-incident reports.** Draft the timeline
  and action items from drill logs and incident notes for a human to
  review and correct, to cut down the paperwork after a drill or event.
- **Failover decision support.** Before a human approves a failover,
  summarize the blast radius: current replication lag, estimated data
  loss, and which services depend on the affected region, so the approval
  is an informed call.

These are possibilities to consider later. If any of them gets built, it
will be added as its own documented piece with its own tests, not bolted
onto the runbooks as a claim.

## License

MIT. See `LICENSE`.
