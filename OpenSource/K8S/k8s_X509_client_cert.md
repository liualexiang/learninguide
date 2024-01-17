#### 介绍
在默认情况下，可以通过azure的用户访问aks cluster，


#### 操作步骤
首先我们先创建一个私钥
```
openssl genrsa -out xiang.key 4096
```

然后我们需要为CSR创建一个配置文件，需要注意下面几点：
1. CN 后面的名字需要和稍后登录aks的用户名保持一致
2. O 后面的名字为用户所在的组

```
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
[ dn ]
CN = xiang
O = dev
[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
```

将上述文件保存成csr.conf之后，使用openssl req命令创建csr证书申请文件

```
openssl req -config csr.conf -new -key xiang.key -nodes -out xiang.csr
```

CSR文件创建完成之后，我们就可以将其发送给aks的api server申请证书了. 首先先将xiang.csr使用base64编码一下(注意去掉回车)
```
cat xiang.csr|base64 | tr -d '\n'
```

之后准备一个证书申请文件csr.yaml，将上一步得到编码过的csr信息放在spec:request 后面，如替换下面的THIS_IS_BASE64_CSR

```
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: mycsr
spec:
  groups:
  - system:authenticated
  request: THIS_IS_BASE64_CSR
  usages:
  - digital signature
  - key encipherment
  - server auth
  - client auth
```

然后将这个csr.yaml的请求提交给api server
```
kubectl apply -f csr.yaml
```

我们可以通过kubectl get csr 命令查看一下当前的证书申请，可看到当前状态为Pending

```
$ kubectl get csr
NAME    AGE   SIGNERNAME                     REQUESTOR               CONDITION
mycsr   30s   kubernetes.io/legacy-unknown   liuxian@microsoft.com   Pending
```
然后使用kubectl命令批准证书的申请
```
kubectl certificate approve mycsr
```

之后再检查一下csr状态，将看到当前证书已Approved,Issued
```
$ kubectl get csr
NAME    AGE     SIGNERNAME                     REQUESTOR               CONDITION
mycsr   2m40s   kubernetes.io/legacy-unknown   liuxian@microsoft.com   Approved,Issued
```
接下来我们将证书导出
```
kubectl get csr mycsr -o jsonpath='{.status.certificate}' | base64 --decode > xiang.crt
```

创建一个测试用的namespace，比如development
```
kubectl create ns development
```

然后创建一个role，role是一个策略文档，里面定义了对什么资源的哪些访问权限。如下所示：我们创建的dev role将对 development namespace的 pod, services和 deployments 有create,get,update,list和 delete的权限。

```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
 namespace: development
 name: dev
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["create", "get", "update", "list", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["create", "get", "update", "list", "delete"]
```

然后创建一个RoleBinding，将用户和Role进行关联

```
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
 name: dev
 namespace: development
subjects:
- kind: User
  name: xiang
  apiGroup: rbac.authorization.k8s.io
roleRef:
 kind: Role
 name: dev
 apiGroup: rbac.authorization.k8s.io
```

到目前为止，我们已经完成了aks 服务端的配置，接下来我们要准备一个kubeconfig文件，发给用户xiang，来验证权限是否能正常工作。在kubeconfig文件中，我们要指定cluster的CA，cluster URL，cluster Name等多个配置参数，因此我们先以变量的方式来命名，之后再进行替换。我们先将下面的配置保存成 kubeconfig.tpl 临时文件

```
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_ENDPOINT}
  name: ${CLUSTER_NAME}
users:
- name: ${USER}
  user:
    client-certificate-data: ${CLIENT_CERTIFICATE_DATA}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: ${USER}
  name: ${USER}-${CLUSTER_NAME}
current-context: ${USER}-${CLUSTER_NAME}
```

接下来替换上面的变量
```
export USER=xiang
export CLUSTER_NAME=$(kubectl config view --minify -o jsonpath={.current-context})
export CLIENT_CERTIFICATE_DATA=$(kubectl get csr mycsr -o jsonpath='{.status.certificate}')
export CLUSTER_CA=$(kubectl config view --raw -o json | jq -r '.clusters[] | select(.name == "'$(kubectl config current-context)'") | .cluster."certificate-authority-data"')
export CLUSTER_ENDPOINT=$(kubectl config view --raw -o json | jq -r '.clusters[] | select(.name == "'$(kubectl config current-context)'") | .cluster."server"')

cat kubeconfig.tpl | envsubst > kubeconfig

```

kubeconfig 文件准备完成之后，我们来测试一下权限。先修改下KUBECONFIG的环境变量，使其使用我们创建的kubeconfig文件(也可以将配置信息放在 ~/.kube/config文件中，或者再执行命令的时候，通过--kubeconfig进行指定)
```
export KUBECONFIG=./kubeconfig
```
添加先前创建的xiang.key
```
kubectl config set-credentials xiang --client-key=./xiang.key --embed-certs=true
```

接下来我们验证一下权限，我们发现可以成功再 development创建3个pod的deployment
```
kubectl create deployment nginxtest --image=nginx --replicas=3 -n development
```
但如果不加-n参数，在默认的namespace下创建的时候，则会遇到报错提示权限不足

```
$ kubectl create deployment nginxtest --image=nginx --replicas=3
error: failed to create deployment: deployments.apps is forbidden: User "xiang" cannot create resource "deployments" in API group "apps" in the namespace "default"
```