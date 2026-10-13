# Least-privilege roles for DR work. Three roles, each with one job:
# - dr-operator: assumed by on-call staff during a failover. Scoped to the DR
#   actions in this repo, nothing else.
# - s3-replication: used by S3 to copy objects to the DR bucket.
# - backup: used by AWS Backup to run backup and copy jobs.

data "aws_iam_policy_document" "dr_operator_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.dr_operator_principals
    }
  }
}

resource "aws_iam_role" "dr_operator" {
  name               = "${var.project}-dr-operator"
  assume_role_policy = data.aws_iam_policy_document.dr_operator_assume.json
  description        = "Assumed by on-call staff during DR failover and failback only."
}

data "aws_iam_policy_document" "dr_operator" {
  statement {
    sid    = "BackupReadAndRestore"
    effect = "Allow"

    actions = [
      "backup:DescribeBackupJob",
      "backup:ListBackupJobs",
      "backup:DescribeRecoveryPoint",
      "backup:ListRecoveryPointsByResource",
      "backup:StartRestoreJob",
    ]

    resources = [
      aws_backup_vault.primary.arn,
      aws_backup_vault.dr.arn,
    ]
  }

  statement {
    sid    = "RdsFailover"
    effect = "Allow"

    actions = [
      "rds:DescribeDBInstances",
      "rds:PromoteReadReplica",
      "rds:CreateDBInstanceReadReplica",
    ]

    resources = [
      aws_db_instance.dr_replica.arn,
      aws_db_instance.primary.arn,
    ]
  }

  statement {
    sid    = "Route53Failover"
    effect = "Allow"

    actions = [
      "route53:GetHealthCheck",
      "route53:ChangeResourceRecordSets",
    ]

    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.app.zone_id}",
    ]
  }

  statement {
    sid    = "AlarmsReadOnly"
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarms",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "dr_operator" {
  name   = "${var.project}-dr-operator"
  policy = data.aws_iam_policy_document.dr_operator.json
}

resource "aws_iam_role_policy_attachment" "dr_operator" {
  role       = aws_iam_role.dr_operator.name
  policy_arn = aws_iam_policy.dr_operator.arn
}

data "aws_iam_policy_document" "s3_replication_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "s3_replication" {
  name               = "${var.project}-s3-replication"
  assume_role_policy = data.aws_iam_policy_document.s3_replication_assume.json
  description        = "Allows S3 to replicate objects from the primary bucket to the DR bucket."
}

data "aws_iam_policy_document" "s3_replication" {
  statement {
    sid    = "ReadSource"
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
    ]

    resources = [
      aws_s3_bucket.primary.arn,
      "${aws_s3_bucket.primary.arn}/*",
    ]
  }

  statement {
    sid    = "WriteDestination"
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging",
    ]

    resources = [
      "${aws_s3_bucket.dr.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_replication" {
  name   = "${var.project}-s3-replication"
  policy = data.aws_iam_policy_document.s3_replication.json
}

resource "aws_iam_role_policy_attachment" "s3_replication" {
  role       = aws_iam_role.s3_replication.name
  policy_arn = aws_iam_policy.s3_replication.arn
}

data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "${var.project}-backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
  description        = "Service role used by AWS Backup to run backup and copy jobs."
}

resource "aws_iam_role_policy_attachment" "backup_service" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRole"
}
