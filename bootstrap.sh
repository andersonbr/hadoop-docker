#!/bin/bash

: ${HADOOP_HOME:=/opt/hadoop}
: ${HADOOP_USER:=hadoop}

# envs
if [ ! -f /etc/profile.d/envs.sh ]; then
echo HADOOP_VERSION=${HADOOP_VERSION} >> /etc/profile.d/envs.sh
echo HADOOP_HOME=${HADOOP_HOME} >> /etc/profile.d/envs.sh
echo HADOOP_USER=${HADOOP_USER} >> /etc/profile.d/envs.sh
echo HDFS_NAMENODE_USER=${HDFS_NAMENODE_USER} >> /etc/profile.d/envs.sh
echo HDFS_SECONDARYNAMENODE_USER=${HDFS_SECONDARYNAMENODE_USER} >> /etc/profile.d/envs.sh
echo HDFS_DATANODE_USER=${HDFS_DATANODE_USER} >> /etc/profile.d/envs.sh
echo YARN_NODEMANAGER_USER=${YARN_NODEMANAGER_USER} >> /etc/profile.d/envs.sh
echo YARN_RESOURCEMANAGER_USER=${YARN_RESOURCEMANAGER_USER} >> /etc/profile.d/envs.sh
echo HADOOP_DOWNLOAD_URL=${HADOOP_DOWNLOAD_URL} >> /etc/profile.d/envs.sh
echo HADOOP_COMMON_HOME=${HADOOP_COMMON_HOME} >> /etc/profile.d/envs.sh
echo HADOOP_HDFS_HOME=${HADOOP_HDFS_HOME} >> /etc/profile.d/envs.sh
echo HADOOP_MAPRED_HOME=${HADOOP_MAPRED_HOME} >> /etc/profile.d/envs.sh
echo HADOOP_YARN_HOME=${HADOOP_YARN_HOME} >> /etc/profile.d/envs.sh
echo HADOOP_CONF_DIR=${HADOOP_CONF_DIR} >> /etc/profile.d/envs.sh
echo HDFS_NAMENODE_DIR=${HDFS_NAMENODE_DIR} >> /etc/profile.d/envs.sh
echo HDFS_DATANODE_DIR=${HDFS_DATANODE_DIR} >> /etc/profile.d/envs.sh
echo JAVA_HOME=${JAVA_HOME} >> /etc/profile.d/envs.sh
echo BOOTSTRAP=${BOOTSTRAP} >> /etc/profile.d/envs.sh
echo SPARK_HOME=${SPARK_HOME} >> /etc/profile.d/envs.sh
fi

source /etc/profile

# $HADOOP_HOME/etc/hadoop/hadoop-env.sh

rm -f /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
#cd $HADOOP_HOME/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

function pathfix() {
 echo $1 | sed -e 's/\//\\\//g'
}
# altering configuration
sed s/HOSTNAME/master/ $HADOOP_HOME/etc/hadoop/core-site.xml.template > $HADOOP_HOME/etc/hadoop/core-site.xml
sed s/HOSTNAME/master/ $HADOOP_HOME/etc/hadoop/yarn-site.xml.template > $HADOOP_HOME/etc/hadoop/yarn-site.xml
#
cat $HADOOP_HOME/etc/hadoop/hdfs-site.xml.template > $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i s/NAMENODE_DIR/`pathfix $HDFS_NAMENODE_DIR`/ $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i s/DATANODE_DIR/`pathfix $HDFS_DATANODE_DIR`/ $HADOOP_HOME/etc/hadoop/hdfs-site.xml

###########################################################################################
# hdfs path criar/formatar
if [ ! -d "$HDFS_NAMENODE_DIR" ]; then
    mkdir -p $HDFS_NAMENODE_DIR
    chown -R $HADOOP_USER:$HADOOP_USER $HDFS_NAMENODE_DIR
    hadoop namenode -format 1>/dev/null 2>/dev/null
fi
if [ ! -d "$HDFS_DATANODE_DIR" ]; then
    mkdir -p $HDFS_DATANODE_DIR
    chown -R $HADOOP_USER:$HADOOP_USER $HDFS_DATANODE_DIR
    hadoop datanode -format 1>/dev/null 2>/dev/null
fi

for a in `ls -l hdfs|grep root|awk '{print $9}'`; do chown -R $HADOOP_USER:$HADOOP_USER hdfs/$a; done

service ssh start

# 3.0.3
if [[ "$HADOOP_VERSION" =~ ^3.* ]]; then
    $HADOOP_HOME/bin/hdfs --daemon start namenode
    $HADOOP_HOME/bin/hdfs --daemon start datanode
    $HADOOP_HOME/bin/yarn --daemon start resourcemanager
    $HADOOP_HOME/bin/yarn --daemon start nodemanager
    su -l $HADOOP_USER -c "$HADOOP_HOME/bin/yarn --daemon start proxyserver"
    su -l $HADOOP_USER -c "$HADOOP_HOME/bin/mapred --daemon start historyserver"
else
    #HDFS_NAMENODE_USER=$HADOOP_USER HDFS_DATANODE_USER=$HADOOP_USER YARN_NODEMANAGER_USER=$HADOOP_USER YARN_RESOURCEMANAGER_USER=$HADOOP_USER sbin/start-all.sh &
    #HDFS_NAMENODE_USER=$HADOOP_USER HDFS_DATANODE_USER=$HADOOP_USER YARN_NODEMANAGER_USER=$HADOOP_USER YARN_RESOURCEMANAGER_USER=$HADOOP_USER sbin/start-all.sh &
    su -l $HADOOP_USER -c "$HADOOP_HOME/sbin/start-dfs.sh"
    su -l $HADOOP_USER -c "$HADOOP_HOME/sbin/start-yarn.sh"
    su -l $HADOOP_USER -c "$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver"
fi

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi
if [[ $1 == "-bash" ]]; then
  /bin/bash
fi

