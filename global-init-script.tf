/**
 * Creates a global init script forcing use of external HMS to be applied to all clusters.
 */

resource "databricks_global_init_script" "metastore" {
  content_base64 = base64encode(<<-EOT
    #!/bin/sh
    # Loads environment variables to determine the correct JDBC driver to use.
    source /etc/environment
    
    # Quote the label (i.e. EOF) with single quotes to disable variable interpolation.
    cat << EOF > /databricks/driver/conf/00-custom-spark.conf
    [driver] {
        # Hive specific configuration options for metastores in local mode.
        # spark.hadoop prefix is added to make sure these Hive specific options will propagate to the metastore client.
        "spark.hadoop.javax.jdo.option.ConnectionURL" = "$HMS_CONNECTION"
        "spark.hadoop.javax.jdo.option.ConnectionUserName" = "$HMS_USER"
        "spark.hadoop.javax.jdo.option.ConnectionPassword" = "$HMS_PWORD"

        # If you need to use AssumeRole, uncomment the following settings.
        # "spark.hadoop.fs.s3a.credentialsType" = "AssumeRole"
        # "spark.hadoop.fs.s3a.stsAssumeRole.arn" = "<sts-arn>"
    EOF

    if [[ $DATABRICKS_RUNTIME_VERSION == "7"* ]] || [[ $DATABRICKS_RUNTIME_VERSION == "8"* ]] || [[ $DATABRICKS_RUNTIME_VERSION == "9"* ]]; then
        HMSVERSION="2.3.7"
    else
        HMSVERSION="2.3.9"
    fi

    case "$DATABRICKS_RUNTIME_VERSION" in
    "")
        DRIVER="com.mysql.jdbc.Driver"
        ;;
    *)
        DRIVER="org.mariadb.jdbc.Driver"
        ;;
    esac

    # Add the JDBC driver and HMS version separately since must use variable expansion to choose the correct
    # driver version.
    cat << EOF >> /databricks/driver/conf/00-custom-spark.conf
        "spark.hadoop.javax.jdo.option.ConnectionDriverName" = "$DRIVER"

        # Spark specific configuration options
        "spark.sql.hive.metastore.version" = "$HMSVERSION"
        # Skip this one if <hive-version> is 0.13.x.
        #"spark.sql.hive.metastore.jars" = "/databricks/hive_metastore_jars/*"
        "spark.sql.hive.metastore.jars" = "builtin"
    }
    EOF
    EOT
  )
  name = "external metastore script"
  position = 0
  enabled = true
  depends_on = [
    aws_db_instance.this
  ]
}