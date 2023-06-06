/**
 * Creates a MySQL RDS instance to host the HMS in the customer VPC
 */

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "main"
  subnet_ids = flatten([data.aws_subnets.private.ids])

  tags = var.tags
}

data "aws_security_group" "this" {
  vpc_id = var.vpc_id

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "this" {
  # ...instance configuration...
  allocated_storage = 20
  auto_minor_version_upgrade = true
  db_subnet_group_name = aws_db_subnet_group.this.name
  delete_automated_backups = true
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.medium"
  #TODO: add support for CMK
  #"kms_key_id = "arn:aws:kms:us-east-1:826763667205:key/1be01fe4-3bcc-4fc2-bb5b-ac064234de1c"
  multi_az = false
  identifier = "${var.project_name}-rds-metastore"
  port = 3306
  publicly_accessible = false
  storage_encrypted = true
  storage_type = "gp2"
  tags = var.tags
  db_name = var.hive_database
  username = var.hive_user
  password = random_password.password.result
  vpc_security_group_ids = [
    data.aws_security_group.this.id
  ]
  depends_on = [aws_db_subnet_group.this]
  skip_final_snapshot = true
}
