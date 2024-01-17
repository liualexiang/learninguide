#### ZooKeeper Basic 部署文档
##### 分布式系统常见的问题

分布式系统的特点有以下几个  
* 扩展性
* 分布式
* 对等性
* 并发性
* 无序性
  
存在的问题  
* 网络通信故障
* 网络分区（脑裂）
* 三态 (成功，失败，超时)
* 节点故障

##### ZooKeeper部署  

首先要安装Java运行环境，下载解压ZooKeeper的tar包，然后修改 conf 文件夹下的 zoo.cfg文件，主要修改的有3点

```
dataDir=/home/alex/zk/zk-01/
clientPort=2181


server.1=localhost:2287:4487
server.2=localhost:2288:4488
server.3=localhost:2289:4489
server.4=localhost:2290:4490:observer
```

* dataDir 指定Zookeeper存放数据快照的目录
* clientPort指定Zookeeper的端口，使用 zkCli.sh 所要连接的端口.
* server.N 指定服务器，如上图，leader会从1--3中仲裁出来，剩下2个为follower，server.4 为 observer，不参与选举(提供只读)。N 要和 myid 文件中一致，注册配置zookeeper集群，在启动时根据这个配置进行相应的选举。
* 如果在同一个机器上模拟zookeeper多节点，如上述模拟4个节点，那么注意每一个节点的dataDir和clientPort 均不一样
* localhost:2287:4487, 这里面的第一个端口号2287指的是 leader和 follower通信的端口，第二个端口号4487指的是选举的端口号

除了修改 zoo.cfg 文件之外，还需要在 zookeeper 的根目录下创建一个 myid 的文件，server.1 的 myid 内容输入 1， server.2 的 myid 内容输入2，以此类推  

启动服务 ``` bin/zkServer.sh start ```  
查看服务状态 ``` bin/zkServer.sh status ```
停止服务 ``` bin/zkServer.sh stop ```

注意：只启动一台 zookeeper 服务，那么检查状态依然没启动，除 observer 外，至少2台才可以启动成功 ( observer 可以不启动)

##### 使用 zkCli.sh 连接 zookeeper

示例：
使用zkCli连接，通过ip和端口号可以指定连到哪个节点， 连接成功之后，使用 create 创建节点，ls 列出节点， get 查看节点

```
./zkCli.sh -server localhost:2181

create /zk "1"
ls /
get /zk
stat /zk
```

**扩展资料** ： https://www.cnblogs.com/yangzhenlong/p/8271151.html  

##### failover机制

zookeeper 选举原则为：过半原则，即：3台机器的情况下，只要启动2台，就可以选举成功。4台机器参与选举，那么需要有3台启动成功，角色才能选定。

observer 的机器不参与选举，但提供了水平扩展功能(选举也会消耗一部分性能， observer的机器可以同步数据并提供读取功能)

因此 zookeeper 要部署成 **单数** 节点模式






