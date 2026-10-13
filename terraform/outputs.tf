output "primary_vpc_id" {
  description = "ID of the primary VPC."
  value       = aws_vpc.primary.id
}

output "dr_vpc_id" {
  description = "ID of the DR VPC."
  value       = aws_vpc.dr.id
}

output "primary_bucket" {
  description = "Name of the primary data bucket."
  value       = aws_s3_bucket.primary.id
}

output "dr_bucket" {
  description = "Name of the DR data bucket."
  value       = aws_s3_bucket.dr.id
}

output "primary_db_endpoint" {
  description = "Endpoint of the primary database."
  value       = aws_db_instance.primary.endpoint
}

output "dr_replica_endpoint" {
  description = "Endpoint of the DR read replica. After promotion this becomes the primary endpoint."
  value       = aws_db_instance.dr_replica.endpoint
}

output "primary_backup_vault" {
  description = "Name of the primary backup vault."
  value       = aws_backup_vault.primary.name
}

output "dr_backup_vault" {
  description = "Name of the DR backup vault."
  value       = aws_backup_vault.dr.name
}

output "health_check_id" {
  description = "ID of the Route 53 health check on the primary endpoint."
  value       = aws_route53_health_check.primary.id
}

output "dr_alerts_topic_arn" {
  description = "ARN of the SNS topic that receives DR alerts."
  value       = aws_sns_topic.dr_alerts.arn
}

output "dr_operator_role_arn" {
  description = "ARN of the least-privilege role for DR operations."
  value       = aws_iam_role.dr_operator.arn
}
