%%bash

#################################################
# HOME LOCATION
#################################################

mkdir -p /home/cloudera

cd /home/cloudera

#################################################
# INSTALL JAVA 8
#################################################

if [ ! -d "/usr/lib/jvm/java-8-openjdk-amd64" ]; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-8-jdk-headless > /dev/null 2>&1
fi

#################################################
# ENV VARIABLES
#################################################

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

export HADOOP_HOME=/home/cloudera/hadoop-2.7.7

export HADOOP_MAPRED_HOME=/home/cloudera/hadoop-2.7.7

export HIVE_HOME=/home/cloudera/apache-hive-3.1.3-bin

export SQOOP_HOME=/home/cloudera/sqoop-1.4.7.bin__hadoop-2.6.0

export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$SQOOP_HOME/bin

#################################################
# DOWNLOAD
#################################################

[ ! -f hadoop-2.7.7.tar.gz ] && wget -q https://archive.apache.org/dist/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz

[ ! -f apache-hive-3.1.3-bin.tar.gz ] && wget -q https://archive.apache.org/dist/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz

[ ! -f sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz ] && wget -q https://archive.apache.org/dist/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz

#################################################
# EXTRACT
#################################################

[ ! -d hadoop-2.7.7 ] && tar -xzf hadoop-2.7.7.tar.gz

[ ! -d apache-hive-3.1.3-bin ] && tar -xzf apache-hive-3.1.3-bin.tar.gz

[ ! -d sqoop-1.4.7.bin__hadoop-2.6.0 ] && tar -xzf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz

#################################################
# FIX HADOOP JAVA
#################################################

sed -i '/JAVA_HOME/d' $HADOOP_HOME/etc/hadoop/hadoop-env.sh

echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

#################################################
# HDFS CONFIG
#################################################

mkdir -p /tmp/hadoop-root/dfs/name

mkdir -p /tmp/hadoop-root/dfs/data

cat > $HADOOP_HOME/etc/hadoop/core-site.xml <<EOF
<configuration>

<property>
<name>fs.defaultFS</name>
<value>hdfs://localhost:9000</value>
</property>

</configuration>
EOF

cat > $HADOOP_HOME/etc/hadoop/hdfs-site.xml <<EOF
<configuration>

<property>
<name>dfs.replication</name>
<value>1</value>
</property>

<property>
<name>dfs.namenode.name.dir</name>
<value>file:///tmp/hadoop-root/dfs/name</value>
</property>

<property>
<name>dfs.datanode.data.dir</name>
<value>file:///tmp/hadoop-root/dfs/data</value>
</property>

</configuration>
EOF

#################################################
# CLEAN OLD PROCESSES
#################################################

pkill -f NameNode || true

pkill -f DataNode || true

rm -rf /tmp/hadoop-root

mkdir -p /tmp/hadoop-root/dfs/name

mkdir -p /tmp/hadoop-root/dfs/data

#################################################
# FORMAT NAMENODE
#################################################

hdfs namenode -format -force > /dev/null 2>&1

#################################################
# START HDFS
#################################################

nohup hdfs namenode > /tmp/namenode.log 2>&1 &

sleep 10

nohup hdfs datanode > /tmp/datanode.log 2>&1 &

sleep 20

#################################################
# CREATE HDFS DIRECTORIES
#################################################

hdfs dfs -mkdir -p /user/cloudera

hdfs dfs -chmod -R 777 /user/cloudera

hdfs dfs -mkdir -p /user/hive/warehouse

hdfs dfs -chmod -R 777 /user/hive/warehouse

#################################################
# FIX HIVE LIBRARIES
#################################################

wget -q -nc https://repo1.maven.org/maven2/com/google/guava/guava/27.0-jre/guava-27.0-jre.jar

rm -f /home/cloudera/apache-hive-3.1.3-bin/lib/guava-19.0.jar

cp guava-27.0-jre.jar /home/cloudera/apache-hive-3.1.3-bin/lib/

wget -q -nc https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar

cp mysql-connector-java-5.1.38.jar $SQOOP_HOME/lib/

wget -q -nc https://repo1.maven.org/maven2/commons-lang/commons-lang/2.6/commons-lang-2.6.jar

cp commons-lang-2.6.jar $SQOOP_HOME/lib/

#################################################
# HIVE CONFIG
#################################################

cat > /home/cloudera/apache-hive-3.1.3-bin/conf/hive-site.xml <<EOF
<configuration>

<property>
<name>javax.jdo.option.ConnectionURL</name>
<value>jdbc:derby:;databaseName=metastore_db;create=true</value>
</property>

<property>
<name>javax.jdo.option.ConnectionDriverName</name>
<value>org.apache.derby.jdbc.EmbeddedDriver</value>
</property>

<property>
<name>hive.metastore.warehouse.dir</name>
<value>/user/hive/warehouse</value>
</property>

</configuration>
EOF

#################################################
# CLEAN HIVE
#################################################

rm -rf metastore_db

rm -rf derby.log

#################################################
# INIT HIVE
#################################################

schematool -dbType derby -initSchema > /dev/null 2>&1

#################################################
# FINAL SCREEN
#################################################

clear

echo ""

echo "##############"

echo "## Ready to use ##"

echo "##############"
