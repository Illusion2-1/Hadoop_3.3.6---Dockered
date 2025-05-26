FROM ubuntu:22.04

ARG HADOOP_VERSION=3.3.6
ARG HADOOP_HOME=/opt/hadoop
ARG HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ARG JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ARG HADOOP_USER=hadoop
ARG HADOOP_GROUP=hadoop

ARG FLUME_VERSION=1.11.0
ARG FLUME_HOME=/opt/flume

ARG SQOOP_VERSION=1.4.7
ARG SQOOP_HADOOP_VERSION_TAG=2.6.0
ARG SQOOP_HOME=/opt/sqoop
ARG MYSQL_CONNECTOR_VERSION=8.0.33
ARG POSTGRESQL_JDBC_VERSION=42.7.1


ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV HADOOP_HOME=${HADOOP_HOME}
ENV HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
ENV JAVA_HOME=${JAVA_HOME}

ENV FLUME_VERSION=${FLUME_VERSION}
ENV FLUME_HOME=${FLUME_HOME}
ENV FLUME_CONF_DIR=${FLUME_HOME}/conf

ENV SQOOP_VERSION=${SQOOP_VERSION}
ENV SQOOP_HOME=${SQOOP_HOME}
ENV SQOOP_CONF_DIR=${SQOOP_HOME}/conf

ENV PATH=${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${JAVA_HOME}/bin:${FLUME_HOME}/bin:${SQOOP_HOME}/bin:${PATH}

ENV HDFS_NAMENODE_USER=${HADOOP_USER}
ENV HDFS_DATANODE_USER=${HADOOP_USER}
ENV HDFS_SECONDARYNAMENODE_USER=${HADOOP_USER}
ENV YARN_RESOURCEMANAGER_USER=${HADOOP_USER}
ENV YARN_NODEMANAGER_USER=${HADOOP_USER}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-11-jdk \
    openssh-server \
    openssh-client \
    wget \
    gnupg \
    gosu \
    iputils-ping \
    rsyslog \
    net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://downloads.apache.org/hadoop/common/KEYS -O /tmp/HADOOP_KEYS && \
    wget https://downloads.apache.org/flume/KEYS -O /tmp/FLUME_KEYS && \
    wget https://archive.apache.org/dist/sqoop/KEYS -O /tmp/SQOOP_KEYS && \
    gpg --batch --import /tmp/HADOOP_KEYS && \
    gpg --batch --import /tmp/FLUME_KEYS && \
    gpg --batch --import /tmp/SQOOP_KEYS

# 安装 Hadoop
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -P /tmp && \
    wget https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz.asc -P /tmp && \
    gpg --verify /tmp/hadoop-${HADOOP_VERSION}.tar.gz.asc /tmp/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf /tmp/hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    ln -s /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm -f /tmp/hadoop-${HADOOP_VERSION}.tar.gz /tmp/hadoop-${HADOOP_VERSION}.tar.gz.asc

# 安装 Flume
RUN wget https://dlcdn.apache.org/flume/${FLUME_VERSION}/apache-flume-${FLUME_VERSION}-bin.tar.gz -P /tmp && \
    wget https://dlcdn.apache.org/flume/${FLUME_VERSION}/apache-flume-${FLUME_VERSION}-bin.tar.gz.asc -P /tmp && \
    gpg --verify /tmp/apache-flume-${FLUME_VERSION}-bin.tar.gz.asc /tmp/apache-flume-${FLUME_VERSION}-bin.tar.gz && \
    tar -xzf /tmp/apache-flume-${FLUME_VERSION}-bin.tar.gz -C /opt && \
    ln -s /opt/apache-flume-${FLUME_VERSION}-bin ${FLUME_HOME} && \
    rm -f /tmp/apache-flume-${FLUME_VERSION}-bin.tar.gz /tmp/apache-flume-${FLUME_VERSION}-bin.tar.gz.asc

# 安装 Sqoop
RUN wget https://archive.apache.org/dist/sqoop/${SQOOP_VERSION}/sqoop-${SQOOP_VERSION}.bin__hadoop-${SQOOP_HADOOP_VERSION_TAG}.tar.gz -P /tmp && \
    wget https://archive.apache.org/dist/sqoop/${SQOOP_VERSION}/sqoop-${SQOOP_VERSION}.bin__hadoop-${SQOOP_HADOOP_VERSION_TAG}.tar.gz.asc -P /tmp && \
    gpg --verify /tmp/sqoop-${SQOOP_VERSION}.bin__hadoop-${SQOOP_HADOOP_VERSION_TAG}.tar.gz.asc /tmp/sqoop-${SQOOP_VERSION}.bin__hadoop-${SQOOP_HADOOP_VERSION_TAG}.tar.gz && \
    tar -xzf /tmp/sqoop-${SQOOP_VERSION}.bin__hadoop-${SQOOP_HADOOP_VERSION_TAG}.tar.gz -C /opt && \
    ln -s /opt/sqoop-${SQOOP_VERSION}.bin__hadoop-${SQOOP_HADOOP_VERSION_TAG} ${SQOOP_HOME} && \
    rm -f /tmp/sqoop-${SQOOP_VERSION}.bin__hadoop-${SQOOP_HADOOP_VERSION_TAG}.tar.gz /tmp/sqoop-${SQOOP_VERSION}.bin__hadoop-${SQOOP_HADOOP_VERSION_TAG}.tar.gz.asc

RUN rm -f /tmp/*_KEYS

RUN mkdir -p ${SQOOP_HOME}/lib && \
    wget https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_CONNECTOR_VERSION}/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar -P ${SQOOP_HOME}/lib/ && \
    wget https://jdbc.postgresql.org/download/postgresql-${POSTGRESQL_JDBC_VERSION}.jar -P ${SQOOP_HOME}/lib/

RUN cp ${SQOOP_CONF_DIR}/sqoop-env-template.sh ${SQOOP_CONF_DIR}/sqoop-env.sh && \
    sed -i "s|#export HADOOP_COMMON_HOME=<Location of HADOOP_COMMON_HOME>|export HADOOP_COMMON_HOME=${HADOOP_HOME}|g" ${SQOOP_CONF_DIR}/sqoop-env.sh && \
    sed -i "s|#export HADOOP_MAPRED_HOME=<Location of HADOOP_MAPRED_HOME>|export HADOOP_MAPRED_HOME=${HADOOP_HOME}|g" ${SQOOP_CONF_DIR}/sqoop-env.sh


RUN groupadd ${HADOOP_GROUP} && \
    useradd -ms /bin/bash -g ${HADOOP_GROUP} ${HADOOP_USER}

RUN usermod -p '*' hadoop
RUN passwd -u hadoop

COPY config/* ${HADOOP_CONF_DIR}/

RUN if [ ! -f "${HADOOP_CONF_DIR}/workers" ] && [ -f "${HADOOP_CONF_DIR}/slaves" ]; then \
        mv "${HADOOP_CONF_DIR}/slaves" "${HADOOP_CONF_DIR}/workers"; \
    fi

RUN mkdir -p ${HADOOP_HOME}/data/hdfs/namenode \
             ${HADOOP_HOME}/data/hdfs/datanode \
             /opt/hadoop_data/tmp \
             ${HADOOP_HOME}/logs && \
    mkdir -p /opt/hadoop_data/hdfs/namenode /opt/hadoop_data/hdfs/datanode && \
    chown -R ${HADOOP_USER}:${HADOOP_GROUP} /opt/hadoop-${HADOOP_VERSION} \
                                        ${HADOOP_HOME}/data \
                                        /opt/hadoop_data \
                                        ${HADOOP_HOME}/logs \
                                        /opt/apache-flume-${FLUME_VERSION}-bin \
                                        ${FLUME_HOME} \
                                        /opt/sqoop-${SQOOP_VERSION}.bin__hadoop-${SQOOP_HADOOP_VERSION_TAG} \
                                        ${SQOOP_HOME}


RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config



RUN mkdir -p /run/sshd

COPY entrypoint.sh /usr/local/bin/
COPY start-hadoop.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/start-hadoop.sh

# NameNode UI
EXPOSE 9870
# NameNode IPC
EXPOSE 9000
# ResourceManager UI
EXPOSE 8088
# JobHistoryServer UI
EXPOSE 19888
# DataNode
EXPOSE 9864
# NodeManager
EXPOSE 8042

EXPOSE 44444

WORKDIR ${HADOOP_HOME}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["default"]