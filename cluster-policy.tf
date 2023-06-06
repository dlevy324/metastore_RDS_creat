/**
 * Creates a cluster policy to set ENV variables necessary for connection to the external HMS
 */

locals {
  default_policy = {
    "spark_env_vars.HMS_CONNECTION": {
        "value": "{{secrets/${databricks_secret_scope.this.name}/${databricks_secret.hms_conn.key}}}",
        "type" : "fixed",
        "hidden" : false
    },
    "spark_env_vars.HMS_PWORD": {
        "value": "{{secrets/${databricks_secret_scope.this.name}/${databricks_secret.hms_pword.key}}}",
        "type" : "fixed",
        "hidden" : false
    },
    "spark_env_vars.HMS_USER": {
        "value": "{{secrets/${databricks_secret_scope.this.name}/${databricks_secret.hms_user.key}}}",
        "type" : "fixed",
        "hidden" : false
    },
    "cluster_type": {
        "type": "allowlist",
        "values": ["all-purpose","jobs"]
        "hidden" : true
    } 
  }
}

resource "databricks_cluster_policy" "this" {
  name       = "metastore cluster policy"
  definition = jsonencode(local.default_policy)
}

resource "databricks_permissions" "can_use_cluster_policyinstance_profile" {
  cluster_policy_id = databricks_cluster_policy.this.id
  access_control {
    group_name       = "users"
    permission_level = "CAN_USE"
  }
}