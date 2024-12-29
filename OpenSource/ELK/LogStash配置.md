# LogStash 配置

## 插件安装

```
./logstash-plugin list
./logstash-plugin install logstash-input-azureblob
```

## 有关Logstash的配置解读

* Logstash 数据处理的三大步骤: Input --> Filter --> Output

* 如果logstash要处理多个业务的数据，可以用 logstash pipeline，每一个业务放到单独的pipeline文件夹下，一个pipeline文件夹一般只有一个input，output一般也只1个（当然如果业务想写到多个地方，也可以配置多个）。同一个业务里，如果有不同的服务，可以用不同的文件来处理 filter里的逻辑，然后将 add_field 加上一个字段表示这个服务

  

## filter Grok的示例

下面 filter Grok的示例中，其中第一部分 ?<api_path>\/api\/v1\/\S+) 表示的是使用正则进行处理，正则判断的是 /api/v1/xxx的这种路径，并将搜索到的结果保存到 api_path 中，这个结果可以再 output 中，通过 "%{[api_path]}" 的方式进行引用。

%{WORD} 是使用 grok 里的WORD pattern进行查找； BASE10NUM则是搜索数字，后面的:int指的是将数据类型转换为 int，默认是string类型（常用的还有 float, boolean, epoch，一共仅此4种）；NUMBER是在BASE10NUM 搜索的基础上，再加上对科学计数法的支持；最后的 (?\<unit\>(s|ms|us)) 指的是将 s 或者 ms，或者us 保存到 unit里

再if 语句后面有一个 else {} 表示，如果grok匹配不到，则删除

最后if _grokparsefailure 指的是，对于 grok匹配不到的数据，一般会加上这个tag，然后依然保留这个数据，我们通过将这些数据删除，能确保后续处理的数据，一定是grok 匹配到的

```

filter {
  if "/my-log-group" in [logGroup] {
    grok {
      match => {
          "message" => "(?<api_path>\/api\/v1\/\S+) %{WORD} %{BASE10NUM:code:int} %{NUMBER:duration}(?<unit>(s|ms|us))"
      }
    }
  }
else {
  drop {}
  }
if "_grokparsefailure" in [tags] {
  drop {}
  }
}

```

不过在上述的示例种，也不免发现，由于时间单位，既有秒，又有毫秒，还有微秒，我们在存储的时候，希望时间统一。此时最好的办法是让开发写日志的时候统一起来。如果开发没有处理，我们也可以通过嵌入ruby脚本来完成。比如:

```
filter {
  if "/my-log-group" in [logGroup] {
    grok {
      match => {
        "message" => "(?<api_path>\/api\/v1\/\S+) %{WORD} %{BASE10NUM:code:int} %{NUMBER:duration}(?<unit>(s|ms|us))"
      }
    }
    ruby {
      init => "
        def to_milliseconds(value, unit)
          case unit
          when 'ms'
            value
          when 's'
            value * 1_000
          when 'us'
            value / 1_000.0
          else
            value
          end
        end
      "
      code => "event.set('duration', to_milliseconds(event.get('duration').to_f, event.get('unit')))"
    }
  } else {
    drop {}
  }
  
if "_grokparsefailure" in [tags] {
  drop{}
  }
}
```





## 解读Filter常用部分，也是对logstash配置的关键部分
* 在filter里，一般可以用 json { source => "message"} 来对 message字段进行展开。如果 message是一个list，想要对list展开，则要用 split
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

参考文档：https://docs.microsoft.com/zh-cn/azure/network-watcher/network-watcher-read-nsg-flow-logs