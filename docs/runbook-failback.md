# Failback Runbook

Failback returns traffic to the primary region after an outage. It is
planned work, not an emergency action. Never fail back in a hurry.

## When to use this

Use this runbook when the primary region is confirmed healthy, data written
in DR has been reconciled, and the business has agreed on a failback window.

## Before you start

- Confirm the primary region is healthy: endpoints answer, backups are
  running, and no open incident remains.
- Reconcile data. Anything written in DR that never replicated back must be
  accounted for. If you cannot account for it, stop and escalate.
- Pick a low-traffic window and announce it. Failback briefly touches the
  same DNS and database paths as failover.
- Have the incident channel open and a note-taker assigned.

## Steps

1. Announce the failback window and the plan in the incident channel.
2. Run the failback playbook:
   `ansible-playbook playbooks/failback.yml -e ...` (see the playbook
   header for the required variables).
3. Type YES when prompted. The playbook builds a new replica from the
   promoted database, flips DNS back, and checks application health.
4. Verify the application by hand: log in, run the smoke test, and confirm
   a write path works.
5. Confirm DNS has propagated. DNS TTL is 60 seconds, but cached records
   can lag.
6. Re-establish the original replication setup: the new replica becomes
   the DR replica again, S3 replication resumes, and backup copies to the
   DR vault resume. Verify each one instead of assuming it.
7. Decommission the leftover DR resources from the outage window per your
   change process. Leaving them running costs money and confuses the next
   incident.
8. Notify stakeholders that traffic is back in the primary region and
   close the incident record.

## If something goes wrong

- If the new replica fails to build, stop. Traffic is still in DR and
  serving users. A failed failback is not an outage, it is a delay.
- If DNS flips back but the application does not answer, work the
  application runbook and be ready to flip DNS back to DR.
- If data reconciliation uncovers gaps, stop and escalate. Do not fail
  back over a data gap to meet a schedule.

## After failback

- Run the backup verification playbook to confirm backups are healthy
  again in the primary region.
- Schedule a drill. The next outage should not be the first time the
  runbook is used after a real event.
