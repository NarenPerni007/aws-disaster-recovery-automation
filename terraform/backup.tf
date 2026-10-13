# AWS Backup covers the primary database and the primary data bucket. Every
# backup is copied to a vault in the DR region, so a backup that only exists
# in the region you just lost is not a backup at all.

resource "aws_backup_vault" "primary" {
  name = "${var.project}-primary-vault"

  tags = {
    Name = "${var.project}-primary-vault"
  }
}

resource "aws_backup_vault" "dr" {
  provider = aws.dr
  name     = "${var.project}-dr-vault"

  tags = {
    Name = "${var.project}-dr-vault"
  }
}

resource "aws_backup_plan" "daily" {
  name = "${var.project}-daily"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 2 * * ? *)"

    lifecycle {
      delete_after = var.backup_retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn

      lifecycle {
        delete_after = var.backup_retention_days
      }
    }
  }

  tags = {
    Name = "${var.project}-daily"
  }
}

resource "aws_backup_selection" "protected" {
  name         = "${var.project}-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.daily.id

  resources = [
    aws_db_instance.primary.arn,
    aws_s3_bucket.primary.arn,
  ]
}
