#### 使用开源方案来分析Azure NSG flow log
##### 在Ubuntu 16.04系统下最小化安装示例
##### 安装logstash

使用Logstash将JSON格式的日志拉平到一行一行的，在Ubuntu16.04系统下使用编译好的deb包进行安装

```
curl -L -O https://artifacts.elastic.co/downloads/logstash/logstash-5.2.0.deb
sudo dpkg -i logstash-5.2.0.deb
```

配置Logstash解析JSON格式的flow log，并将其发送到ElasticSearch中，要创建一个Logstash.conf文件

```
sudo touch /etc/logstash/conf.d/logstash.conf
```

将下面的内容复制到logstash.conf中，注意修改Storage Account的ACCESS key

```
input {
   azureblob
   {
     storage_account_name => "mystorageaccount"
     storage_access_key => STORAGEKEY
     container => "insights-logs-networksecuritygroupflowevent"
     codec => "json"
     # Refer https://docs.microsoft.com/azure/network-watcher/network-watcher-read-nsg-flow-logs
     # Typical numbers could be 21/9 or 12/2 depends on the nsg log file types
     file_head_bytes => 12
     file_tail_bytes => 2
     # Enable / tweak these settings when event is too big for codec to handle.
     # break_json_down_policy => "with_head_tail"
     # break_json_batch_count => 2
   }
 }
 filter {
   split { field => "[records]" }
   split { field => "[records][properties][flows]"}
   split { field => "[records][properties][flows][flows]"}
   split { field => "[records][properties][flows][flows][flowTuples]"}

   mutate {
     split => { "[records][resourceId]" => "/"}
     add_field => { "Subscription" => "%{[records][resourceId][2]}"
       "ResourceGroup" => "%{[records][resourceId][4]}"
       "NetworkSecurityGroup" => "%{[records][resourceId][8]}" 
     }
     convert => {"Subscription" => "string"}
     convert => {"ResourceGroup" => "string"}
     convert => {"NetworkSecurityGroup" => "string"}
     split => { "[records][properties][flows][flows][flowTuples]" => "," }
     add_field => {
       "unixtimestamp" => "%{[records][properties][flows][flows][flowTuples][0]}"
       "srcIp" => "%{[records][properties][flows][flows][flowTuples][1]}"
       "destIp" => "%{[records][properties][flows][flows][flowTuples][2]}"
       "srcPort" => "%{[records][properties][flows][flows][flowTuples][3]}"
       "destPort" => "%{[records][properties][flows][flows][flowTuples][4]}"
       "protocol" => "%{[records][properties][flows][flows][flowTuples][5]}"
       "trafficflow" => "%{[records][properties][flows][flows][flowTuples][6]}"
       "traffic" => "%{[records][properties][flows][flows][flowTuples][7]}"
        "flowstate" => "%{[records][properties][flows][flows][flowTuples][8]}"
        "packetsSourceToDest" => "%{[records][properties][flows][flows][flowTuples][9]}"
         "bytesSentSourceToDest" => "%{[records][properties][flows][flows][flowTuples][10]}"
         "packetsDestToSource" => "%{[records][properties][flows][flows][flowTuples][11]}"
        "bytesSentDestToSource" => "%{[records][properties][flows][flows][flowTuples][12]}"
     }
     add_field => {
       "time" => "%{[records][time]}"
       "systemId" => "%{[records][systemId]}"
       "category" => "%{[records][category]}"
       "resourceId" => "%{[records][resourceId]}"
       "operationName" => "%{[records][operationName}}"
       "Version" => "%{[records][properties][Version}}"
       "rule" => "%{[records][properties][flows][rule]}"
       "mac" => "%{[records][properties][flows][flows][mac]}"
     }
     convert => {"unixtimestamp" => "integer"}
     convert => {"srcPort" => "integer"}
     convert => {"destPort" => "integer"}
     add_field => { "message" => "%{Message}" }        
   }

   date {
     match => ["unixtimestamp" , "UNIX"]
   }
 }
 output {
   stdout { codec => rubydebug }
   elasticsearch {
     hosts => "localhost"
     index => "nsg-flow-logs"
   }
 }
```

