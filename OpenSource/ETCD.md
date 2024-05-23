# ETCD

## ETCD 基础命令



```
export PATH=/usr/local/bin:$PATH

# 创建用户
etcdctl --user USER:PASSWORD user list
etcdctl --user USER:PASSWORD user create USERNAME


# 创建 role
etcdctl --user USER:PASSWORD role list
etcdctl --user USER:PASSWORD role add ROLENAME


# 给 role 分配权限
etcdctl --user USER:PASSWORD role grant-permission ROLENAME write --prefix=true '/PATH'

# 给用户分配role
etcdctl --user USER:PASSWORD user grant-role USERNAME ROLENAME

# 查看用户在哪个role里
etcdctl --user USER:PASSWORD user get USERNAME

查看role的权限
etcdctl --user USER:PASSWORD role get ROLENAME

# 查看节点
etcdctl --user USER:PASSWORD member list

# 查看当前的节点健康状态
etcdctl endpoint status

# 查看IP1,IP2,IP3节点状况，并指定证书，可看到哪个节点是主节点
etcdctl --endpoints https://IP1:2379,https://IP2:2379,https://IP3:2379 --cacert /opt/etcd/cert/ca.crt --cert /opt/etcd/cert/server.crt --key /opt/etcd/cert/server.key --insecure-skip-tls-verify endpoint status
```

ETCD 搭建好集群后，前面可以挂一个TCP 负载均衡器，流量无论写到哪个节点都可以。或者直接在DNS解析到每一个节点上，应用配置这个DNS（但节点挂了如何维护DNS需要考虑）。或者是应用直接配置节点地址，client sdk会自己retry。



## 搭建ETCD

搭建ETCD的时候，可以用 https://discovery.etcd.io/new?size=3 这个在线ETCD自动发现url 来让各个节点动态加入到集群中。启动命令的一个示例如下(如果没必要，集群内部节点之间通信，可以不用TLS)

```
 echo etcd --name etcd${instance_count} --peer-auto-tls \
  --cert-file=/opt/etcd/cert/server.crt --key-file=/opt/etcd/cert/server.key \
  --client-cert-auth --trusted-ca-file=/opt/etcd/cert/ca.crt \
  --initial-advertise-peer-urls https://$LOCAL_IP:2380 \
  --listen-peer-urls https://$LOCAL_IP:2380 \
  --listen-client-urls https://$LOCAL_IP:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://$LOCAL_IP:2379 \
  --discovery ${discovery_etcd_url}
```

### ETCD 部署注意

etcd启动的时候需要打开 boltDB文件，如果DB文件过大，会导致启动过慢，同时会用 nmap 将db 映射到内存，因此内存一定要大雨DB配置(quota-backend-bytes)，默认的 DB quota配额是2GB。建议开启压缩，否则 etcd所有变更历史，都在db里，会导致db一直膨胀。压缩模块会回收旧版本的空间，具体原理是：将旧版本空间打一个free tag，如果后续写入数据可以复用这个空间，不用申请新空间。如果将 quota-backend-bytes 改成0，就是禁用配额，不建议这么设置，默认不设置就是2GB

etcd不支持数据分片，每一个节点都是完整的数据。所以ETCD部署的时候，DB不要超过8GB.

ETCD 适合读多写少的场景。一般读会占 2/3 以上的请求

### ETCD使用

在读ETCD的时候，有两种方法，一种是线性读（默认的方法），这个会保证数据的一致性，当有数据要更新到 boltdb里的时候，节点会到leader节点检查当前自己的缓存是否是最新(查询leader节点的 readIndex)，如果不是最新，则先更新本地的boltdb，之后再读，再返回读取成功。

如果为了性能，但可以牺牲一定程度的一致性，那么可以使用串行读 (Serializable) 的方式，这个只要读的时候，就会立即返回，并不会强制要求更新数据





## Raft 原理

```
https://thesecretlivesofdata.com/raft/
```





参考文档: https://etcd.io/docs/v3.3/op-guide/authentication/

