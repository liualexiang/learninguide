## tools
nvm 管理nodejs 版本和npm
```shell
nvm install 18.20.3
nvm use 18.20.3
nvm current
```

## nodejs 语法
### map,reduce与filter

比如有下面的一个数据结构，注意此时是数组里存一个字典，想要做一些处理
```javascript
userinfo=[{"name":"alex","age":35},{"name":"jack","age":36},{"name":"edward","age":41}]

# 过滤出年龄小于40的
userinfo.filter(user => user.age < 40)

```
但如果是一个字典结构的对象，则需要先用 Object.entries读取每一个条目，然后再对条目里的value进行过滤，之后再使用 reduce方法，写入到字典里（如果没有用reduce，或者使用reduce的时候，没有指定初始值位{}，则最终输出的是一个数组）。

```javascript
userinfo={"alex":34, "jack":35, "edward":40}
UserInfo=Object.entries(userinfo)
 
UserInfo.filter(([key,value]) => value < 40).reduce((obj,[key, value])=>{obj[key]=value; return obj;},{})
```


