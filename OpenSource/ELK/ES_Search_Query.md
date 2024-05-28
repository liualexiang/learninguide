# ES Search 和 Query常用语句





## 全文文本查询

match 

match_bool_prefix

match_phrase

match_phrase_prefix

combined_fields

multi_match

query_string

simple_query_string

term ## 注意，这个不适用于 text类型的文档字段，一般用于 keyword 或者 number类型等



## ES 查询

### query_string ， match_phrase 和 match

下面有三个查询，在多数情况下是等效的，都是表达要查询 message字段里包含 device risk detected 的内容。但 query_string支持通配符和正则，match_phrase不支持。默认Kibana上的kibana query language就是 query_string

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
      "query": "device risk detected"
      }
}
```



再看一个示例

```
查询一
GET /_search
{
  "query": {
    "match": {
      "user.id": {
        "query":  "\"kit cat\""
      }
    }
  }
}

查询二
GET /_search
{
  "query": {
    "query_string": {
      "user.id": {
        "query":  "\"kit cat\""
      }
    }
  }
}


查询三

GET /_search
{
  "query": {
    "match_phrase": {
      "user.id": {
        "query":  "kit cat"
      }
    }
  }
}

查询二和查询三是一样的，但查询一是不一样的，因为查询一会查询包含引号(即查到的是"kit cat"包含引号)，但查询二和三包含的是 kit cat 这两个单词，且单词之间有一个空格

```



### 查询中是否加 query

下面的查询一与二（三与四）查询也是等价的。不过查询二和查询四能支持更多的参数，如 analyzer，slop，operator, fuzziness等

```
查询一
{
  "match_phrase": {
    "message": "inspect balance redundancy fail, devices not enough"
  }
}

查询二
{
  "match_phrase": {
    "message": {
      "query":  "inspect balance redundancy fail, devices not enough"
    }
  }
}

查询三
{
  "match": {
    "id": "0c5j1p6h6dzr"
  }
}

查询四
{
  "match": {
    "id": {
      "query": "0c5j1p6h6dzr"
    }
  }
}
```





### multi_match,query_string,match与 match_phrase对比

下面四个查询，multi_match 可以指定多个字段，也可以不指定，不指定的时候则搜索所有字段，同时multi_match 还支持 type，不同的字段，可以用不同的type，比如有一个字段使用 best_fields，另外一个字段使用 match_phrase (type为phrase)

query_string 可以指定字段，也可以不指定，不指定就搜所有，还支持正则和通配符，是最灵活的。

match 则必须指定字段，且默认会做分词，只要搜到一个词，就匹配成功

match_phrase 则要求搜索的和输入的完全一致，包括特殊字符，它强调的是精确匹配。



```
查询一
{
  "multi_match": {
    "type": "phrase",
    "query": "0c5j1p6h6dzr",
    "lenient": true
  }
}

查询二
{
  "query_string": {
    "query": "0c5j1p6h6dzr"
  }
}
查询三
{
  "match": {
    "id": "0c5j1p6h6dzr"
  }
}
查询四
{
  "match_phrase": {
    "id": {
    "query": "0c5j1p6h6dzr"
    }
  }
}
```



#### query

match默认会做分词，也就是说，如果有空格，则只要搜到任意一个单词，即返回。如果想要让每一个都能返回，就要加 operator 参数为 AND，但是此时指的是这个document里，只要有这几个单词就会返回，这几个单词可以不在一起，如果想要精确匹配，则应该用 match_phrase。示例

```
需要包含 this is a test的每一个单词，但是这几个单词可以顺序是乱的
GET /_search
{
  "query": {
    "match": {
      "field_name": {
        "query": "this is a test",
        "operator": "AND"
      }
    }
  }
}

