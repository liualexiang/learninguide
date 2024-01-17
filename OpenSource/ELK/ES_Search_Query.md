# ES Search 和 Query常用语句

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