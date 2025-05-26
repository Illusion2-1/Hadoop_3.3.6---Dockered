# Set Hadoop-specific environment variables here.

# The only required environment variable is JAVA_HOME. All others are
# optional. When running accumulation classes, HADOOP_HOME may be
# useful.

# The java implementation to use.
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
# export JAVA_HOME=${JAVA_HOME}

# Extra Java CLASSPATH elements. Automatically handles line feeds.
# export HADOOP_CLASSPATH=

# The maximum amount of heap to use, in MB. Default is 1000.
# export HADOOP_HEAPSIZE_MAX=


export HDFS_NAMENODE_USER="hadoop"
export HDFS_DATANODE_USER="hadoop"
export HDFS_SECONDARYNAMENODE_USER="hadoop"
export YARN_RESOURCEMANAGER_USER="hadoop"
export YARN_NODEMANAGER_USER="hadoop"