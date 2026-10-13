# Alerting. Two classes of signal matter here:
# 1. Backup job failures, delivered through EventBridge, because a backup that
#    silently stops running is worse than no backup plan at all.
# 2. Replication health, through CloudWatch alarms on replica lag and on the
#    S3 replication backlog. Lag alarms tell you the DR copy is falling behind
#    before you need it, which is the only time that warning is useful.

resource "aws_sns_topic" "dr_alerts" {
  name = "${var.project}-dr-alerts"

  tags = {
    Name = "${var.project}-dr-alerts"
  }
}

resource "aws_sns_topic_subscription" "dr_alerts_email" {
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

data "aws_iam_policy_document" "dr_alerts_topic_policy" {
  statement {
    sid = "AllowEventBridgePublish"

    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.dr_alerts.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.backup_failed.arn]
    }
  }
}

resource "aws_sns_topic_policy" "dr_alerts" {
  arn    = aws_sns_topic.dr_alerts.arn
  policy = data.aws_iam_policy_document.dr_alerts_topic_policy.json
}

resource "aws_cloudwatch_event_rule" "backup_failed" {
  name = "${var.project}-backup-failed"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change"]
    detail = {
      state = ["FAILED", "ABORTED", "EXPIRED"]
    }
  })

  tags = {
    Name = "${var.project}-backup-failed"
  }
}

resource "aws_cloudwatch_event_target" "backup_failed_alert" {
  rule = aws_cloudwatch_event_rule.backup_failed.name
  arn  = aws_sns_topic.dr_alerts.arn
}

resource "aws_cloudwatch_metric_alarm" "replica_lag" {
  alarm_name          = "${var.project}-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.replica_lag_threshold_seconds
  alarm_description   = "DR replica is falling behind primary. Check replication and network before it matters."
  alarm_actions       = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.dr_replica.identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_replication_backlog" {
  alarm_name          = "${var.project}-s3-replication-backlog"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "BytesPendingReplication"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Average"
  threshold           = 1073741824
  alarm_description   = "More than 1 GB of S3 data is waiting to replicate to the DR region."
  alarm_actions       = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    BucketName  = aws_s3_bucket.primary.id
    StorageType = "AllStorageTypes"
    FilterId    = "EntireBucket"
  }
}
