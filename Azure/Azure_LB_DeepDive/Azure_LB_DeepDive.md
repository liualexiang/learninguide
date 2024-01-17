# Azure LB Deep Dive

## 有关LB底层设计原理
Azure LB 不管什么模式，永远都是DSR(Direct Server Response)模式，具体说明如下：

* 进来流量  
Client --> LB --> 一组MUX形成一个ring --> 物理机Hyper-V --> Virtual Switch --> VFP (Virtual Filter Platform) --> Azure VM 

* 出去流量  
Azure VM --> VFP --> Internet

* 上述概念说明   

  * MUX 是做五元组hash的，能决定将流量发给哪个物理机。
  * 只有在进来的时候，流量才经过MUX，出去的时候不经过MUX。 
  * 对于Internal LB，只有第一次五元组的时候，流量经过MUX，以后VFP会cache住这个记录，VM间通信不再经过VFP

## Float IP 的解释

azure LB FloatIP启用之后，在后端的VM上，抓包看到的IP是负载均衡器的IP（这也就是为何要将负载均衡器的FrontIP配置到VM的loopback上）。如果不启用，则抓包看到的IP是当前VM的IP。除了在Azure Portal上启用Float IP之外，还要在Azure VM上将LB IP添加到系统的回环地址上  

* linux 在loopback上添加ip的命令：  
``` sudo ip addr add 20.55.205.90 dev lo```

* 在Windows系统下，可以新建一个loopback的网卡，也可以在现有的lookback网卡上操作
  * 新建loopback网卡：
    * 打开设备管理器，然后鼠标点中最上面的计算机名字，然后点击Action-->Add lagency hardware-->下一步-->Install the hardware that I manually select from a list(Advanced)--> Network Adapter --> Microsoft (Microsoft KM-TEST Loopback Adapter) --> Next。 新建网卡之后，在这个Loopback网卡上设置一下LoadBalancer的IP地址，子网掩码为255.255.255.255，网关和DNS为空。保存。
    * 执行 netsh int ipv4 show config 命令，查看loopback网卡名字，如名字为"Ethernet 3"，然后执行
      * netsh interface ipv4 set interface "Ethernet 3" weakhostreceive=enabled
      * netsh interface ipv4 set interface "Ethernet 3" weakhostsend=enabled
  * 使用现有loopback网卡
    * 执行 netsh int ipv4 show config，查看loopback网卡名字，如名字为"Loopback Pseudo-Interface 1"
    * 执行 netsh interface ip set dns "Loopback Pseudo-Interface 1" dhcp
    * 执行 netsh interface ipv4 add address "Loopback Pseudo-Interface 1" 20.55.205.90 255.255.255.255

已测试,参考截图 [FloatIP.png](FloatIP.png)   
[启用FloatIP抓包](floatip.pcap)，[不启用FloatIP抓包](nofloatip.pcap)

  * 不启用float IP的情况下，在进来的流量的时候，VFP会将destination IP由LB的IP改成VM的内网IP。出去的时候，VM将流量发给VFP，然后VFP将源IP由VMIP改成LB FrontIP发出去。
  * 启用Float IP的情况下，VFP就不做IP转换的操作了，出去流量是由VM到VFP直接出去的。
  * 无论是否启用Float IP，出去流量都不经过MUX，这也就是为何说Azure LB永远工作在DSR(Direct Server Response)模式下

参考资料：https://www.youtube.com/watch?v=wJvmXM81tEI