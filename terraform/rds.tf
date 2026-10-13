# Primary database with automated backups, plus a cross-region read replica that
# becomes the failover path. The replica is promoted by the failover playbook,
# not by Terraform: promotion is a one-way, human-approved action and does not
# belong in an apply that can be re-run casually.

resource "aws_db_subnet_group" "primary" {
  name       = "${var.project}-primary"
  subnet_ids = aws_subnet.primary[*].id

  tags = {
    Name = "${var.project}-primary"
  }
}

resource "aws_db_subnet_group" "dr" {
  provider = aws.dr

  name       = "${var.project}-dr"
  subnet_ids = aws_subnet.dr[*].id

  tags = {
    Name = "${var.project}-dr"
  }
}

resource "aws_db_instance" "primary" {
  identifier              = "${var.project}-primary"
  engine                  = "postgres"
  engine_version          = "16.4"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.primary.name
  backup_retention_period = var.backup_retention_days
  storage_encrypted       = true
  deletion_protection     = true
  skip_final_snapshot     = false

  tags = {
    Name = "${var.project}-primary"
  }
}

resource "aws_db_instance" "dr_replica" {
  provider = aws.dr

  identifier           = "${var.project}-dr-replica"
  replicate_source_db  = aws_db_instance.primary.arn
  instance_class       = var.db_instance_class
  db_subnet_group_name = aws_db_subnet_group.dr.name
  storage_encrypted    = true
  skip_final_snapshot  = true

  tags = {
    Name = "${var.project}-dr-replica"
  }
}
