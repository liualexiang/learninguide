# istio

## service mesh

服务网格一般有下面的几个重要功能

* 流量管理 (路由，灰度，重试等)
* 安全（认证 ，mtls）
* 监控 (metrics，端到端监控)
* 扩展性

## istio 架构

istio 的control plane有几个重要组件。istiod里跑了几个组件 

* Pilot (最重要的一个，实现流量管理)
* Citadel (mtls 证书管理)
* Mixer (下发配置)
* Galley (检查配置)

具体istio架构架构参考官方 (1.5 及其以上)

![The overall architecture of an Istio-based application.](https://istio.io/latest/docs/ops/deployment/architecture/arch.svg)



需要说明，如果是1.4的及其以前版本的istio，那么 pilot, galley, citadel, mixer 等组件，是单独以pod的形式运行的，但 istio 1.6开始，将这些组件都放在 istiod pod里了

![The overall architecture of an Istio-based application.](https://istio.io/v1.4/docs/ops/deployment/architecture/arch.svg)

## 流量管理

从v1.17开始，默认情况下，istio分发流量的时候，使用的是最少请求数，envoy proxy会在后端池中随机选择2个主机，将请求路由到活动连接数较少的主机上。在v1.16及其之前，是轮询算法

* Virtual Service: 一个virtual service可以通过其 routing rule将其转发到一个或多个 destination rule上，并可以指定 destination rule的 subset。在virtual service的routing rule定义的时候，可以指定到不同的destination 的权重，也可以指定 timeout， retry等，也可以定义故障注入(比如通过spec.http.fault.delay.percentage设置请求延迟多长时间)。
  * virtual service与 destination rule并没有直接关系，两者都是和 k8s service关联，属于间接关系。
  * 一般至少要有一个virtual service跟 ingressgateway 进行关联，这样当流量通过 ingressgateway进入的时候，流量会先经过关联的这个virtual service，由这个virtual service进行判断，再将流量导到其他地方

* Destination rule：可以选择负载均衡算法，以及创建 subset，每个 subset里，通过label 对pod进行选择。在Destination rule里可以指定熔断 circuit breaker的配置，比如：如果是对速率做熔断，可以通过 connectionPool.tcp.maxConnections 实现；如果对5xx错误做熔断，可以通过 outlierDetection.consecutive5xxErros来控制
* Gateway: 可以对入站和出站流量进行过滤。Gateway 其实是跑了一个 standalone 的 envoy容器, Gateway其实是一个 4-6层的负载均衡，主要让你选择暴露的端口，TLS设置等等，而并非7层的设置（如基于header等设置，需要用 virtual service）。Gateway主要是ingress gateway，除非想要对出站流量做限制，比如做一个完全内部的mesh，不让mesh内的容器访问外部资源等。virtual service在创建的时候，可以选择与 gateway进行绑定或不绑定
  * PS: 在未来(v1.19之后，具体还未确定)，istio将会用 [k8s Gateway API](https://gateway-api.sigs.k8s.io/guides/) 替代 Istio API
* Service entry: 可以将外部的某一个域名添加到 istio的 service entry里，之后envoy向这个地址发送流量，就像是网格内部一样。比如我们将外部域名加进来之后，可以用 DestinationRule对这个host做 trafficPolicy，控制外部服务的连接超时.
* Sidecar: 默认情况下，sidecar可以接收其配置上关联的端口的所有流量，不过我们也可以做一些微调，创建一个sidecar 类型的应用，来限制其能访问的hosts，端口或协议等信息。



### 创建流量路由的步骤

1. 创建pod，在创建pod的时候，定义好label，比如version=v1等，建议所有pod都使用 app 和version的标签。另外，pod必须有service关联，[哪怕pod不暴露任何端口](https://istio.io/latest/docs/ops/deployment/requirements/)

2. 创建 destination rules，创建的时候，在subsets 里的labels里，通过第一步的label选择pod

3. 创建 virtual services，在spec.http.route.destination.host 里选择要关联的 svc，如果创建的destinationrule有 subset的话，也可以加上subset，以及如果需要做一些过滤，可以使用match 对uri 的prefix过滤，或者做header过滤等。

   1. 注意：如果有多个 service都要关联gateway的话，那么路径或者过滤pattern一定不能有重叠，否则会出现流量随机在所匹配到的pattern里打给不同的服务
   2. 如果流量是东西向，由A服务打到B服务，那么只需要A服务关联gateway就可以了

   

### 注意

1. virtual service 里的 spec.hosts，这个是根据流量的 host header来选择使用哪个virtual service。只有当virtualservice与gateway关联的时候，hosts才能用*通配符，如果virtualservice没有与gateway关联，则必须明确指定hosts名字

2. virtual service 的 destination 里的host，是 k8s 的service名字，并非istio destination。如果想要访问mesh外部的转发，可以将外部地址放到 service entry里

3. destination rule 里的host，也是 k8s 的 service名字

4. virtual service 跟 destination rule没有直接关系，两者都是跟 k8s service关联

4. Istio 会修改 pod 上的 readiness health check，实际上检查用的还是自定义的，只是 kubectl get pod 看到的会改变

6. 除了mesh入口的gateway必须和一个virtualservice关联之外，其余服务可以没有virtual service，直接通过 destination rule来控制策略，但是如果想要使用 virtual service的一些特性，如故障注入(加入delay seconds)，那么就需要virtual service进行关联了

   示例参考：https://github.com/liualexiang/handson/tree/main/istio-demo

   

   

## Istioctl 命令

常用 istiocl 命令

```shell
# 检查mesh的整体概览
istioctl proxy-status
#或者
istioctl ps


```

