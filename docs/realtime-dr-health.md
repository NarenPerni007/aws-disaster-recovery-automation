# Real-Time DR Health

This page covers what to watch day to day so a disaster is not the first
time you learn DR is broken. DR health is a daily habit, not a quarterly
event.

## Alarms and what they mean

| Alarm | What it means | Who acts |
| --- | --- | --- |
| Backup job failed | A backup job failed, aborted, or expired. The next backup may also fail for the same reason. | On-call engineer, same day |
| RDS replica lag high | The DR replica is more than 5 minutes behind primary. Failover now would lose more data than the RPO allows. | On-call engineer, same day |
| S3 replication backlog high | More than 1 GB of object data is waiting to replicate to DR. The DR copy is stale. | On-call engineer, same day |

## Daily checks (5 minutes)

- Backup jobs: any failures in the last 24 hours? If yes, find the cause
  before the next backup window.
- Replica lag: current lag within normal range? A slow upward trend matters
  more than a single spike.
- S3 replication: backlog near zero? A backlog that never drains means
  replication is broken, not slow.

## Weekly checks (15 minutes)

- Confirm the DR replica is still replicating and has not been left in a
  stopped or modified state after maintenance.
- Review alarm history for flapping or muted alarms.
- Confirm the SNS alert subscription is still confirmed. An unconfirmed
  subscription means alerts go nowhere.

## What is not covered here

- Application-level health in DR. The DR application tier needs its own
  health checks; this repo covers data and DNS.
- Security monitoring. GuardDuty, CloudTrail, and config drift are
  separate concerns with their own alerts.
