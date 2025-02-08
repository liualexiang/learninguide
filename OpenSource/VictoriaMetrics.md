

## 单节点模式
单节点模式[文档](https://docs.victoriametrics.com/single-server-victoriametrics/)  
只需要VictoriaMetrics 这一个二进制就可以.  
http://<victoriametrics-addr>:8428 端口提供了prometheus 查询能力.  
http://victoriametrics:8428/vmui 提供了一个简单的UI，集群模式是vmselect提供的 http://<vmselect>:8481/select/<accountID>/vmui/ 


## 集群模式的组件
集群模式[文档](https://docs.victoriametrics.com/cluster-victoriametrics/)  
集群模式主要有两个特性：1.支持多租户，2.能横向扩容，适合数据量比较大，性能要求比较高的场景  
集群模式[URL格式](https://docs.victoriametrics.com/cluster-victoriametrics/#url-format)

* vmstorage：存储metrics
通过 -storageDataPath 参数指定存储路径  
通过 -retentionPeriod 参数指定保留时间  
vmstorage 的 8400 端口， 是给 vminsert 写入用的
vmstorage 的 8401 端口，是给 vmselect 读取用的
vmstorage 的 8482 端口，是给 /metrics 接口用的


* vminsert：写入到vmstorage  
vminsert 通过 -storageNode 参数指定 vmstorage的地址，比如  
vminsert的 8480 端口，提供了写入能力，格式是: ` http://<vminsert>:8480/insert/<accountID>/<suffix> `
如果是在其他账号里部署vmagent，通过vminsert写入到 vmstorage里，此时需要将 vminsert 前面加一个 LB，将8480端口暴露出去


* vmselect：从vmstorage里查询  
vmselect 通过 -storageNode 指定 vmstorage 的地址，比如   
vmselect 通过 -vmalert.proxyURL 指定 vmalert 的地址  

vmselect 的 8481 端口，提供了UI访问能力，格式是: ` http://<vmselect>:8481/select/<accountID>/vmui/ `  
vmselect 的 8481端口，提供了查询能力，格式是: ` http://<vmselect>:8481/select/<accountID>/prometheus/<suffix> `  
vmselect 列出所有tenant，格式是: ` http://<vmselect>:8481/admin/tenants `  


集群模式的上述三个组件，都会将自身的指标通过 /metrics 接口暴露出去，vminsert 是 8480（vmagent客户端，将数据通过vminsert 的8480写进来的），vmselect是 8481（grafana查询prometheus的时候，查询的是vmselect的8481端口），vmstorage是 8400（vminsert通过vmstorage的8400将数据写入）

## vmagent
上述通过 集群模式，部署的组件，主要是对分布式存储，分布式存储读写的组件。我们还需要一个支持 prometheus 协议的程序，解析 prometheus 的配置文件，比如配置 scrape 规则等，然后将 scrape 到的数据，通过 vminsert 写入到 vmstorage 里 (集群模式，技术上 vmagent 也可以直接写入到 vmstorage，但尽量不要这么做，未验证)。按下面配置，如果 grafana 连prometheus，地址也是 `https://vminsert:8480/insert/0/prometheus`  
示例:  
```
/path/to/vmagent -promscrape.config=/path/to/prometheus.yml -remoteWrite.url=https://vminsert:8480/insert/0/prometheus
```

在单节点模式下，也可以让 vmagent 直接写入到 VictoriaMetrics 里(端口是 8428)，用于简单部署  
```
/path/to/vmagent -promscrape.config=/path/to/prometheus.yml -remoteWrite.url=http://victoria-metrics-host:8428/api/v1/write
```

vmagent 可以作为 prometheus 的remote_write 的代理，接口是: `http://<vmagent>:8429/api/v1/write`，最终通过 vminsert 写入到 vmstorage 里

vmagent 的 8429 端口，除了支持remote write之外，还有提供 /metrics 接口，所以 vmagent 可以scrape自身的 8429 端口

## vmalert
vmalert 是执行 prometheus 的 alerting rule 和 recording rule 的功能。vmalert的 datasource 要指向 vmselect的地址，比如 `https://vminsert:8480/insert/0/prometheus`。 notifier 后面是 alert manager的地址，默认alertmanager是 9093 端口。remoteWrite 和 remoteRead url，只有在需要使用 recording rule的时候才需要，一个用户写入recording rule的记录，一个用于查询recording rule的记录。如果不使用recording rule功能，可以不用写着两个参数。顾名思义，remote read需要指定 vmselect，remote write需要指定 vminsert地址。-rule后面跟 alert rule文件，支持通配符，比如某一个路径下所有的 `*.rules` 文件  

```
./bin/vmalert -rule=alert.rules \            # Path to the file with rules configuration. Supports wildcard
    -datasource.url=http://localhost:8428 \  # Prometheus HTTP API compatible datasource
    -notifier.url=http://localhost:9093 \    # AlertManager URL (required if alerting rules are used)
    -notifier.url=http://127.0.0.1:9093 \    # AlertManager replica URL
    -remoteWrite.url=http://localhost:8428 \ # Remote write compatible storage to persist rules and alerts state info (required if recording rules are used)
    -remoteRead.url=http://localhost:8428 \  # MetricsQL compatible datasource to restore alerts state from
    -external.label=cluster=east-1 \         # External label to be applied for each rule
    -external.label=replica=a                # Multiple external labels may be set
```

## vmauth
vmauth 在集群模式中，可以实现不同的用户访问不同的tenant里的数据，确保每个租户只能访问自己的数据，从而实现隔离


## 维护
先 gracefully shutdown 所有的 vminsert 和 vmselect，然后再停止 vmstorage。之后


## cloudwatch agent
配置文件不是很成熟，文档写的比较乱。ubuntu下的cloudwatch agent 和 amazon linux下yum 安装的还不太一样。ubuntu是跟docker里一样。amazon linux下的，貌似不能读取到ECS的IAM Role credential。amazon linux下用的是 amazon-cloudwatch-agent.json 的配置文件，然后start-cloudwatch-agent脚本。ubuntu下，是使用 amazon-cloudwatch-agent.toml配置文件，通过 cloudwatch-agent --config=amazon-cloudwatch-agent.toml 来指定配置文件.






