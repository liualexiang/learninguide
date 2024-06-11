# Docker 基础

## Docker 权限控制

使用不同的 container 编排工具，容器内的权限和宿主机的登录的用户权限之间的关系可能不一样。

比如Podman对容器进行管理的时候，每一个容器是一个单独的进程，因此在root 用户下，使用 podman run启动的容器，执行这条命令启动的进程的用户就是root，在某一个user下使用podman run启动的容器的进程用户就是该user。

但实际容器内部的用户，是由 podman run -u USERNAME 决定的，如果想让container里面是root身份，那么也可以用 podman run -u root 或者 podman run --priviledged 的方式起一个privileged容器，这样container里面就能执行apt或yum等命令安装应用了。

使用docker的话，所有的docker container的进程都隶属于dockerd 这个父进程，因为docker是用root 身份启动的，因此 docker container 在宿主机上也是以root身份启动的。使用ps -ef |grep container_ID 就能看出来。但docker container容器内部的用户，是由 docker run -u USERNAME 决定的，同样也可以用 docker run --priviledged 的方式启动一个privileged容器。



如果在启动容器的时候，没有指定用户的身份，那么 docker 内默认的用户身份，是由 Dockerfile 文件中的 USER 字段决定的。需要注意的是：USER只能说明使用哪个用户，而不会创建这个用户，因此请务必在 USER 字段前，使用 RUN useradd ${USERNAME} 的方式将用户创建出来。还需要注意的是：如果是启动了某个服务进程，并且该服务进程监听到 1024以下端口，那么还是需要root用户才能启动，否则会失败.



备注：

1. 容器内的用户，是通过宿主机 /etc/subuid 的这个文件决定如何和宿主机之间做mapping的，在容器内可以 cat /proc/self/uid_map 来查看容器的uid范围，如果是root的话，则如下所示：

```
bash-4.4$ cat /proc/self/uid_map
         0          0 4294967295
```

2. podman管理的容器，并不需要安装docker



## 有关Dockerfile的技巧

### Entrypoint 和  CMD

在Dockerfile中，如果FROM 的镜像，已经有了  CMD 和 ENTRYPOINT，那么新的Dockerfile，如果不修改启动命令的话，可以没有CMD 和 ENTRYPOINT；但如果新的Dockerfile有 CMD，那么这个 CMD会覆盖原来的FROM镜像的CMD，也就意味着，实际生效是：将新Dockerfile里的CMD作为参数，传递给原来的FROM镜像的 ENTRYPOINT；如果只想修改ENTRYPOINT，该怎么办呢？答案是：需要将原来的ENTRYPOINT 修改后和 将原来的CMD 也带到新的Dockerfile中，如果不带原来的CMD的话，那么新的Dockerfile就会认为没有CMD，它不会去原来的Dockerfile里找CMD

**为什么有了 CMD 还要有ENTRYPOINT？**

在使用效果上，如果CMD 和ENTRYPOINT 共存的情况下，CMD会作为参数，传递给 ENTRYPOINT。而在实际docker run的时候，如果后面又跟了一个参数，这个参数会覆盖 CMD 里的参数，此时ENTRYPOINT只接受 docker run命令后面带的参数，而忽略 CMD里写的参数。用这个效果，可以构建一个动态的传参过程，将CMD作为默认参数，但docker run的参数，作为动态参数传递给 ENTRYPOINT。

如果ENTRYPOINT 中指定的是一个脚本，那么脚本的第一行，必须使用 #!/bin/bash 或 #!/bin/sh 说明使用的是哪一个shell，并且这个shell必须存在。比如 如果脚本指定使用的是 bash，但 alpine 镜像是没有bash的，就会报错



### 有关 COPY 

在使用COPY 指令将文件到Docker内部的时候，注意目标地址最好写绝对路径，否则在下面的命令中，可能找不到这个文件。或者使用 WORKDIR指令来指定工作目录



### 使用multi stage进行构建

一个示例Dockerfile

```dockerfile
FROM ubuntu:latest as builder
WORKDIR /app
RUN apt update && apt install nginx && go build

FROM alpine as prod
RUN addgroup --system --gid 1002 appuser && adduser --system --uid 1002 --gid 1002 appuser
WORKDIR /app
COPY --from=builder /go/build/output .

RUN chown -R appuser:appuser /app/output && chmod +x ./output
USER 1002

EXPOSE 8080
CMD ["./output"]
```

可以创建一个Makefile，以后使用 make docker_build 来进行构建

