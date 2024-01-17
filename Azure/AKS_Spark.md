### 在AKS平台上轻松运行Spark应用
#### 前言
在当今互联网和移动应用快速发展的浪潮下，大数据和微服务应用也受到越来越多技术人员的青睐，其中Spark 和Kubernetes 容器管理平台几乎是每一个技术人员必备的技能。如何快速部署集群，如何安全高效的运维，是否可以将大数据平台和容器管理平台有效的结合起来，也是很多人一直以来探索和研究的一个方向。本文我们将和大家一起来探索在Azure Kubernetes Services上部署和运行Spark 应用的两种方式。

#### 方法一：通过AKS 的API Server直接提交Spark任务
从Spark 2.3开始，Spark原生已经支持Kubernetes，这意味着您无需提前构建Spark集群，在Spark Client提交任务的时候，只需要指定 Kubernetes 的 API Server地址和端口，即可运行Spark任务。在使用spark-submit提交任务的时候，既可以指定Cluster Mode，又可以指定Client Mode。其工作原理如下：
•	当任务提交成功之后，会在K8S集群里面起一个运行Spark driver的Pod
•	这个Spark driver会在Pod中创建executors，然后连到这些executor，并执行应用代码。
•	当应用执行完成之后，运行executor的pod会被终止并删除，但运行Spark driver的Pod会一直保留，并显示为”completed” 状态直到被手动删除。在此期间，可以kubectl logs 命令查看Spark的日志。

##### 通过Spark-Submit向AKS集群提交Spark 任务
1.	创建AKS集群
在Azure Portal上搜索”kubernete”，然后进入到AKS的管理界面，可根据向导快速创建一个AKS集群。本次示例我们采用了3个节点的Worker Node，机型为B2ms，网络模式为Basic (Kubenet)。有关创建集群和连接集群的步骤，您也可以参考本文档。成功创建之后，可以通过下面的命令看到AKS集群的信息，记录下master节点的地址。

```bash
$ kubectl cluster-info
```

2.	准备Spark环境。下载Spark安装文件，将其解压

```bash
$ wget https://archive.apache.org/dist/spark/spark-2.4.6/spark-2.4.6-bin-hadoop2.7.tgz
$ tar zxvf spark-2.4.6-bin-hadoop2.7.tgz
$ cd spark-2.4.6-bin-hadoop2.7
```

3.	创建Azure Container registries镜像仓库。在Azure Portal中搜索”container registries”，按默认参数创建一个镜像仓库。创建完成之后，再Access keys界面，点击Enable 启用Admin user，记录下repo的地址，用户名和密码，使用docker login登录到ACR，然后使用az cli将AKS集群和ACR进行关联。

```bash
$ docker login REPO_URL --username USERNAME --password PASSWORD
$ az aks update -n AKS_NAME-g RESOURCE_GROUP--attach-acr ACR_NAME
```

4.	准备Spark Docker Image。创建spark image，并将其上传到Azure Container Registries镜像仓库中。其中-r 后面跟上一步创建的repo地址， -t后面跟版本号

```bash
$ ./bin/docker-image-tool.sh -r xiangliurepo2.azurecr.io/spark -t v2.4.6 build
$ ./bin/docker-image-tool.sh -r xiangliurepo2.azurecr.io/spark -t v2.4.6 push
```

5.	创建运行Spark任务的service account，并绑定相应的role

```bash
$ kubectl create serviceaccount spark
$ kubectl create clusterrolebinding spark-role --clusterrole=edit --serviceaccount=default:spark --namespace=default
```
6.	准备一个Spark应用jar包，将其传到Azure Blob上，权限设置为公网可访问。或者使用本次示例提供的jar包。

```bash
$ ./bin/spark-submit \
   --master k8s://https://AKS_MASTER_ADDRESS:443 \
   --deploy-mode cluster \
   --name spark-pi \
   --class org.apache.spark.examples.SparkPi \
   --conf spark.executor.instances=3 \
   --conf spark.kubernetes.container.image=ACR_URL/spark/spark:v2.4.6 \
   --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
   https://xiangliu.blob.core.windows.net/files/spark-examples_2.11-2.4.6.jar
```

在运行的过程中，可以通过kubectl get pod –watch进行观察，我们会看到 spark-pi-xxxx-driver先运行起来，然后会起3个spark-pi-xxxx-exec-N pod作为executor，任务完成之后，executor pod会自动删除，只保留driver pod信息，通过 kubectl logs DRIVER_POD_NAME可以看到计算的PI结果。

7.	在Spark任务执行的过程中，我们也可以通过port forward的方法，将driver的端口映射到本机来访问spark UI.

```bash
$ kubectl port-forward spark-pi-xxxx-driver 4040:4040
```

然后浏览器访问 http://localhost:4040 即可访问到Spark UI

##### 通过client mode访问到运行在AKS集群中的spark-shell
从Spark 2.4.0开始，Spark原生支持在k8s上以client模式提交任务。但Spark executors必须能通过主机名和端口连接到Spark Driver上。Spark Driver既可以在物理机上运行，也可以跑在pod里面。为了使Spark executors 能够解析到spark driver的DNS名称，本次我们将创建一个ubuntu的pod，在pod中配置spark client的环境。
创建ubuntu pod的命令为：
```bash
kubectl run jump-ubuntu -it --image=ubuntu -- sh
```
之后会自动进入到ubuntu pod的shell，接下来的命令全部都在ubuntu pod shell中输入