在上述配置文件中，需要指定文件头部字节数和尾部字节数，可以用PowerShell脚本获得，注意观察输出结果的第一行和最后一行
```
$StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName xiangliu_csa -Name xiangliu).Value[0]
$ctx = New-AzStorageContext -StorageAccountName xiangliu -StorageAccountKey $StorageAccountKey
$ContainerName = "insights-logs-networksecuritygroupflowevent"
$BlobName = "resourceId=/SUBSCRIPTIONS/5FB605AB-C16C-4184-8A02-FEE38CC11B8C/RESOURCEGROUPS/XIANGLIU_CSA/PROVIDERS/MICROSOFT.NETWORK/NETWORKSECURITYGROUPS/NSG_WEB_REMOTE_ICMP/y=2020/m=06/d=26/h=15/m=00/macAddress=000D3AE5D159/PT1H.json"
$Blob = Get-AzStorageBlob -Context $ctx -Container $ContainerName -Blob $BlobName
$CloudBlockBlob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob] $Blob.ICloudBlob
$blockList = $CloudBlockBlob.DownloadBlockListAsync()
$blockList.Result
```

在Logstash配置文件中，input中使用了azureblob插件（插件稍后安装），然后指定了读取的文件位置以及格式，filter中将JSON格式的文件拉平，output中将其输出到Elastic Search中（稍后安装）

接下来安装一下azureblob插件(需要安装JAVA，并指定好JAVA_HOME路径)

```
# Ubuntu 16.04安装java运行环境
#sudo apt-get install default-jre
#JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64/
#echo $JAVA_HOME
# 如果要把JAVA_HOME放在全局变量中，可修改/etc/environment这个文件

cd /usr/share/logstash/bin
sudo ./logstash-plugin install logstash-input-azureblob
```

##### 可选： 有关Logstash的配置解读

