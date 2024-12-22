# helm 基础

在 helm v2的时候，需要在 k8s 里创建 tiller，tiller相当于一个代理，同时需要给tailer一个 service account，helm将请求给 tailer，然后由tailer去执行 创建删除资源的操作。但 helm v3的时候，helm直接使用本地的 kubeconfig文件进行操作，不再需要tailer



## helm 软件包管理命令

helm管理命令

```bash
helm search hub
# 从Artifact Hub中查找并列出charts。Artifact Hub中存放了大量不同的仓库
# 可通过运行该命令找到公开可用的charts，如：helm search hub wordpress
# 通过search hub命令只能搜到是否由charts，但需要通过返回的url，打开对应的网页，找到真正的 repo地址，将其添加到本地helm里，再进行安装. 
# helm search hub wordpress --max-col-width 0

helm search repo
# 加上 -l 参数，可以搜索所有版本
helm search repo -l

# 从添加（使用helm repo add命令）到本地客户端的仓库中查找，该命令基于本地数据进行搜索，无需互联网
helm repo add
helm repo update
```

安装包的时候，指定配置

```
helm install NAME REPO/PACKAGE --version 1.2.3 --set replicaCount=2,image.tag=v1.2
# 如果配置是一个列表，要修改第一个
--set server[0].port=80,server[0].host=aaa
# 如果值里是多个，比如 sg= "a,b"，那么在 set的时候，需要在,前面加上 \ 做转义。同样有其他特殊字符，也需要转义
--set sg=a\,b


helm update NAME REPO/PACKAGE --reset-values


```

如果在安装helm的时候，对变量做了修改，想要获得helm修改过的变量值，可以用 get values 的命令

```
helm get values NAME
```

如果想看到所有变量值，则 get values 需要加上 -a 参数

```
helm get values -a NAME
```



helm查看历史

```
helm history NAME

# 查看任意版本当时设置的值
helm get values NAME --revision 1

# 回滚到特定版本
helm rollback NAME 1
```



## 创建 helm chart

创建 chart

```
helm create CHART_NAME
```

检查 chart 是否有错误

```
helm lint ./CHART_NAME
```

渲染 chart template，生成yaml

```
helm template ./CHART_NAME
```

将生成的helm chart打包 (实际在当前路径生成了一个 .tgz文件)，然后可以将这个打包文件，传到自己的私有仓库里

```
helm package ./CHART_NAME
```

## 上传 helm chart 到远程仓库

只要远程仓库支持 OCI 标准，则可以上传。如Azure Container Registries或者AWS ECR等

```shell
# 创建示例的helm chart
helm create hello-world
# 登录到 helm registry
helm registry login CONTAINER_REGISTRY_URL --username xxx --password yyy
# 将 helm package进行打包
helm package hello-world
Successfully packaged chart and saved it to: /home/alex/temp/hello-world-0.1.0.tgz
# 推送到远程仓库
helm push hello-world-0.1.0.tgz oci://CONTAINER_REGISTRY_URL
# 从远程仓库安装
helm install myhelmhelloworld oci://CONTAINER_REGISTRY_URL/hello-world --version 0.1.0
# 查看安装的信息
helm get manifest myhelmhelloworld
# 从远程仓库下载
helm pull oci://CONTAINER_REGISTRY_URL/hello-world --version 0.1.0
```

需要注意：Helm OCI artifact是不能被 helm search repo 和 helm repo list等命令搜索到的。微软Azure的Container Registries支持 helm chart，可将 helm chart作为 repo添加到helm仓库里（如果是OCI上传的，则存储在 docker repository里，在Portal里能看到。但如果用 az acr helm 命令上传的并非docker image repo，在Azure Portal上看不到helm 仓库的信息），但AWS 的 ACR貌似只能用 OCI，不支持 helm chart
