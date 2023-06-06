/**
 * Pulls HMS dependencies and initializes HMS schema in RDS via Databricks job
 */

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

resource "databricks_secret_scope" "this" {
  name = "hms-secret-scope"
}

resource "databricks_secret_acl" "user_acl" {
  principal  = "users"
  permission = "READ"
  scope      = databricks_secret_scope.this.name
}

resource "databricks_secret_acl" "admin_acl" {
  principal  = "admins"
  permission = "MANAGE"
  scope      = databricks_secret_scope.this.name
}

resource "databricks_secret" "hms_pword" {
  key          = "hms-db-pword"
  string_value = random_password.password.result
  scope        = databricks_secret_scope.this.name
}

resource "databricks_secret" "hms_user" {
  key          = "hms-db-user"
  string_value = var.hive_user
  scope        = databricks_secret_scope.this.name
}

resource "databricks_secret" "hms_conn" {
  key          = "hms-db-conn"
  string_value = "jdbc:mysql://${aws_db_instance.this.endpoint}/${var.hive_database}?useUnicode=true&characterEncoding=UTF-8&trustServerCertificate=true&useSSL=true"
  scope        = databricks_secret_scope.this.name
}

resource "databricks_cluster" "this" {
  depends_on = [databricks_secret.hms_pword,databricks_secret.hms_user,databricks_secret.hms_conn]
  cluster_name            = "Metastore setup"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = "i3en.large" #fedramp compliant
  autotermination_minutes = 20

  spark_conf = {
    # Single-node
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }

  spark_env_vars = {
    "HIVE_URL"="{{secrets/${databricks_secret_scope.this.name}/${databricks_secret.hms_conn.key}}}",
    "HIVE_USER"="{{secrets/${databricks_secret_scope.this.name}/${databricks_secret.hms_user.key}}}",
    "HIVE_PASSWORD"="{{secrets/${databricks_secret_scope.this.name}/${databricks_secret.hms_pword.key}}}",
    "TARGET_HIVE_VERSION"=var.hive_version,
    "TARGET_HADOOP_VERSION"=var.hadoop_version,
    "TARGET_HIVE_HOME"="/opt/apache-hive-${var.hive_lib_version}-bin",
    "TARGET_HADOOP_HOME"="/opt/hadoop-${var.hadoop_version}",
    "MYSQL_DRIVER"="org.mariadb.jdbc.Driver",
    "DBFS_LIB": "${var.dbfs_lib_location}/lib",
    "JARS_DIRECTORY": "/dbfs${var.dbfs_lib_location}/hive-${var.hive_lib_version}/lib/"
  }
  
  custom_tags = {
    "ResourceClass" = "SingleNode"
  }
}

data "databricks_current_user" "me" {}

resource "databricks_notebook" "metastore_setup" {
  path     = "${data.databricks_current_user.me.home}/metastore-init/ExternalMetastoreSetup"
  source = "${path.module}/ExternalMetastoreSetup.py"
}

resource "databricks_job" "this" {
  depends_on = [databricks_notebook.metastore_setup,databricks_cluster.this]
  name = "Init Metastore"

  existing_cluster_id = databricks_cluster.this.id

  notebook_task {
    notebook_path = databricks_notebook.metastore_setup.path
  }
}

resource "null_resource" "download_metastore_lib_hive" {
  provisioner "local-exec" {
    command = "[ ! -f apache-hive-${var.hive_lib_version}-bin.tar.gz ] && wget https://archive.apache.org/dist/hive/hive-${var.hive_lib_version}/apache-hive-${var.hive_lib_version}-bin.tar.gz || echo 'File already exists'"
    interpreter = ["bash", "-c" ]
    working_dir = "lib"
  }
}

resource "null_resource" "download_metastore_lib_hadoop" {
  provisioner "local-exec" {
    command = "[ ! -f hadoop-${var.hadoop_version}.tar.gz ] && wget https://archive.apache.org/dist/hadoop/common/hadoop-${var.hadoop_version}/hadoop-${var.hadoop_version}.tar.gz || echo 'File already exists'"
    interpreter = ["bash", "-c" ]
    working_dir = "lib"
  }
}

resource "null_resource" "download_metastore_lib_mariadb" {
  provisioner "local-exec" {
    command = "[ ! -f mariadb-java-client-2.7.3.jar ] && wget https://downloads.mariadb.com/Connectors/java/connector-java-2.7.3/mariadb-java-client-2.7.3.jar || echo 'File already exists'"
    interpreter = ["bash", "-c" ]
    working_dir = "lib"
  }
}

resource "databricks_dbfs_file" "this" {
    depends_on = [null_resource.download_metastore_lib_mariadb,null_resource.download_metastore_lib_mariadb,null_resource.download_metastore_lib_hive]
    for_each = fileset(path.module, "lib/*")
        source = each.value
        path   = "/databricks/metastore-init/${each.value}"
}

resource "databricks_token" "this" {
  comment  = "Metastore init via Terraform"
  // 1 hour token
  lifetime_seconds = 3600
}

resource "null_resource" "exec_metastore_init" {
  depends_on = [databricks_notebook.metastore_setup, databricks_cluster.this, aws_db_instance.this]
  provisioner "local-exec" {
    command = "curl -X POST -H 'Authorization: Bearer ${databricks_token.this.token_value}' '${var.databricks_workspace_url}/api/2.1/jobs/run-now' -d '${jsonencode({ "job_id": "${databricks_job.this.id}"})}'"
    interpreter = ["bash", "-c" ]
  }
}