#### 使用Google OIDC的方式访问k8s
##### 背景
本次使用kubeadm自建2个节点的k8s集群，以及通过google提供的OIDC身份提供商做验证

##### 创建OIDC
访问下面的网站，创建一个OIDC IDP，将app type选择为Desktop App，记录下Client ID和 Secret ID
https://console.cloud.google.com/apis/credentials

##### 修改master node的kube-api

通过下面的命令进行修改master节点的kube-apiserver的配置，只用修改master节点即可，worker node无需修改

```
sed -i "/- kube-apiserver/a\    - --oidc-issuer-url=https://accounts.google.com\n    - --oidc-username-claim=email\n    - --oidc-client-id=[YOUR_GOOGLE_CLIENT_ID]" /etc/kubernetes/manifests/kube-apiserver.yaml
```

修改的本质是：将 /etc/kubernetes/manifests/kube-apiserver.yaml的 .spec.containers.command中，添加三行
```
    - kube-apiserver
    - --oidc-issuer-url=https://accounts.google.com
    - --oidc-username-claim=email
    - --oidc-client-id=[THIS_IS_CLIENT_ID]
```

##### 使用kubectl进行认证的时候，我们需要用 k8s-oidc-helper 来产生一个token，并将其存放在 ~/.kube/config 文件中

执行下面的命令下载k8s-oidc-helper，并产生kubeconfig文件
```
go get github.com/micahhausler/k8s-oidc-helper
cd go/bin/
./k8s-oidc-helper — client-id <lient-Id> — client-secret <secret>
```
将上述返回的信息的users部分的字段，追加到当前的kubeconfig文件中

```
users:
- name: ***************@gmail.com
 user:
 auth-provider:
 config:
 client-id: ***************
 client-secret: ****************************
 id-token: ***************************
 idp-issuer-url: https://accounts.google.com
 refresh-token: ****************************
 name: oidc

```

##### 创建clusterrole和rolebinding(测试k8s 1.19)


```
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: admin-role
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: admin-binding
subjects:
- kind: User
  name: liualexiang@gmail.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: admin-role
  apiGroup: rbac.authorization.k8s.io
```

##### 验证

接下来验证下是否能访问成功吧
```
kubectl --user=xxxxx@gmail.com get nodes
kubectl --token=[THIS_IS_JWT_TOKEN] get nodes
```