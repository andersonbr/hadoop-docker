FROM openjdk:8

MAINTAINER Anderson Calixto andersonbr@gmail.com

# Init ENV
ENV HADOOP_VERSION 3.0.3
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_USER hadoop

# Apply JAVA_HOME
RUN . /etc/environment
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-amd64

# Install Dependences
RUN apt-get update; apt-get install zip -y; \
apt-get install wget unzip git openssh-server openssh-client rsync -y; \
apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

RUN mkdir ${HADOOP_HOME};

RUN useradd -s /bin/bash -d ${HADOOP_HOME} ${HADOOP_USER};

# passwordless ssh
RUN rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key ${HADOOP_HOME}/.ssh/id_rsa ${HADOOP_HOME}/.ssh/authorized_keys
RUN mkdir ${HADOOP_HOME}/.ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f ${HADOOP_HOME}/.ssh/id_rsa
RUN cp ${HADOOP_HOME}/.ssh/id_rsa.pub ${HADOOP_HOME}/.ssh/authorized_keys

ADD core-site.xml.template $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
RUN chown -R ${HADOOP_USER}:${HADOOP_USER} ${HADOOP_HOME};

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh
ENV BOOTSTRAP /etc/bootstrap.sh

# ssh fix
# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" > /etc/ssh/sshd_config
# 2122
RUN echo "Port 22" >> /etc/ssh/sshd_config

RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
RUN chmod 0700 ${HADOOP_HOME}/.ssh
RUN chmod 0600 ${HADOOP_HOME}/.ssh/*


#Always non-root user
#USER ${HADOOP_USER}
WORKDIR ${HADOOP_HOME}

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090
# Mapred ports
EXPOSE 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 22