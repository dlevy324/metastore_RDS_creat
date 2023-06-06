output "rds_metastore_address"{
  value = aws_db_instance.this.endpoint
}

output "rds_metastore_password" {
  value = random_password.password.result
  sensitive = true
}