# jq

jq 和 AWS CLI 都是使用 JMESPATH 语法进行查询，但是内置的一些函数是不一样的，因此查询语法上也略有差异


## 添加字段
可以用 += 添加字段
```shell
echo '{"a":{"b":"c"}}' | jq '.a+={"d":3}'
```
如果是对一个已存在的字段进行 += 操作，则会更新这个字段
```shell
echo '{"a":{"b":"c"}}' | jq '.a+={"b":3}'
```
如果有变量，jq 后面使用单引号的时候，要用 --arg 将变量从操作系统里，传递给 jq，才能识别到
```shell
export NUM=4
echo '{"a":{"b":"c"}}' | jq --arg num ${NUM} '.a+={"d":$num}'
```

不过需要注意，上述示例，在 --arg 的时候，shell 里的 NUM 传递给jq 的 num的时候，变量值 4 就变成了字符串，如果想要变成数字，需要用 tonumber 函数，示例
```shell
export NUM=4
echo '{"a":{"b":"c"}}' | jq --arg num ${NUM} '.a+={"d":($num | tonumber)}'
```

如果想要直接用shell里的变量，不做传递，那么 jq 后面要用双引号，此时注意可能要做转义。这个示例中，由于 shell里定义的 NUM 是数值型，所以jq生成的json文档，也是数值型
```shell
 export NUM=4
 echo '{"a":{"b":"c"}}' | jq ".a+={\"d\":$NUM}"
```



## 属性过滤

在 jq 中，如果要查找某一个匹配的值，并将其他属性显示出来，可以通过 select() 函数对其进行过滤

```shell
aws elbv2 describe-load-balancers | jq '.LoadBalancers[] | select(.Scheme == "internet-facing") | .LoadBalancerName'
```



https://lzone.de/cheat-sheet/jq