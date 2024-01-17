### Azure VM抓包说明
* [internal_vm.pcap](internal_vm.pcap) 是一个纯内网的VM，没有public IP
* [nginx_server.pcap](nginx_server.pcap) 是一个公网VM，其公网IP为 52.247.123.17

### 抓包解读

* 测试一：在公网VM上部署nginx，然后纯内网VM访问并抓包：
internal vm在数据包No.4 发起了一个GET请求，nginx_server.pcap在数据包No. 12收到了这个GET请求。

观察这两个GET请求的TCP seq number 以及TCP timestamp(在TCP Option字段中)，可以断定这两个数据包为同一个。

由此可见，Azure VM默认情况下，内网的VM是通过NAT的方式访问互联网，而并非通过HTTP 7层代理。

* 测试二：在公网VM上将nginx建通端口改为88
同时也测试了将外网的web端口改为88，也依然能从纯内网的VM上访问到。

* 测试三：在公网VM上使用nc -u -l 880来侦听UDP流量，然后在纯内网的VM上使用nc -u 连接，然后发UDP数据包，也能收到。

* 测试四：在公网VM的防火墙上开启ICMP流量，在自身ping自己的公网IP，可以ping通，但是在纯内网VM上ping公网VM，无法ping通。

### 结论：
默认只对TCP和UDP做了NAT，没有对ICMP做NAT，所以ping不通。查阅Azure官方文档，是因为默认情况下Azure会对没有公网IP的VM做SNAT。文档参考：
https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#defaultsnat


