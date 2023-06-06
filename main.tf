/**
 * External metastore pattern with AWS RDS
 * 
 * This reference architecture can be described as the following diagram:
 * 
 */
 terraform {
  required_providers {
    databricks = {
      source = "databrickslabs/databricks"
    }
  }
}

provider "aws" {
  region = var.region
  profile = "aws-cust-test1_databricks-power-user"
}

provider "databricks" {
  host = var.databricks_workspace_url
  username = var.databricks_workspace_username
  password = var.databricks_workspace_password
}