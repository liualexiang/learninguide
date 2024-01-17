# jq

jq 和 AWS CLI 都是使用 JMESPATH 语法进行查询，但是内置的一些函数是不一样的，因此查询语法上也略有差异



## 变量的处理

在jq的查询中，单引号不会进行shell的变量替换，双引号会引用linux shell的变量。比如当查询的结果里有 CombinName 的变量的时候，想要让 jq 能解析这个变量，可以用下面的方法

```shell
aws appconfig list-applications --region ${aws_region} --query "Items[*]" --output json | jq ".[] | select(.Name == \"${CombineName}-Application\") | .Id"
```

如果我们使用单引号，则没法处理这个变量，此时可以通过 --arg 给 jq 注入一个变量，然后jq的 select 函数使用注入的变量

```shell
aws appconfig list-applications --region ${aws_region} --query "Items[*]" --output json | jq -r --arg appconfig_name "${CombineName}-Application" '.[] | select(.Name == $appconfig_name) | .Id'
```



## 属性过滤

在 jq 中，如果要查找某一个匹配的值，并将其他属性显示出来，可以通过 select() 函数对其进行过滤

```shell
aws elbv2 describe-load-balancers | jq '.LoadBalancers[] | select(.Scheme == "internet-facing") | .LoadBalancerName'
```



https://lzone.de/cheat-sheet/jq