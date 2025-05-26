<div align="center">
    <span> <a href="./README-cn.md">中文</a> | English </span>
</div>

# Hadoop 3.3.6 Dockerfile

此 Dockerfile 使用 Java 11 构建了一个 Hadoop 3.3.6 镜像，其中安装了 Flume 和 Sqoop。

## 目的
此仓库面向那些之前对大数据和 Hadoop 不感兴趣，但因为某些课程或实验又或实训，不得不去接触这个东西的计科或任何相关专业的学生。目标是提供一个简单易用的单节点 HDFS 实例 Docker 镜像，供学习和实验使用。

此 Dockerfile 旨在用于开发、学习和测试目的。不建议用于生产环境。

## 用法
要构建 Docker 镜像，请在仓库的根目录中运行以下命令：

```bash
sudo docker build --network=host -t hadoop:3.3.6 。 # 使用主机网络进行构建以避免 DNS 问题
```
要运行 Docker 容器，请使用以下命令：

```bash
sudo docker run -d --name hadoop-master \
-p 9870:9870 \
-p 8088:8088 \
-p 19888:19888 \
--hostname localhost \
hadoop:3.3.6
```
要访问 Hadoop 网页界面，请打开网页浏览器并访问：
- NameNode：[http://localhost:9870](http://localhost:9870)
- ResourceManager：[http://localhost:8088](http://localhost:8088)
- JobHistory：[http://localhost:19888](http://localhost:19888)


要停止容器，请运行：

```bash
sudo docker stop hadoop-master
```


要删除容器，请运行：

```bash
sudo docker rm hadoop-master
```