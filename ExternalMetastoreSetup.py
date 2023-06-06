# Databricks notebook source
# DBTITLE 1,Check connectivity with RDS
# MAGIC %sh
# MAGIC arrIN=(${HIVE_URL//:/ })
# MAGIC db=`echo ${arrIN[2]} | sed 's/\/\///g'`
# MAGIC 
# MAGIC nslookup $db
# MAGIC nc -vz $db 3306

# COMMAND ----------

# DBTITLE 1,Check libs in DBFS
# MAGIC %sh
# MAGIC ls /dbfs/$DBFS_LIB/

# COMMAND ----------

# DBTITLE 1,Deploy dependencies for Hive schematool
# MAGIC %sh
# MAGIC cp -r /dbfs/$DBFS_LIB/* /tmp/
# MAGIC tar -xvzf /tmp/hadoop*tar.gz --directory /opt
# MAGIC tar -xvzf /tmp/apache-hive-*tar.gz --directory /opt
# MAGIC 
# MAGIC cp /tmp/mariadb*.jar ${TARGET_HIVE_HOME}/lib/mariadb_java_client.jar

# COMMAND ----------

# MAGIC %sh
# MAGIC mkdir -p ${JARS_DIRECTORY}
# MAGIC cp -r ${TARGET_HIVE_HOME}/lib/. ${JARS_DIRECTORY}
# MAGIC cp -r ${TARGET_HADOOP_HOME}/share/hadoop/common/lib/. ${JARS_DIRECTORY}

# COMMAND ----------

# DBTITLE 1,Test Hive Environment Variables - set these vars on cluster UI --> Advance tab
# MAGIC %sh
# MAGIC echo $HIVE_URL
# MAGIC echo $HIVE_USER
# MAGIC echo $HIVE_PASSWORD
# MAGIC echo $MYSQL_DRIVER
# MAGIC echo $TARGET_HIVE_HOME
# MAGIC echo $TARGET_HADOOP_HOME

# COMMAND ----------

# DBTITLE 1,Initialize hive schema
# MAGIC %sh
# MAGIC 
# MAGIC export HIVE_HOME=$TARGET_HIVE_HOME
# MAGIC export HADOOP_HOME=$TARGET_HADOOP_HOME
# MAGIC arrIN=(${TARGET_HIVE_VERSION//./ })
# MAGIC 
# MAGIC ${TARGET_HIVE_HOME}/bin/schematool -dbType mysql -url "$HIVE_URL" -passWord "$HIVE_PASSWORD" -userName "$HIVE_USER" -driver "$MYSQL_DRIVER" -info
# MAGIC RES=$?
# MAGIC if [ $RES -ne 0 ]; then
# MAGIC   echo "It looks like it's not initialized yet, going to initialize"
# MAGIC   ${TARGET_HIVE_HOME}/bin/schematool -dbType mysql -url "$HIVE_URL" -passWord "$HIVE_PASSWORD" -userName "$HIVE_USER" -driver "$MYSQL_DRIVER" --initSchemaTo ${arrIN[0]}"."${arrIN[1]}".0" -verbose
# MAGIC fi

# COMMAND ----------

# DBTITLE 1,Validate hive is initialized
# MAGIC %sh
# MAGIC 
# MAGIC export HIVE_HOME=$TARGET_HIVE_HOME
# MAGIC export HADOOP_HOME=$TARGET_HADOOP_HOME
# MAGIC ${TARGET_HIVE_HOME}/bin/schematool -dbType mysql -url "$HIVE_URL" -passWord "$HIVE_PASSWORD" -userName "$HIVE_USER" -driver "$MYSQL_DRIVER" -info
