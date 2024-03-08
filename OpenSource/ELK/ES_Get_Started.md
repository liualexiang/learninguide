# ES 架构

一个 index 创建的时候可以指定 shards，然后也可以指定 replica数量。数据从 primary shard 到 replica shard 之间的复制，是异步的。复制是基于操作数级别的， 即document level，并非segment level.

每一条记录是一个document，写入一个document的时候，会先写到 translog里，然后按index的 flush_interval配置刷到磁盘的segment文件里，默认flush_interval是1s，为了减少磁盘IO，也可以增大 flush_interval减少写入segment文件的频率。一个segment只会包含一个index的数据。ES会自动将小的 segment汇聚成一个大的segment来优化性能，这个频率是由ES内部算法，根据系统负载，索引大小，写入频率等参数动态决定。我们也可以手动进行 force merge (POST /my_index/_forcemerg)，但是注意这个过程非常消耗IO，一般不建议频繁使用



## 集群配置

- 更改集群的Shard数量

```
PUT /_cluster/settings
 {
  "persistent": {
    "cluster.max_shards_per_node": 2000
  }
 }
```

- 创建index 指定shard和replica

  ```
      "settings": {
        "index": {
          "number_of_shards": "5",
          "number_of_replicas": "1"
        }
      }
  ```

  



# 部署ElasticSearch

