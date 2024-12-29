如果yum想装特定版本的软件，则可以用 --showduplicates 列出所有版本
```
yum list --showduplicates logstash
```

搜到后，能看到比如 1:8.17.0-1，则安装的时候是
```
yum install logstash-1:8.17.0-1
```


在yum配置里，也可以exclude一些包，在安装的时候，如果想排出execlue，则为
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

```toml
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
```