# ES Search 和 Query常用语句

## ES 查询

下面有三个查询，在多数情况下是等效的，都是表达要查询 message字段里包含 device risk detected 的内容。但 query_string支持通配符和正则，match_phrase不支持。

```
查询一
"query_string": {
   "query": "message: \"device risk detected\"",
   "default_field": "*",
}

查询二
"query_string": {
   "query": "\"device risk detected\"",
   "default_field": "message",
}

查询三
"match_phrase": {
   "message" {
      "query": "device risk detected
      }
}
```





## 示例

1. 搜索特定的@log_group 字段，以及 @message中包含403的
```
GET _search
{
  "query": { 
    "bool": { 
      "must": [
        { "match": { "@message": "403" }},
        { "match": { "@log_group.keyword": "/this-is-nginx-index" }},
        { "range": {
                    "@timestamp": {
                        "gte": "now-1m",
                         "lt": "now"
                    }
            }
        }
      ]
    }
  },
  "highlight": {
    "fields": {
      "@message": {},
      "@log_group.keyword": {}
    }
}
}
```

2. ES 在查询的时候，上述用的是 match，如果是 "403 404 405"，那么只要搜到任何一个，就会返回。如果想精确匹配，比如 "/api/v1/test" 这个，而不是说只要搜到 "api"或者"v1"或者"test"，那么要用 match_phrase。示例:

   ```
   {
               "query": {
                   "bool": {
                       "must":
                           [
                               {
                                   "match_phrase": {
                                       "message": "/api/v1/test"
                                   }
                               },
                               {
                                   "range": {
                                       "@timestamp": {
                                           "gte": "now-60m",
                                           "lt": "now"
                                       }
                                   }
                               }
                           ]
                   }
               },
               "_source": ["@timestamp", "message"],
               "sort": [
                   {
                       "@timestamp": "desc"
                   }
               ],
               "size": 10000
           }
   ```

   