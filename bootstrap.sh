#!/bin/bash

: ${HADOOP_HOME:=/opt/hadoop}
: ${HADOOP_USER:=hadoop}

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
#
cat $HADOOP_HOME/etc/hadoop/hdfs-site.xml.template > $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i s/NAMENODE_DIR/`pathfix $HDFS_NAMENODE_DIR`/ $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i s/DATANODE_DIR/`pathfix $HDFS_DATANODE_DIR`/ $HADOOP_HOME/etc/hadoop/hdfs-site.xml

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

#HDFS_NAMENODE_USER=$HADOOP_USER HDFS_DATANODE_USER=$HADOOP_USER YARN_NODEMANAGER_USER=$HADOOP_USER YARN_RESOURCEMANAGER_USER=$HADOOP_USER sbin/start-all.sh &
#HDFS_NAMENODE_USER=$HADOOP_USER HDFS_DATANODE_USER=$HADOOP_USER YARN_NODEMANAGER_USER=$HADOOP_USER YARN_RESOURCEMANAGER_USER=$HADOOP_USER sbin/start-all.sh &

#$HADOOP_HOME/sbin/start-dfs.sh
#$HADOOP_HOME/sbin/start-yarn.sh
#$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver # deprecated

hdfs --daemon start namenode
hdfs --daemon start datanode
yarn --daemon start resourcemanager
yarn --daemon start nodemanager
yarn --daemon start proxyserver
su -l $HADOOP_USER -c "$HADOOP_HOME/bin/mapred --daemon start historyserver"

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi
