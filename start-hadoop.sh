#!/bin/bash
set -e

: ${HADOOP_HOME:=/opt/hadoop}
: ${HADOOP_CONF_DIR:=$HADOOP_HOME/etc/hadoop}
: ${HADOOP_USER:=hadoop}

echo "Ensuring SSH key for user $HADOOP_USER and configuring known_hosts..."
if [ ! -d "/home/$HADOOP_USER/.ssh" ]; then
    mkdir -p "/home/$HADOOP_USER/.ssh"
    chmod 700 "/home/$HADOOP_USER/.ssh"
fi

if [ ! -f "/home/$HADOOP_USER/.ssh/id_rsa" ]; then
    echo "Generating SSH key for $HADOOP_USER..."
    ssh-keygen -t rsa -q -N "" -f "/home/$HADOOP_USER/.ssh/id_rsa"
fi

if ! grep -q -f "/home/$HADOOP_USER/.ssh/id_rsa.pub" "/home/$HADOOP_USER/.ssh/authorized_keys" 2>/dev/null; then
    echo "Adding public key to authorized_keys..."
    cat "/home/$HADOOP_USER/.ssh/id_rsa.pub" >> "/home/$HADOOP_USER/.ssh/authorized_keys"
fi
chmod 600 "/home/$HADOOP_USER/.ssh/authorized_keys"

echo "Waiting for SSHD to be ready..."
n=0
until [ $n -ge 5 ]
do
   ssh-keyscan -H localhost >> /dev/null 2>&1 && break
   n=$((n+1))
   echo "SSHD not ready yet, waiting 1s... (attempt $n)"
   sleep 1
done
if [ $n -ge 5 ]; then
    echo "ERROR: SSHD failed to start or become accessible."
    exit 1
fi
echo "SSHD is ready."


echo "Updating known_hosts..."
ssh-keyscan -H localhost >> "/home/$HADOOP_USER/.ssh/known_hosts" 2>/dev/null
ssh-keyscan -H 0.0.0.0 >> "/home/$HADOOP_USER/.ssh/known_hosts" 2>/dev/null
CURRENT_HOSTNAME=$(hostname)
if [[ ! -z "$CURRENT_HOSTNAME" && "$CURRENT_HOSTNAME" != "localhost" ]]; then
    ssh-keyscan -H "$CURRENT_HOSTNAME" >> "/home/$HADOOP_USER/.ssh/known_hosts" 2>/dev/null
fi


sort -u -o "/home/$HADOOP_USER/.ssh/known_hosts" "/home/$HADOOP_USER/.ssh/known_hosts"
chmod 644 "/home/$HADOOP_USER/.ssh/known_hosts"
chown -R ${HADOOP_USER}:${HADOOP_USER} "/home/${HADOOP_USER}/.ssh"


PERSISTENT_NAMENODE_DIR="/opt/hadoop_data/hdfs/namenode"

if [ ! -d "$PERSISTENT_NAMENODE_DIR/current" ] || [ ! "$(ls -A $PERSISTENT_NAMENODE_DIR/current 2>/dev/null)" ]; then
  echo "Formatting NameNode in $PERSISTENT_NAMENODE_DIR..."
  mkdir -p "$PERSISTENT_NAMENODE_DIR"
  chown -R ${HADOOP_USER}:${HADOOP_USER} "$(dirname "$PERSISTENT_NAMENODE_DIR")"

  $HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
  echo "NameNode formatted."
else
  echo "NameNode already formatted in $PERSISTENT_NAMENODE_DIR or data directory not empty."
fi

echo "Starting Hadoop daemons..."


$HADOOP_HOME/sbin/start-dfs.sh

$HADOOP_HOME/sbin/start-yarn.sh

$HADOOP_HOME/bin/mapred --daemon start historyserver
echo "Hadoop daemons started."

if [[ "$1" == "bash" ]]; then
  echo "Entering bash shell..."
  /bin/bash
else
  echo "Hadoop is running. Tailing logs to keep container alive or use 'docker exec -it <container_name> bash' to interact."

  sleep 10

  LOG_DIR="$HADOOP_HOME/logs"
  LATEST_NAMENODE_LOG=$(ls -t $LOG_DIR/hadoop-${HADOOP_USER}-namenode-*.log 2>/dev/null | head -n 1)
  LATEST_RESOURCEMANAGER_LOG=$(ls -t $LOG_DIR/hadoop-${HADOOP_USER}-resourcemanager-*.log 2>/dev/null | head -n 1)

  if [ -f "$LATEST_NAMENODE_LOG" ]; then
      echo "Tailing $LATEST_NAMENODE_LOG..."
      tail -n +1 -f "$LATEST_NAMENODE_LOG"
  elif [ -f "$LATEST_RESOURCEMANAGER_LOG" ]; then
      echo "Tailing $LATEST_RESOURCEMANAGER_LOG..."
      tail -n +1 -f "$LATEST_RESOURCEMANAGER_LOG"
  else
      echo "Warning: Main Hadoop log file not found. Keeping container alive with sleep loop."
      while true; do sleep 3600; done
  fi
fi