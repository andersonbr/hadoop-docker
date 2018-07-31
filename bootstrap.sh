#!/bin/bash

: ${HADOOP_HOME:=/opt/hadoop}

$HADOOP_HOME/etc/hadoop/hadoop-env.sh

rm -f /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
#cd $HADOOP_HOME/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

# altering the core-site configuration
#sed s/HOSTNAME/$HOSTNAME/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml


service ssh start
#$HADOOP_HOME/sbin/start-dfs.sh
#$HADOOP_HOME/sbin/start-yarn.sh
#$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi