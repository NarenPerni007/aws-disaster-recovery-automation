# Failover Runbook

Read this before you need it. A runbook you are reading for the first time
during an outage is not a runbook, it is a puzzle.

## When to use this

Use this runbook when the primary region is down or degraded and recovery in
the primary region is not expected within the RTO. Failover is a business
decision, not an automatic step. The on-call engineer recommends, the
incident commander approves.

## Before you start

- Confirm the outage is region-scoped, not an application bug. A bug will
  follow you to the DR region.
- Confirm the DR replica is healthy and replication lag is within the RPO.
  Check the replica lag alarm and the S3 replication backlog alarm.
- Have the incident channel open and a note-taker assigned.

## Steps

1. Announce the failover decision in the incident channel with the reason
   and the expected RTO.
2. Run the failover playbook:
   `ansible-playbook playbooks/failover.yml -e ...` (see the playbook header
   for the required variables).
3. Type YES when prompted. The playbook promotes the DR replica, waits for
   it to become available, flips DNS, and checks application health.
4. Verify the application by hand: log in, run the smoke test, and confirm
   a write path works. The playbook health check is not enough on its own.
5. Confirm DNS has propagated for the users that matter. DNS TTL is 60
   seconds, but cached records and client-side DNS can lag behind that.
6. Notify stakeholders that traffic is now served from the DR region and
   note the data-loss window, if any, based on replication lag at failover
   time.
7. Open the post-incident record and start the failback plan. Do not treat
   running in DR as the new normal.

## If something goes wrong

- If promotion fails, check the replica state in the AWS console and the
  playbook output. Do not re-run promotion blindly; check whether it
  partially succeeded.
- If DNS flips but the application does not answer, the problem is in the
  DR application tier, not the database. Work the application runbook.
- If replication lag was above the RPO at failover time, say so openly in
  the incident record. Hiding data loss makes the next decision worse.

## After failover

- Keep the DR region running until failback is planned and approved.
- Re-establish monitoring baselines: alarms tuned for primary will fire
  differently in DR.
- Schedule the failback. See `runbook-failback.md`.