```bash
cd /tmp
apt update
apt install -y wget openjdk-8-jdk curl dnsutils
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
# 使用Azure Account登录到Azure CLI
az login
# 下载kubectl
az aks install-cli
#获取aks的kubeconfig
az aks get-credentials -g xiangliu_csa -n xiangaks16

# 下载 Spark
wget https://archive.apache.org/dist/spark/spark-2.4.6/spark-2.4.6-bin-hadoop2.7.tgz
tar zxvf spark-2.4.6-bin-hadoop2.7.tgz
cd spark-2.4.6-bin-hadoop2.7

# 配置spark client模式提交任务的环境变量
export NAMESPACE=default
export SA=spark
export K8S_CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
export K8S_TOKEN=/var/run/secrets/kubernetes.io/serviceaccount/token
export DOCKER_IMAGE=xiangliurepo2.azurecr.io/spark/spark:v2.4.6
export DRIVER_PORT=29413
export DRIVER_NAME=jump-ubuntu
kubectl expose pod $DRIVER_NAME --port=$DRIVER_PORT --type=ClusterIP --cluster-ip=None
# 确保可以正确解析到Spark Driver的pod
nslookup $DRIVER_NAME.$NAMESPACE.svc.cluster.local

# 打开spark shell
bin/spark-shell \
    --master k8s://https://xiangaks16-dns-749d5885.hcp.eastus2.azmk8s.io:443 \
    --deploy-mode client \
    --name pyspark-shell \
    --conf spark.executor.instances=2 \
    --conf spark.kubernetes.container.image=$DOCKER_IMAGE \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=$SA \
    --conf spark.kubernetes.namespace=$NAMESPACE \
    --conf spark.kubernetes.authenticate.caCertFile=$K8S_CACERT  \
    --conf spark.kubernetes.authenticate.oauthTokenFile=$K8S_TOKEN  \
    --conf spark.driver.port=$DRIVER_PORT \
    --conf spark.driver.host=$DRIVER_NAME.$NAMESPACE.svc.cluster.local

```

进入Spark Shell之后，就可以看到spark master的地址即为aks的地址，之后就可以通过交互式方法跑Spark的任务了

```scala
scala> val range = spark.range(1000000)
scala> range.collect()
```

通过上述方法，我们已经实现了在AKS集群中运行Spark任务PI，好处是在不跑Spark任务的时候，不消耗任何资源，任务跑完之后，pod会被删除，也不会占用AKS集群的资源。 

#### 方法二：使用Spark Operator在AKS里面运行Spark集群
K8s Operator 是K8s的一个扩展功能，通过K8S Operator可以通过自定义资源来创建应用。基于这个功能，我们可以借助于一些第三方的Operator在k8s里面运行一个长期稳定的Spark集群。本次我们以radanalytics.io 提供的Apache Spark Operator 为例，来演示如何创建一个Spark集群以及如何直接提交Spark Application.

##### 操作步骤：

1.	在AKS集群上使用下面的命令部署Apache Spark Operator，部署完成之后可以通过kubectl get operators 命令来进行确认，PHASE显示为”Successed”则表示已部署成功
```bash
$ curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.16.1/install.sh | bash -s 0.16.1
$ kubectl create -f https://operatorhub.io/install/radanalytics-spark.yaml
$ kubectl get csv -n operators
```

2.	将下面的内容保存成sparkdemo.yaml，然后执行 kubectl appy -f sparkdemo.yaml命令，将会创建一个master node，2个worker node的Spark集群.
```yaml
apiVersion: radanalytics.io/v1
kind: SparkCluster
metadata:
  name: my-spark-cluster
spec:
  worker:
    instances: '2'
  master:
    instances: '1'
```
3.	运行  kubectl get sparkcluster 命令来检查SparkCluster已经创建成功，使用 kubectl get pod可以看到master和worker运行的pod信息。通过 kubectl get svc 可以看到spark cluster连接的服务地址  

4.	接下来可以通过自己的应用，或者部署JupyterNotebook，或在pod中访问到spark master的地址，在访问的时候通过 –master k8s://my-spark-cluster:7077 的方式进行指定。  
5.	您也可以通过SparkApplication直接向k8s集群提交spark任务，示例yaml如下：
```yaml
apiVersion: radanalytics.io/v1
kind: SparkApplication
metadata:
  name: my-spark-app
spec:
  mainApplicationFile: 'local:///opt/spark/examples/jars/spark-examples_2.11-2.3.0.jar'
  mainClass: org.apache.spark.examples.SparkPi
  driver:
    cores: 0.2
    coreLimit: 500m
  executor:
    instances: 2
    cores: 1
    coreLimit: 1000m
```


**小结：**
我们在上述方法中探讨了在AKS环境中运行Spark 集群的两种方式：原生集成方式和Spark Operator方式。对于原生集成方式，需要Spark2.3以上的版本(Spark Shell 则需要 2.4.0以上版本)，在不运行任务的时候，可以自动销毁pod以节约资源。Spark Operator是由第三方提供的，提供了通过Yaml的方式管理集群，运行Spark 应用。另外由于集群是长期在aks环境中运行，因此可以和丰富的k8s管理工具做集成。大家可以根据自己的实际需求，来选择最适合自己的方式来运行。


**参考资料：**
1.	AKS 介绍：https://docs.microsoft.com/zh-cn/azure/aks/intro-kubernetes
2.	Running Spark on Kubernets：https://spark.apache.org/docs/latest/running-on-kubernetes.html
3.	Apache Spark Operator: https://operatorhub.io/operator/radanalytics-spark

