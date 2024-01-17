# Cloud Custodian 

c7n 支持几种模式，比如直接在本机执行，基于资源进行扫描，基于cloudtrail进行扫描，或者跟 aws 的config集成。在执行的时候，也能通过 action 直接对资源进行修复操作，如删除，或者发通知到slack等


## schema 检查

```
custodian schema aws.security-group.filters.ingress
```



## 检查安全组的示例

```
policies:
  - name: security-groups-with-test-description
    resource: security-group
    filters:
      - or:
        - type: ingress
          Description:
            value: "test"
            op: contains
        - type: ingress
          Description:
            value: "manual"
            op: contains
        - type: ingress
          Description:
            value: "manually"
            op: contains
            
```

执行

```
custodian run -s output sg-with-test.yaml --cache-period 0
custodian report -s output sg-with-test.yaml --format grid
```

注意上面的type是 ingress，如果 c7n 没有针对这个类型做处理的话，也可以通过对 type: value 对value进行过滤处理，value里的内容格式可以在 output/resources.json 里查看

上面的检查安全组的示例，也可以用这种方法

```
policies:
  - name: security-groups-with-test-description
    resource: aws.security-group
    filters:
      - type: list-item
        key: IpPermissions[].UserIdGroupPairs[]
        attrs:
          - type: value
            key: Description
            op: contains
            value: "test"
```

之所以不直接使用 type: value的过滤器，而使用 ingress 或 list-item 过滤器，是因为type:value 对安全组的 IpPermissions[].UserIdGroupPairs[] 过滤之后，拿到的返回值是一个 list，而list里不能使用 contains 搜索test，contains只支持 string这类数据类型