如果精确匹配，则用 match_phrase
GET /_search
{
  "query": {
    "match_phrase": {
      "field_name": "this is a test"
    }
  }
}
```



#### fuzzy query

ES 可以支持模糊查询，这个是通过编辑距离来计算的，比如 box 不小心写成了 fox, sick 写成了 sic 等。fuzzy query可以帮助解决这些问题.

```
GET /_search
{
  "query": {
    "fuzzy": {
      "user.id": {
        "value": "ki"
      }
    }
  }
}
```

注意必须按上面的格式写，不能给 field 直接传一个value，比如不能写成 "user.id": "ki"。这是因为 field 下面需要接收一个对象，我们可以在对象里指定更多的参数，比如 fuzziness等。下面我们用比较熟悉的 match 做示例

```
GET /_search
{
  "query": {
    "match": {
      "user.id": {
        "query": "ki",
        "fuzziness": "AUTO"
      }
    }
  }
}
```

由于 fuzzy query 是对字段进行模糊查询，因此是需要分析这个字段的，所以像 term 之类的搜索，是没办法用 fuzzy query的。另外，像 match_phrase用于查找包含精确短语的内容，是对词的顺序敏感的，而 fuzzy查询的本质却是模糊复合词的匹配，因此 match_phrase也不支持 fuzzy query

但其他的诸如 match, muti_match, query_string,等，都支持 fuzzy query

#### wildcard query

如果我们知道了要搜索的文本的匹配格式，我们也可以用 wildcard query得方式

```
{
    "query": {
        "wildcard" : { "user" : "ki*y" }
    }
}
```





#### term 与 terms

term 是做精确查询的，一定不要用于 text类型的字段上，一般建议是 keyword或者number。term的精确查找，包括大小写，空格等，字段值必须完全和搜索的一致，适合搜索用户名，订单数量等信息。它跟 match_phrase不同的是，match_phrase只要对文档中能满足搜索条件，则会返回成功，比如下面一个示例，field 的值是 this is a test, hahaha，下第一个查不到，第二个能查到

```
   GET /_search
    {
        "query": {
            "term": {
                "field.keyword": "this is a test"
            }
        }
    }


    GET /_search
    {
        "query": {
            "match_phrase": {
                "field": "this is a test"
            }
        }
    }
```

如果我们想要搜的结果，可能是多个，比如 username可能是 alex，也可能是 jack，则要用 terms

```
GET /_search
{
    "query": {
        "terms": {
            "username.keyword": ["alex", "jack"]
        }
    }
}
```



### 查询优化

一般建议，如果能用 term, match, range的情况下，优先使用 term match，这个效率比 query_string 要高。同样 fuzzy 和 wildcard 效率也比较低。

总的来说，term最高效，其次是 match 和 range，query_string, fuzzy, wildcard 不一定，要具体分析。有时候业务需要，必须使用 query_string, wildcard 或fuzzy，此时也可以通过合理的分词器和分析器，调整索引设置，限制查询范围等方式进行优化.



## 常见查询参数

这些参数是 Elasticsearch 查询时的常见参数，不过并非所有的查询类型都支持所有的参数。这些参数的用途范围如下：

- `analyzer`：指定要用于该查询的分析器。

- `boost`：设置特定查询的权重，值大于 1.0 的查询条件，反馈的结果相关度会更高，值小于 1.0 的查询条件，结果的相关度会降低。

- `operator`：定义多个查询词之间的逻辑关系，可选值包括`AND`和`OR`。

- `minimum_should_match`：定义布尔查询中的`should`子句必须匹配的最少数量。

- `fuzziness`：在`match`查询中，在匹配时允许的最大编辑距离。

- `lenient`：是否应忽略格式错误并爬取尽可能多的结果，比如 number类型的，使用string类型也能搜到

- `prefix_length`：指定模糊查询时，需要完全匹配的字符前缀长度。

- `max_expansions`：为了改善性能，`auto_generate_synonyms_phrase_query` 查询只会返回前 N 个扩展。

- `fuzzy_rewrite`：指定重写方法，提高模糊查询和前缀查询的性能。

- `zero_terms_query`：如果在分析查询文本后没有词条，则此选项控制查询的行为。

- `auto_generate_synonyms_phrase_query`：当为`true`时，匹配同义词短语查询会自动生成。

- `fuzzy_transpositions`：是否模糊查询应计算并包含字符转置。





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

   