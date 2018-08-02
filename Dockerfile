FROM openjdk:8

MAINTAINER Anderson Calixto andersonbr@gmail.com

# Init ENV
ENV HADOOP_VERSION 3.0.3
#ENV HADOOP_VERSION 2.7.7
#ENV HADOOP_VERSION 2.9.1
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_USER hadoop
ENV HDFS_NAMENODE_USER ${HADOOP_USER}
ENV HDFS_SECONDARYNAMENODE_USER ${HADOOP_USER}
ENV HDFS_DATANODE_USER ${HADOOP_USER}
ENV YARN_NODEMANAGER_USER ${HADOOP_USER}
ENV YARN_RESOURCEMANAGER_USER ${HADOOP_USER} 
#ENV HADOOP_DOWNLOAD_URL http://www.apache.org/dist/hadoop/common/hadoop-3.0.3/hadoop-3.0.3.tar.gz
ENV HADOOP_DOWNLOAD_URL http://www.apache.org/dist/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz

ENV HADOOP_COMMON_HOME ${HADOOP_HOME}
ENV HADOOP_HDFS_HOME ${HADOOP_HOME}
ENV HADOOP_MAPRED_HOME ${HADOOP_HOME}
ENV HADOOP_YARN_HOME ${HADOOP_HOME}
ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
ENV HDFS_NAMENODE_DIR ${HADOOP_HOME}/hdfs/namenode
ENV HDFS_DATANODE_DIR ${HADOOP_HOME}/hdfs/datanode

# Apply JAVA_HOME
RUN . /etc/environment
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-amd64

# Install Dependences
RUN apt-get update; apt-get install zip -y; \
apt-get install wget unzip git openssh-server openssh-client rsync -y; \
apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

RUN mkdir ${HADOOP_HOME};

RUN useradd -s /bin/bash -d ${HADOOP_HOME} ${HADOOP_USER};

# download
#RUN curl -s ${HADOOP_DOWNLOAD_URL} | tar -xz -C /opt
#RUN cd /opt && mv hadoop-* hadoop
ADD ./hadoop-${HADOOP_VERSION} ${HADOOP_HOME}

# passwordless ssh
RUN rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key ${HADOOP_HOME}/.ssh/id_rsa ${HADOOP_HOME}/.ssh/authorized_keys
RUN mkdir ${HADOOP_HOME}/.ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f ${HADOOP_HOME}/.ssh/id_rsa
RUN cp ${HADOOP_HOME}/.ssh/id_rsa.pub ${HADOOP_HOME}/.ssh/authorized_keys
RUN cp -a ${HADOOP_HOME}/.ssh /root/.ssh
RUN chown -R root:root /root/.ssh

# mod hadoop files
RUN echo export JAVA_HOME=${JAVA_HOME} >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN echo export HADOOP_HOME=${HADOOP_HOME} >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN echo export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

#RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=$JAVA_HOME\nexport HADOOP_PREFIX=$HADOOP_PREFIX\nexport HADOOP_HOME=$HADOOP_PREFIX\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
#RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
ADD hdfs-site.xml.template $HADOOP_HOME/etc/hadoop/hdfs-site.xml.template
ADD yarn-site.xml.template $HADOOP_HOME/etc/hadoop/yarn-site.xml.template
ADD core-site.xml.template $HADOOP_HOME/etc/hadoop/core-site.xml.template
RUN chown -R ${HADOOP_USER}:${HADOOP_USER} ${HADOOP_HOME};

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh
ENV BOOTSTRAP /etc/bootstrap.sh

# env files
RUN echo '#!/bin/bash'"\n\nexport PATH=$PATH:"${HADOOP_HOME}"/bin:"${HADOOP_HOME}"/sbin" > /etc/profile.d/hadoop.sh

# ssh fix
RUN echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
RUN chmod 0700 ${HADOOP_HOME}/.ssh
RUN chmod 0600 ${HADOOP_HOME}/.ssh/*


#Always non-root user
#USER ${HADOOP_USER}
WORKDIR ${HADOOP_HOME}

CMD ["/etc/bootstrap.sh", "-d"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090
# Mapred ports
EXPOSE 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 22

