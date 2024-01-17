# iptables

### 基础概念

Iptables 默认有三个表: filter表，nat表，以及 mangle 表。mangle 表

filter表默认有 Input, output, forward 的链(chain)

![img](http://linux-training.be/networking/images/iptables_filter.png)



nat表默认有prerouting, input, output, forward, post routing 5条链

![img](http://linux-training.be/networking/images/iptables_filter_nat2.png)

### 显示当前iptables，可看到规则id

````
iptables -L -n --line-numbers
iptables -t nat -L -n --line-numbers
````

### 删除规则

```
iptables -D INPUT 2
```



### 端口转发

将 1.1.1.1的3306端口，转发到2.2.2.2的3306，这样在任意机器上，访问1.1.1.1的3306，就是2.2.2.2的3306

```
# systemctl status iptables， 服务需要是running状态，ec2网卡源目的地址检查需要关闭
echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 3306 -j DNAT --to-destination 2.2.2.2:3306 
iptables -t nat -A POSTROUTING -p tcp -j SNAT -d 2.2.2.2 --dport 3306 --to-source 1.1.1.1

iptables -I FORWARD -i eth0 -j ACCEPT
#iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```





参考资料: http://linux-training.be/networking/ch14.html#:~:text=the%20Linux%20kernel.-,iptables%20tables,is%20used%20for%20packet%20filtering.&text=The%20nat%20table%20is%20used%20for%20address%20translation.&text=The%20mangle%20table%20can%20be,special%2Dpurpose%20processing%20of%20packets.

