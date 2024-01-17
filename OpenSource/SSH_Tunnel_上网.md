# SSH Tunnel



## 配置SSH Tunnel访问网站

### 快速配置ssh tunnel
在国外开一个虚拟机，然后在终端中打开SSH Tunnel

```shell
ssh -ND 8898 -i key.pem ec2-user@ip
```

这样相当于在127.0.0.1:8898开启了SOCKS5的代理，可以在浏览器或者操作系统中设置SOCKS代理，就可以上网了。

### 智能浏览的配置
如果要实现智能上网，那么还需要一个PAC文件，PAC文件中包含有一些需要加速的网站，网站列表可以从此处获得：https://github.com/gfwlist/gfwlist .
下载这个raw文件就可以了： https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt

然后利用gfwlist2pac工具将gfwlist.txt生成pac文件
pip install gfwlist2pac

gfwlist2pac -i gfwlist.txt -f gfw.pac -p “SOCKS5 127.0.0.1:8898;”

之后在当前目录生成了 gfw.pac，使用文本工具打开，在网站中移除 amazon.com 域名(否则访问公司内部系统会出问题)，同时在修改 var proxy 为var proxy = "SOCKS5 127.0.0.1:8898; DIRECT"; 这里添加的DIRECT主要是做高可用，当本地的127.0.0.1:8898不可用时，就会直接访问互联网，以免由于SSH Tunnel故障导致无法上网。

### 浏览器插件
Google Chrome浏览器安装SwitchyOmega插件，然后新建一个Profile，将PAC Script内容添加进去。之后测试一下就可以上网了。

### MacOS X全局代理的配置
如果要配置操作系统全局代理，那么需要在MAC上开启apache服务(MacOS不支持local PAC文件，所以需要用apache来host这个文件，坑啊！！！)
sudo apachectl start/restart
然后访问 http://localhost 会看到It Works！
之后将gfw.pac拷贝到 /Library/WebServer/Documents
在Mac操作系统配置代理处选择 Automatic Proxy Configuration，地址输入 http://localhost/gfw.pac

再次试试，就能发现可以访问谷歌和内部系统啦！

配置开机自动脚本，开机自动运行下面的代码即可（PAC配置可以一直挂着，毕竟配置了proxy和Direct的高可用，哈哈）
nohup ssh -ND 8898 -i key.pem ec2-user@ip &

大功告成！



## 访问远程主机的端口

在 ssh的时候，使用 -L 可以将远程主机的端口，映射到本地，这样本地浏览器就能访问到远程主机上某个端口的服务

```shell
ssh -i key.pem -L 15000:127.0.0.1:15000 user@remote_ip
```





