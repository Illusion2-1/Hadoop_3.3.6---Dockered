<div align="center">
    <span> English | <a href="./README-cn.md">中文</a></span>
</div>
# Hadoop 3.3.6 Dockerfile

This Dockerfile builds a Hadoop 3.3.6 image with Java 11 with Flume and Sqoop installed.

## Intention
This repository is for CS students who had no interest in Big Data and Hadoop, but now need to learn it for their courses. The goal is to provide a simple and easy-to-use single hdfs instance Docker image that can be used for learning and experimentation.

This Dockerfile is intended to be used for development and testing purposes. It is not recommended for production use. 

## Usage
To build the Docker image, run the following command in the root directory of the repository:

```bash
sudo docker build --network=host -t hadoop:3.3.6 . # use host network for building to avoid DNS issues
```
To run the Docker container, use the following command:
```bash
sudo docker run -d --name hadoop-master \
-p 9000:9000 \
-p 9870:9870 \
-p 9868:9868 \
-p 8088:8088 \
-p 9864:9864 \
-p 10020:10020 \
-p 19888:19888 \
--hostname localhost \
-v ./data:/opt/hadoop_data \
hadoop:3.3.6
```
To access the Hadoop web UI, open your web browser and go to:
- NameNode: [http://localhost:9870](http://localhost:9870)
- ResourceManager: [http://localhost:8088](http://localhost:8088)
- JobHistory: [http://localhost:19888](http://localhost:19888)


To stop the container, run:

```bash
sudo docker stop hadoop-master
```


To remove the container, run:

```bash
sudo docker rm hadoop-master
```