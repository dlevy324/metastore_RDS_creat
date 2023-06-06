variable "databricks_workspace_url" {
  #default = ""
  description = "URI: https://<workspace-name>.staging.cloud.databricks.com"
}

variable "vpc_id" {
  #default = ""
  description = "VPC ID the workspaces is deployed in; used to associate subnets with the new RDS instance"
}

variable "databricks_workspace_username" {
  #default = ""
  description = "Username for authentication to the workspace"
}
  
variable "databricks_workspace_password" {
  default = "Password associated with databricks_workspace_username"
}

variable "dbfs_lib_location" {
  default = "/databricks/metastore-init"
  description = "DBFS location to collect uploaded libraries"
}

variable "hive_user" {
  default = "metastore"
  description = "HMS connection user"
}

variable "hive_database" {
  default = "metastore"
  description = "Name of HMS database to create"
}

variable "hive_version" {
  type = string
  default = "2.3.9"
  description = "Version of Hive to use in the metastore; 2.3.9"
}

variable "hive_lib_version" {
  type = string
  default = "3.1.3"
  description = "Version of Hive libraries to use for metastore setup only; should always be 3.1.0+"
}

variable "hadoop_version" {
  type = string
  default = "2.9.2"
  description = "Version of Hive to use"
}

variable "tags" {
  default = {
    Owner = "someone@databricks.com"
    Project = "dev"
  }
}

variable "region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "dev-privatelink"
  description = "workspace name"
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  prefix = "ext-hms-${random_string.naming.result}"
}
