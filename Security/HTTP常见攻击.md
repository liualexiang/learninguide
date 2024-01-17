# HTTP 常见攻击

## XSS 攻击

XSS 攻击，目前已经不再单纯的是跨站攻击了。一般指的是黑客将 恶意代码(js)，植入到网页里，当用户访问正常的页面，客户的浏览器就会执行黑客的代码(比如收集cookie，将cookie发送到某一个地方)

* 反射型
  * 比如将 ```<script>alert(''xx")</script>``` 的标签放到url里，然后创建短链接，别人拿到连接，就能执行这个代码
* 存储型
  * 比如在论坛聊天等文本窗口，将恶意代码，提交到服务器上，服务器如果没做过滤，就保存到了数据库里。以后任何人访问这个页面，都会执行恶意代码
* DOM型
  * 对于一些url，比如 https://gitbook.aiaod.com/opensource/git/git_basic#git-rebase-ya-suo-commit，url地址后面有一个 #，其实指的是浏览器在第一次请求的时候，就已经拿到了前面的所有数据，然后通过#后面的变量，来动态的加载资源，这样能够减少浏览器跟服务器之间的交互次数，提高效率。但是浏览器的js脚本，在解析#的时候，可能就会直接执行#后面的脚本内容，通过这种方式攻击，就是DOM类型攻击
* 



## SSRF 攻击

如果一个API请求，请求体里要求传一个 URL 地址，然后 server 会向这个地址发起请求，并且将response发给请求方，那么此时很有可能会出现 SSRF 漏洞。

比如：服务是部署到AWS EC2，那么请求题里的 URL地址可以输入 http://169.254.169.254/meta-data/ 的地址，这样本来EC2内部的地址不能被公网访问到，但用户通过这类方法，就有可能拿到 EC2 Role的AK SK 和Token. 强制使用 IMDSv2 的metadata，能够在一定程度上防范 SSRF 攻击，因为 IMDSv2 需要先拿到token，再通过token换取 ak sk，因此有助于降低泄漏的风险

参考资料：https://www.acunetix.com/blog/articles/server-side-request-forgery-vulnerability/

