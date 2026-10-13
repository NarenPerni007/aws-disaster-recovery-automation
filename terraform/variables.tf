variable "project" {
  description = "Short project name used as a prefix for resource names."
  type        = string
  default     = "app"
}

variable "environment" {
  description = "Environment label, for example prod or staging."
  type        = string
  default     = "prod"
}

variable "primary_region" {
  description = "AWS region that serves traffic under normal conditions."
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "AWS region that takes over during a disaster. Must differ from primary_region."
  type        = string
  default     = "us-west-2"
}

variable "primary_vpc_cidr" {
  description = "CIDR block for the primary VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "dr_vpc_cidr" {
  description = "CIDR block for the DR VPC. Keep it different from the primary so peering and routing stay unambiguous."
  type        = string
  default     = "10.1.0.0/16"
}

variable "db_instance_class" {
  description = "RDS instance class for the primary database and its DR replica."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the primary database."
  type        = string
  default     = "appadmin"
}

variable "db_password" {
  description = "Master password for the primary database. Pass it in via a tfvars file or an environment variable, never commit it."
  type        = string
  sensitive   = true
}

variable "backup_retention_days" {
  description = "How long backups are kept, in days."
  type        = number
  default     = 30
}

variable "rto_minutes" {
  description = "Recovery time objective target in minutes. A target, not a guarantee. Prove it with drills."
  type        = number
  default     = 60
}

variable "rpo_minutes" {
  description = "Recovery point objective target in minutes. A target, not a guarantee. Prove it with drills."
  type        = number
  default     = 15
}

variable "replica_lag_threshold_seconds" {
  description = "RDS replica lag in seconds above which the lag alarm fires."
  type        = number
  default     = 300
}

variable "hosted_zone_name" {
  description = "Route 53 hosted zone name, for example example.com. The zone itself must already exist."
  type        = string
}

variable "app_domain" {
  description = "Fully qualified domain name that fails over between regions, for example app.example.com."
  type        = string
}

variable "app_primary_endpoint" {
  description = "Hostname of the primary application endpoint used by the Route 53 health check."
  type        = string
}

variable "app_primary_ip" {
  description = "IP address that the primary DNS record points to (load balancer or endpoint IP)."
  type        = string
}

variable "app_dr_ip" {
  description = "IP address that the secondary DNS record points to in the DR region."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives DR alerts. Confirm the SNS subscription after the first apply."
  type        = string
}

variable "dr_operator_principals" {
  description = "List of IAM user or role ARNs allowed to assume the DR operator role. Keep this list short and reviewed."
  type        = list(string)
  default     = []
}
