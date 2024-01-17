#### ElasticSearch的基础配置

#####  使用ingest-geoip处理IP

ES 默认没有对IP地址的支持，但有时候我们需要通过IP地址做地图上的可视化展示，就需要利用额外的插件做这件事情，需要手动在ES的所有节点上来安装插件, ES的[geoip](https://www.elastic.co/guide/en/elasticsearch/plugins/5.3/ingest-geoip.html)插件是利用了[GeoLite2](http://dev.maxmind.com/geoip/geoip2/geolite2/)的免费的数据库实现的(这个插件下载了GEOIP2的Country和City这两个离线数据库)  
```
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-geoip
```

不过Logstash默认是安装了GEOIP的插件，可以查看下  

```
alex@nsglogs:/usr/share/logstash/bin$ ./logstash-plugin list | grep geoip
logstash-filter-geoip
```

我们可以使用Logstash自带的数据库，位置为：/usr/share/logstash/vendor/bundle/jruby/2.5.0/gems/logstash-filter-geoip-6.0.3-java/vendor，如果想要更新数据库，也可以自行下载GeoLite2数据库文件，并将其放在/usr/share/logstash/data/路径下（也可以是其他路径）  

```
alex@nsglogs:~$ ls /usr/share/logstash/data/
GeoLite2-City.mmdb  
```
注意：现在哪怕是下载GeoLite2也要注册Maxmind账号才能下载了，之前可以直接下载.

在logstash.conf文件中，filter分区中指定对ip地址的处理，下面的示例是将GeoIp的信息放在 geoip.coordinates这个list中

```
   geoip {
     source => "srcIp"
     database => "/usr/share/logstash/data/GeoLite2-City.mmdb"
     add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
     add_field => add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}" ]
  }
```

使用logstash的GeoIP插件处理IP地址的一个最简单的示例，将其保存为 test.conf ，然后加载这个配置文件 ./logstash -f test.conf，加载成功之后，在控制台输入某个ip，如1.1.1.1，则会成功返回IP所在的坐标位置.之所以用remove_field，是因为默认情况下，GeoIP会将与ip地址相关的属性全部都显示出来。 对于测试的test.conf文件，可以在启动logstash的时候，加上 -f 参数指定。如：    
```
root@nsglogs:/usr/share/logstash/bin# ./logstash -f test.conf
``` 

测试用的 test.conf 内容如下:   
```
input {
  stdin{}
}
filter {
   grok {
    match => {"message" => "%{IP:srcIp}"}
  }
   geoip {
    source => "srcIp"
    database => "/usr/share/logstash/data/GeoLite2-City.mmdb"
    target => "geoip"
    add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
    add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}" ]

    remove_field => ["[geoip][city_name]","[geoip][timezone]","[geoip][ip]","[geoip][latitude]","[geoip][country_code2]","[geoip][country_name]","[geoip][continent_code]","[geoip][country_code3]","[geoip][region_name]","[geoip][longitude]","[geoip][region_code]"]
  }
  mutate {
     convert => [ "[geoip][coordinates]", "float" ]
  }

}
output{
  stdout{
    codec => rubydebug
  }
  elasticsearch {
     hosts => "localhost"
     index => "test-ip"
   }
}
```

##### 在Kibana 地图中展示GeoIP位置

通过上面的方法，虽然在查询的时候可以查到ip的属性信息，但是默认情况下，对于经纬度坐标的保存数据是float/number类型的，这种类型没有办法查询指定范围内的数据(比如要查询某个坐标周围1km的距离内有多少数据)，同时在kibana的地图中，也无法直接展示。如果要利用ES的GeoIP的功能，那么需要将数据类型设置为[geo_point](https://www.elastic.co/guide/en/elasticsearch/reference/2.3/geo-point.html)类型.   

为测试方便，我们先创建一个 test-ip的[索引](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html)(由于直接定义比较复杂，可以先按logstash生成一个索引，通过 GET _cat/indices获得索引名，然后GET /test-ip获得索引的详情，找到里面mapping的设置情况，将GeoIP的数据类型设置为 geo_point)   

* test.conf 内容如下   
```
input {
  stdin{}
}
filter {
   grok {
    match => {"message" => "%{IP:srcIp}"}
  }
   geoip {
     source => "srcIp"
     database => "/usr/share/logstash/data/GeoLite2-City.mmdb"
     target => "geoip"
    fields => ["longitude","latitude"]
    add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
    add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}" ]
 }
mutate {
     convert => [ "[geoip][coordinates]", "float" ]
  }
}
output{
  stdout{
    codec => rubydebug
  }
 elasticsearch {
     hosts => "localhost"
     index => "test-ip"
   }
}
```

* 创建索引语句如下:
```
PUT /test-ip
{
  "mappings": {
    "logs": {
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "@version": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "geoip": {
          "properties": {
            "coordinates": {
              "type": "geo_point"
            },
            "latitude": {
              "type": "float"
            },
            "longitude": {
              "type": "float"
            }
          }
        },
        "host": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "message": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "srcIp": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        }
      }
    }
  }
}
```

完成上述操作之后，在Kibana的索引里面，可以搜索一下geoip.coordinates，会发现其类型已经是 geo_points，然后创建一个Tile map，就能在地图上展示数据了。


##### 分析Nginx access的示例

* 注意：在Ubuntu 18.04系统下测试，logstash默认启动用户是logstash，没有权限访问nginx的日志目录/var/log/nginx，默认这个日志目录的用户是 www-data，组是 adm，可以将logstash用户加到adm组中 usermod -a -G adm logstash。检查是否添加成功命令： cat /etc/group | grep adm
```
filter {
  grok {
    match => {"message" => "%{COMBINEDAPACHELOG}"}
  }
  geoip {
    source => "clientip"
    database => "/usr/data/geolite2/GeoLite2-City.mmdb"
    fields => ["region_name"]
  }
  useragent {
    source => "agent"
  }
}
```

fields里面指定的region_name其实是中国的省份，这样在Kibana map中展示的时候，可以根据省份来展示数据。

##### 使用if来判断，决定是否添加字段

示例
```
input {
 stdin{codec => "json"}
}
 filter {
   split { field => "[request_http_headers]"}
  if [request_http_headers][transaction-id] {
     mutate {
      add_field => {"xxxxx" => "%{[request_http_headers][transaction-id]}"}
    }
  }
  else if [request_http_headers][raj] {
    mutate {
      add_field => {"yyyyy" => "%{[request_http_headers][raj]}"}
    }
  }
}
```

测试数据

```
{ "request_http_headers": [ { "transaction-id": "1234" }, {"raj" : "test"} ] }
```


##### 附录1：几个常用的ES命令

```
GET _cat/indices
GET /test-ip
GET /test-ip/_search
DELETE /test-ip

PUT /test-ip
{
  "mappings": {
    "logs": {
      "properties": {
        "srcIp": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        }
      }
    }
  }
}
```


##### 附录2：将Azure NSG Logs的srcIp在Logstash地图上展示示例
有关NSG Logs的分析，请查看"部署Logstash_ElasticSearch_Grafana分析Azure_NSG日志示例.md"这篇文档，标题为"使用开源方案来分析Azure NSG flow log"

创建的索引文件内容   
```
PUT /nsg-flow-logs
{
      "mappings": {
      "logs": {
        "properties": {
          "@timestamp": {
            "type": "date"
          },
          "@version": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "NetworkSecurityGroup": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "ResourceGroup": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "Subscription": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "Version": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "bytesSentDestToSource": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "bytesSentSourceToDest": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "category": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "destIp": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "destPort": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "flowstate": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "geoip": {
            "properties": {
              "coordinates": {
                "type": "geo_point"
              },
              "dma_code": {
                "type": "long"
              },
              "location": {
                "type": "float"
              },
              "postal_code": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword",
                    "ignore_above": 256
                  }
                }
              }
            }
          },
          "mac": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "message": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "operationName": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "packetsDestToSource": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "packetsSourceToDest": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "protocol": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "records": {
            "properties": {
              "category": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword",
                    "ignore_above": 256
                  }
                }
              },
              "macAddress": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword",
                    "ignore_above": 256
                  }
                }
              },
              "operationName": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword",
                    "ignore_above": 256
                  }
                }
              },
              "properties": {
                "properties": {
                  "Version": {
                    "type": "long"
                  },
                  "flows": {
                    "properties": {
                      "flows": {
                        "properties": {
                          "flowTuples": {
                            "type": "text",
                            "fields": {
                              "keyword": {
                                "type": "keyword",
                                "ignore_above": 256
                              }
                            }
                          },
                          "mac": {
                            "type": "text",
                            "fields": {
                              "keyword": {
                                "type": "keyword",
                                "ignore_above": 256
                              }
                            }
                          }
                        }
                      },
                      "rule": {
                        "type": "text",
                        "fields": {
                          "keyword": {
                            "type": "keyword",
                            "ignore_above": 256
                          }
                        }
                      }
                    }
                  }
                }
              },
              "resourceId": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword",
                    "ignore_above": 256
                  }
                }
              },
              "systemId": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword",
                    "ignore_above": 256
                  }
                }
              },
              "time": {
                "type": "date"
              }
            }
          },
          "resourceId": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "rule": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "srcIp": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "srcPort": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "systemId": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "tags": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "time": {
            "type": "date"
          },
          "traffic": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "trafficflow": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "unixtimestamp": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          }
        }
      }
    },
    "settings": {
      "index": {
        "number_of_shards": "5",
        "number_of_replicas": "1"
      }
    }
  
}
```

Logstash内容为：
```
input {
   azureblob
   {
     storage_account_name => "xiangliu"
     storage_access_key => STORATE_ACCOUNT_ACCESS_KEY
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

   geoip {
     source => "srcIp"
     database => "/usr/share/logstash/data/GeoLite2-City.mmdb"
     target => "geoip"
add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
      add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}" ]
     remove_field => ["[geoip][city_name]","[geoip][timezone]","[geoip][ip]","[geoip][latitude]","[geoip][country_code2]","[geoip][country_name]","[geoip][continent_code]","[geoip][country_code3]","[geoip][region_name]","[geoip][longitude]","[geoip][region_code]"]
  }
  mutate {
     convert => [ "[geoip][coordinates]" , "float" ]
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