* 安装Java，注意设置JAVA_HOME, Ubuntu 18.04使用 sudo apt install openjdk-8-jre-headless 安装的java路径为 /usr/lib/jvm/java-1.8.0-openjdk-amd64
* 默认ES是处于开发模式，只能从localhost访问，如果改了network.host，就变成了生产模式，在生产模式下，对于一些配置有一定的要求，如果配置不满足要求，则直接报错，服务不会起来。在开发模式下，设置不合理，会出现警告级别报警，但服务能起来。
* 在ES配置的时候，建议增加下面的几个设置
  * [文件描述符](https://www.elastic.co/guide/en/elasticsearch/reference/master/file-descriptors.html): Linux默认对openfile的限制为1024，需要增大: ulimit -n 65536。也可以修改 /etc/security/limits.conf来增加设置 "* - nofile 65536"
  * [虚拟内存](https://www.elastic.co/guide/en/elasticsearch/reference/master/vm-max-map-count.html): ES默认使用 mmapfs目录存储索引indices，默认值太小，需要增大 
  
  ```
  sudo sh -c 'echo vm.max_map_count=262144 >> /etc/sysctl.conf'
  sudo sysctl -p
  cat /proc/sys/vm/max_map_count
  ```

  * 改了 config/elasticsearch.yml 文件的 network.host 为 0.0.0.0 之后，还要修改 discovery.seed_hosts 和 cluster.initial_master_nodes，否则ES服务无法启动
* 启动ES的方法： ./bin/elasticsearch -p pid -d
* 关闭ES的方法：kill -15 `cat pid`
* ES 端口默认是 9200和9300。9200是HTTP用于外部通信；9300是TCP，用于集群间节点到节点之间的通信。
## ES 与 SQL 概念上的差异

| **SQL**          | **ElasticSearch** |
| ---------------- | ----------------- |
| Catalog/database | Cluster           |
| Table            | Index             |
| Row              | Document          |
| Column           | Field             |

* 在 Elasticsearch 6.0.0 开始，一个 index 只能有一个 mapping。 mapping 是ES中定义数据类型的一种方式.

## ES Index API
* 创建 index:   
  ``` curl -X PUT http://ES_HOST:9200/cf_etf ```
* 检查index是否存在:   
  ``` curl --head http://ES_HOST:9200/cf_etf ```
* 查看index信息：  
  ``` curl -X GET http://ES_HOST:9200/cf_etf ```
* 删除index:
  ``` curl -X DELETE http://ES_HOST:9200/cf_etf  ```
* 更新index: 用的也是put方法，直接put新的属性到原来的index即可
* 打开关闭index: 当关闭index的时候，这部分数据就处于维护模式。在生产环境中，可以设置 cluster.indices.close.enable 从true到false来禁止关闭index.
  ``` curl -X POST http://ES_HOST:9200/cf_etf/_close ```

* 对index的设置进行操作
  * 更新index的replicas数量  
  
  ```bash
  curl --location --request PUT 'http://ES_HOST:9200/cf_etf/_settings' \
    --header 'Content-Type:  application/json' \
    --header 'Accept:  application/json' \
    --data-raw '{
        "index": {
            "number_of_replicas": 2
        }
    }'
  ```

  * 更新index的codec为 best_compression   
  
  ```bash
  curl --location --request PUT 'http://ES_HOST:9200/cf_etf/_settings' \
    --header 'Content-Type:  application/json' \
    --header 'Accept:  application/json' \
    --data-raw '{
        "index": {
            "codec": "best_compression"
        }
    }'
  ```

* index template 模板
  * 创建一个模板(更新模板不会影响现有index)
  ```bash
  curl --location --request PUT 'http://ES_HOST:9200/_template/cf_etf_template' \
    --header 'Content-Type:  application/json' \
    --header 'Accept:  application/json' \
    --data-raw '{
        "index_patterns": ["cf_etf*"],
        "settings" : {
            "codec": "best_compression",
            "number_of_replicas": 2
        }
    }'
  ```
  * 查看模板/删除/查看是否存在: GET/DELETE/HEAD  http://ES_HOST:9200/_template/cf_etf_template
  * 使用模板创建index
    * index的名字以cf_etf开头，如 PUT http://ES_HOST:9200/cf_etf_large
    * GET 一下这个index，能够看到已经自定使用先前创建的模板定义(因为index名字匹配到了 cf_etf*)
  * Index aliases
    * Index alias 是给index起一个别名，然后在使用的时候可以通过这个alias来对index进行操作。在下面的操作会非常有用
      * re-indexing 的时候零宕机
      * 将多个indices放在一个组里
      * 对多个documents创建view
    * 示例: PUT/GET/DELETE/HEAD http://ES_HOST:9200/cf_etf/_alias/cf_etf_1 
    * _aliases 的这个API可以对index/indices 执行原子性操作，比如add，remove, remove_index
      * 示例:
       ```bash
        curl --location --request POST 'http://ES_HOST:9200/_aliases' \
        --header 'Content-Type:  application/json' \
        --header 'Accept:  application/json' \
        --data-raw '{
        "actions": [
            {"add": {"index":"cf_etf", "alias":"cf_etf_2"}},
            {"remove": {"index":"cf_etf", "alias":"cf_etf_1"}}
        ]
        }'
       ```
      * 示例：零宕机重新建立索引 Reindexing:
        * 当前设计中，index设计可能不合理，比如，一些字段发生了变化，这时候就要重新建立索引。我们可以移除旧的index和alias之间的关联，然后创建alias和新的index的映射。这样，依然使用同样的alias，就能访问到新的index了.
         ```bash
        curl --location --request POST 'http://ES_HOST:9200/_aliases' \
            --header 'Content-Type:  application/json' \
            --header 'Accept:  application/json' \
            --data-raw '{
                "actions": [
                    {
                        "remove": {
                            "index": "cf_etf",
                            "alias": "cf_etf_production"
                        }
                    },
                    {
                        "add": {
                            "index": "cf_etf_new",
                            "alias": "cf_etf_production"
                        }
                    }
                ]
            }' 
         ```
      * 示例： 将多个indices放在组中
        * 如果一个index中有太多的数据，在检索的时候可能会影响性能。比如有一个产品分类，包含有large, mid, small 和 others，这时候我们可以创建4个index，用相同的前缀，以及同样的alias。如果检索某一类的产品，直接搜索这个index即可，如果要检索所有产品，那么就检索这个alias。
         ```
        # 先创建多个索引，这些索引都是以 cf_etf开头的
            PUT http://ES_HOST:9200/cf_etf_others
            PUT http://ES_HOST:9200/cf_etf_small
            PUT http://ES_HOST:9200/cf_etf_mid
        # 再针对这些索引创建一个alias，这里在index处，使用了*作为通配符
            PUT http://ES_HOST:9200/cf*/_alias/cf_etf_alias
        # 通过alias访问整体数据
            GET http://ES_HOST:9200/cf*/_alias/cf_etf_alias
         ```
      * 示例： 创建View
        * 在SQL中，View是一个SQL语句的别名，在ES中也是类似的，能够对ES中的数据做过滤、统计和删除等等 
         ```bash
        # 创建一个叫做 cf_view 的index，这里面影射了两个字段: symbol 和 category，数据类型都是 keyword
        curl --location --request PUT 'http://ES_HOST:9200/cf_view' \
            --header 'Content-Type:  application/json' \
            --header 'Accept:  application/json' \
            --data-raw '{
                "mappings": {
                    "properties": {
                        "symbol": {
                            "type": "keyword"
                        },
                        "category": {
                            "type": "keyword"
                        }
                    }
                }
            }' 
        # 向 Index 中插入数据，有两种方式PUT和POST，PUT需要指定_id，但POST不用
        # 插入第一条记录
        curl --location --request PUT 'http://ES_HOST:9200/cf_view/_doc/1' \
            --header 'Content-Type:  application/json' \
            --header 'Accept:  application/json' \
            --data-raw '{"symbol": "ACWF", "category":"Equity"}'
        # 插入第二条记录
        curl --location --request POST 'http://ES_HOST:9200/cf_view/_doc' \
            --header 'Content-Type:  application/json' \
            --data-raw '{"symbol": "ACWI", "category":"International"}'
        # 创建一个叫 cf_view_international的view，过滤出category为International的document
        curl --location --request POST 'http://ES_HOST:9200/_aliases' \
            --header 'Content-Type:  application/json' \
            --data-raw '{"actions": [{"add": {"index":"cf_view","alias":"cf_view_international", "filter": {"term": {"category":"International"}}}}]}'
        # 搜索一下数据，在搜索出来得结果，可以看到hits下得total value为1,  但如果搜索原来得cf_view 的index，有2条结果
        curl --location --request GET 'http://ES_HOST:9200/cf_view_international/_search' \
            --header 'Content-Type:  application/json'
         ```

      * 其他几个常用的index的属性
       ```
        GET http://ES_HOST:9200/cf_view/_segments
        GET http://ES_HOST:9200/cf_view/_recovery
        GET http://ES_HOST:9200/cf_view/_shard_stores
        GET http://ES_HOST:9200/cf_view/_stats
       ```
  
      * Index Cache 控制
        * 清除某个index的query cache:  POST http://elk.liuxianms.com:9200/cf_view/_cache/clear?query=true
        * 清除某个index的shard requet cache: POST http://elk.liuxianms.com:9200/cf_view/_cache/clear?request=true
        * 清除某个index的field data cache: POST http://elk.liuxianms.com:9200/cf_view/_cache/clear?fielddata=true
        * 刷新/flush/synced flush/Forcemerge： POST _refresh, _flush, _flush/synced, _forcemerge


