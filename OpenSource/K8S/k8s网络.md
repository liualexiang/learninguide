## 基础
容器网络一般有三种:
1. veth pair bridge
	1. 这种方式会在容器上，以及宿主机上，产生一对（2个）网卡，两个网卡之间是桥接的方式
	2. 这种用的是最多的，默认情况下用的都是这个
2. MacVLAN/IPVLAN 的方式
	1. MacVLAN，容器使用虚拟网卡和虚拟mac地址，与宿主机通过物理网卡通信
	2. IPVLAN， 容器和宿主机共用同一个mac 地址，但容器有自己的IP地址
3. SR-IOV方式
	1. 容器直接使用宿主机的网卡，一个网卡对应一个容器

查看cgroup和 network namespace
```
lsns -t cgroup
lsns -t net // 或者 ip netns
```
### network namespace初探
#### 创建两个network namespace进行通信
在同一个linux宿主机上创建两个 network namespace，然后每一个network namespace里创建一个虚拟网卡，配置一个虚拟ip，模拟通信

```shell
# 查看当前的 network namespace
ip netns

# 创建两个 network namespace
ip netns add ns1
ip netns add ns2

# 创建veth网卡对
ip link add veth-ns1 type veth peer name veth-ns2

# 查看默认namespace里创建的网卡对
ip link
# ip addr 也可以
# 在结果里，有 veth-sn2 和 veth-sn1，是成对出现的
19: veth-ns2@veth-ns1: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 8a:54:a9:17:b9:b2 brd ff:ff:ff:ff:ff:ff
20: veth-ns1@veth-ns2: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 26:6b:f0:b3:5e:73 brd ff:ff:ff:ff:ff:ff

# 将网卡加入到不同的namespace里。注意：一旦将网卡加入到其他namespace，使用默认的 ip link或者 ip addr 命令，就看不到这个网卡了
ip link set veth-ns1 netns ns1
ip link set veth-ns2 netns ns2

# 查看特定 namespace下的网卡，需要加前缀 ip netns exec NAMESPACE_NAME，示例
# 查看 ns1下的ip link
ip netns exec ns1 ip link

# 从输出上，看到默认刚刚创建的网卡是 DOWN 的，我们如果想要使用，需要激活这个网卡
ip netns exec ns1 ip link set veth-ns1 up
ip netns exec ns2 ip link set veth-ns2 up


# 给网卡配置一个地址
ip netns exec ns1 ip addr add 1.1.1.1/24 dev veth-ns1
ip netns exec ns2 ip addr add 1.1.1.2/24 dev veth-ns2

# 检查一下ip
ip netns exec ns1 ip addr

# 从 ns1 里 ping一下 ns2的 1.1.1.2 的地址，能看到可以顺利ping通
ip netns exec ns1 ping 1.1.1.2

```
删除的时候，直接删除 namespace，则 namespace里的虚拟网卡也就被删除了
```
ip netns delete ns1
ip netns delete ns2
```

#### 将两个network namespace里的网卡，与加宿主机 的veth peer，在veth peer里进行bridge进行通信
```shell
# 创建两个 network namespace
ip netns add ns1
ip netns add ns2
# 创建一个br0 网桥
ip link add br0 type bridge
# 通过 brctl show命令，查看网桥信息
brctl show
bridge name     bridge id               STP enabled     interfaces
br0             8000.3e155fd1fab6       no
docker0         8000.02423316cd10       no

# 启用网桥
ip link set br0 up

# 创建两个 veth pair，注意跟第一次的不同，第一次是一个网卡对，现在是两个
ip link add veth1 type veth peer name veth1-ns1
ip link add veth2 type veth peer name veth2-ns2

# 将 veth1 和 veth2 的 peer 网卡，分别放到 ns1 和 ns2 命名空间里
ip link set veth1-ns1 netns ns1
ip link set veth2-ns2 netns ns2

# 启用网卡
ip netns exec ns1 ip link set veth1-ns1 up
ip netns exec ns2 ip link set veth2-ns2 up

# 设置IP
ip netns exec ns1 ip addr add 1.1.1.1/24 dev veth1-ns1
ip netns exec ns2 ip addr add 1.1.1.2/24 dev veth2-ns2

# 注意此时两个网卡是不能通信的，因为是两个独立的 namespace
ip netns exec ns1 ping 1.1.1.2
PING 1.1.1.2 (1.1.1.2) 56(84) bytes of data.

# 我们接下来要设置一下两个 peer 的网卡，让其都加入到 br0 的网桥里
# 先启用网卡
ip link set veth1 up
ip link set veth2 up

# 加入到 br0 网桥里
ip link set veth1 master br0
ip link set veth2 master br0

# 在ns1里ping一下ns2，应该就能ping通了
ip netns exec ns1 ping 1.1.1.2

# 如果还是ping不通，有可能是 网桥启用了 iptables 规则导致的，先检查下
cat /proc/sys/net/bridge/bridge-nf-call-iptables
# 如果值是1，说明确实启用了，我们可以设置为0,将其禁用。之后再ping一下就好了。注意这个设置，是操作系统上的全局设置，对所有网桥都生效
echo 0 > /proc/sys/net/bridge/bridge-nf-call-iptables

# 如果要将这个设置永久生效，需要写入到 /etc/sysctl.conf 文件中
net.bridge.bridge-nf-call-iptables = 0
# 然后使用下面命令将其生效
sysctl -p

# 注意：如果没有启用 bridge模块，可能看不到 /proc/sys/net/bridge/相关文件，可以用下面方法启用
modprobe br_netfilter
```