* Logstash pipeliine的三大流程: Input --> Filter --> Output
* input 则利用了azure blob的插件，按照插件要求的配置即可，如果是中国区Azure Blob，则需要加上 endpoint => "core.chinacloudapi.cn"。点击[此处](AzureNSGDemo.json)下载示例数据.
* **主要解读一下Filter部分，也是对logstash配置的关键部分**
  * filter 部分的split   
    * 这部分的split主要是用来将JSON文件中的list数据拆开，建议将所有有关list的都拆出来。之所以有4个split，是因为有4个list (records最外侧一层，properties.flows一层，flows.flows一层，flows.flowTuples一层)，从外层到内层注意拆解。
      * 示例 split { field => "[records]" }

  * mutate里面的split
    * 这部分split主要是将在filter中拆出来的每一个元素，通过某些特定的字段再次拆解，如将ResourceID按"/"进行拆分，将 "flowTuples" 里面的每一行(之所以每一行，是因为filter中已经split过)按","进行拆分，要读取拆分后的数据，则按[0],[1][...] 这种顺序读取。示例： split => { "[records][resourceId]" => "/"}
    * mutate 里面的split需要用 =>，filter里面的split直接跟 {}
    * add_field 添加需要的字段，这个主要是将mutate里面split之后的结果给添加到要输出的字段中(list索引从0开始)。毕竟split的最终目的就是为了提取有效字段，add_field的重要性可想而知。示例： add_field => { "Subscription" => "%{[records][resourceId][2]}"}
    * convert 将数据转换为需要的数据类型，示例: convert => {"Subscription" => "string"}
  
  * 对于ip处理的[geoip](https://www.elastic.co/guide/en/logstash/current/plugins-filters-geoip.html)的插件
    * logstash默认已经有geoip的插件，但需要指定下GeoLite2数据库
    * source 后面指定要处理哪个字段作为ip地址(字段名字可以在上述add_field中指定)
    * target 后面跟要将查询结果保存到哪个字段中，如指定 geoip，则对于查询的城市，字段名为 geoip.city_name
    * add_field 可以添加字段，比如可以通过查询经纬度信息，将其添加到geoip.coordinates 这个list中
    * remove_field 默认情况下，如果不加说明，会打印所有字段，通过remove_field 可以移除指定字段
    * fields 这个可以直接指定要显示哪些字段(如果要对经纬度数据合并，那么fields里面要有经纬度的字段，才能用add_field，如果没有fields字段，则说明显示所有)
    * 如果在ES里面，想要直接识别经纬度坐标，那么需要将经纬度保存成float类型。同时需要创建ES的index的时候，指定这个字段类型为 geo_point.
  * 通过date 对时间日期处理，比如将unixtimestamp指定为unix时间戳:  date { match => ["unixtimestamp" , "UNIX"] }

* output 的定义
  * output根据需要，可以输出到redis, ES等，一般为debug方便，也可以输出为 stdout()，但在stdout中，一般指定为 rubydebug 为解码方式，这样输出的格式比较友好，方便debug.
  * 示例: output { stdout { codec => rubydebug } }

##### 安装ElasticSearch

```
apt-get install apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen -y
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://packages.elastic.co/elasticsearch/5.x/debian stable main" | tee -a /etc/apt/sources.list.d/elasticsearch-5.x.list
apt-get update && apt-get install elasticsearch
sed -i s/#cluster.name:.*/cluster.name:\ grafana/ /etc/elasticsearch/elasticsearch.yml
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service
```

##### 安装Grafana

```
wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_4.5.1_amd64.deb
sudo apt-get install -y adduser libfontconfig
sudo dpkg -i grafana_4.5.1_amd64.deb
sudo service grafana-server start
```

默认情况下，上述安装的grafana监听在0.0.0.0:3000端口上，默认用户名密码存放在/etc/grafana/grafana.ini文件中，如果该文件中没有指定，则用户名和密码均为admin


启动logstash服务，然后打开Grafana，添加ElasticSearch作为数据源，然后就可以创建dashboard了.

```
sudo systemctl start logstash
```

##### 配置Grafana 数据源

添加Grafana数据源的时候，可直接选择与ElasticSearch集成，url输入http://localhost:9200，Access方式可以选择为proxy，这个代表 Grafana去查询ES，如果选择Direct，则代表浏览器直接查询ES. index名字选择为nsg-flow-logs，Time field name选择 @timestamp，Version为5.x


##### 配置Grafana Dashboard

在Grafana Dashboard中有General, Metrics, Axes, Legend, Display, Alert, Time range几个选项卡，比较重要的有 Metrics, Axes, Legend, Display   

* Metric 

根据不同的数据源，Metric界面的显示是不同的。以本次实验的ElasticSearch数据为例，在Query中可以直接执行Lucene Query，如不想查某一个IP，可以输入 "Not destIp: 10.21.1.208"  
Group by 可以先按 Terms destIp.keyword 进行Group by，如果要选择前10个最多的destIp，那么Order选择为Top，Size为10  
Then By一般以Date Histogram @timestamp来聚合。

* Axes

Left Y 为左侧的Y轴定义，Unit一般为short，Scale 为liner  
Right Y为右侧的Y轴定义。如果想要将一个数据放到右侧Y轴，那么需要现在Legend中，Options中勾选show，也可以再勾选 "AsTable"，之后点击下面的数字前面的颜色，就可以为这个数据选择颜色以及Y轴
X-Axis 也很重要，决定了数据聚合的方法，Mode选择Series则按照之前定义的Terms destIp.keyword进行聚合，Value设置为total.

* Legend

可以将数据X轴的标签单独显示出来，也可以统计出每一个标签的最小值、最大值、平均值、统计值等。

* Display

这个很重要，默认图表是线line，如果想要改成柱状图，则修改为Bars。





参考文档：https://docs.microsoft.com/zh-cn/azure/network-watcher/network-watcher-read-nsg-flow-logs