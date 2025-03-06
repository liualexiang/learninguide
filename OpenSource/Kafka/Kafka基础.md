
在早期版本中，对kafka操作，是通过 zookeeper实现的。后来是通过 bootstrap server实现的。

## 列出topic
如果是AWS EC2，要指定IAM认证，需要创建[client.properties](https://docs.aws.amazon.com/msk/latest/developerguide/create-topic.html)
```
bin/kafka-topics.sh --list --bootstrap-server host1_domain:9098,host2_domain:9098,host3_domain:9098 --command-config bin/client.properties
```

## 读取某一个topic的消息

```
bin/kafka-console-consumer.sh \
--bootstrap-server BOOTSTRAP_SERVER_STRING \
--consumer.config bin/client.properties \
--topic TOPIC_NAME \
--from-beginning
```

## 列出partition
```
 bin/kafka-topics.sh --bootstrap-server BOOTSTRAP_SERVER_STRING --command-config bin/client.properties --describe
```

## 删除topic

```
 bin/kafka-topics.sh --bootstrap-server BOOTSTRAP_SERVER_STRING --command-config bin/client.properties --delete --topic TOPIC_NAME
```

## compact topic 和 non-compact topic
 compact topic 和 非 compact topic，主要影响数据保留的清理。如果是 compact topic，则会根据 kafka topic里的key进行清理，旧的key会被压缩删除。如果是 非 compact topic，是根据retention.ms 或 retention.bytes进行清理。默认是non-compact topic.

## 其他
对于加载配置文件，不同的 Kafka 命令行工具使用不同的参数名：

- kafka-topics.sh 使用 `--command-config`
- kafka-console-consumer.sh 使用 `--consumer.config`
- kafka-console-producer.sh 使用 `--producer.config`