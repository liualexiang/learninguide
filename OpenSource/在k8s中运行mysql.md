首先创建一个nfs，作为mysql数据卷的持久化存储。如果是在某个云平台构建的k8s，也可以使用AWS的EFS或者Azure的Fileshare等作为持久化存储。

我们使用gcp提供的nfs-server-docker的镜像进行构建，首先将项目clone到本地，然后在1/debian9/1.3/目录下运行docker build制作镜像。
项目地址：https://github.com/GoogleCloudPlatform/nfs-server-docker

k8s默认不支持nfs作为storage class，不过我们可以用nfs的插件来做:
https://kubernetes.io/docs/concepts/storage/storage-classes/