```makefile
docker_build:
        docker build --target prod -t my-app .
```





### 在Docker Build的时候拉取私有仓库

在docker build的时候，比如执行 go build，需要导入一个私有仓库的依赖包，那么我们可以将github credential注入到 Dockerfile中，比如:

```dockerfile
# format https://<github_user_name>:<github_password>@github.com
ARG GITHUB_CREDENTIAL="nothing"

RUN echo ${GITHUB_CREDENTIAL} > /root/.git-credentials
RUN printf "[credential]\n\thelper = store\n" > /root/.gitconfig

##或者用这个替代
RUN git config --global url."${GITHUB_CREDENTIAL}".insteadOf "https://github.com"
```

在build的时候，通过build-arg 将git token传进去就行

```
export GITHUB_CREDENTIAL="https://<github_user_name>:<github_password>@github.com"
docker build --build-arg GITHUB_CREDENTIAL=${GITHUB_CREDENTIAL}
```



## Docker Buildx 构建multi architecture image

如果我们想构建出跨平台的镜像，比如 nginx:latest，我们既能在 amd64下使用，又能在 arm 64平台下使用，那么可以使用 buildx 来快速构建.

首先我们要创建出来一个builder，这里我们使用 docker-container的driver，除了这个driver之外，还有 docker,kubernetes, remote三类可以使用

```shell
docker buildx create --name mybuilder --driver docker-container --bootstrap

```

然后我们要制定所使用的builder

```shell
docker buildx use mybuilder
# 使用 docker buildx ls 可以看到当前使用的builder
```

之后就可以一键build并且push了

```shell
docker buildx build --platform linux/amd64,linux/arm64 -t liualexiang/dockertest . --push
```

需要注意的是：如果是多平台镜像，那么要带上 --push 参数，否则只存在本地的缓存中。如果是单一平台镜像，那么我们可以加上 --load 的参数，这样build之后，用 docker images 是能看到的

在使用多平台镜像的时候，注意要看所在的容器平台是否支持多平台镜像，比如AWS ECS Fargate支持，但AWS Lambda不支持(2023-06-21)

在拉镜像以及运行镜像的时候，默认会根据平台自动选择，如果想手动制定平台拉取镜像，那么要加上 --platform 参数

```shell
docker pull --platform linux/arm64 liualexiang/dockertest:latest
docker run --platform linux/arm64 -p 80:80 liualexiang/dockertest:latest
# 检查镜像所属平台
```

如果只想构建某一个特定平台的镜像，比如在 x86_64机器上，构建arm64的

```shell
docker build --platform linux/arm64 -t xxx .
```

在使用多阶段构建的时候，如果有些库是依赖于系统里的库，那么使用 一些精简的docker镜像可能会出问题，此时我们最好使用静态编译，具体做法是将 CGO_ENABLED=0

```dockerfile
FROM --platform=linux/amd64 golang as builder
WORKDIR /builder
COPY main.go main.go
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o main main.go

FROM alpine:3.16 AS certs
RUN apk --no-cache add ca-certificates

FROM scratch as prod
WORKDIR /app
COPY --from=certs /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /builder/main main
CMD ["./main"]

```



## Docker 项目优化

### lazy pulling

使用 lazy pulling的技术，可以不用等镜像完全下载到本地的时候，就能运行起来。目前有多种 lazy pulling实现的技术（基于 snapshotter实现），一般都是在原生的 docker manifest index的基础上，又加了另外一个index，因此对 docker registry是否支持这个技术也有一定的关系。比如AWS 在2022年9月份推出的 [SOCI](https://aws.amazon.com/cn/about-aws/whats-new/2022/09/introducing-seekable-oci-lazy-loading-container-images/)，或者 Stargz Snapshotter, Nydus, OverlayBD等(后者都可以用 nerdctl 构建 )

### docker build替代工具

nerdctl是一个比较成熟的项目，兼容 docker的大多数命令，也支持 rootless container，支持 builds，甚至支持P2P镜像分发技术(类似阿里的 dragonfly项目，需要另外部署ipfs 进程才行)

podman也支持rootless，兼容docker多数命令



参考文档: https://www.redhat.com/en/blog/understanding-root-inside-and-outside-container

## Docker 存储

在 Mac 或 windows系统中，docker有一个专门的分区，有时候镜像过多，会出现docker分区磁盘已经满了的情况

```
docker system df -v
df -h /var/lib/docker
docker system prune

```

具体分区配置在 ~/.docker/daemon.json 或 /etc/docker/daemon.json 配置文件中
