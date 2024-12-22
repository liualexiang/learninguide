## 基础
### 开发CRD的方法
使用 kubectl api-resources 可以列出所有的API，一般开发 k8s CRD，会用到 client-go，不过从头写一个 controller，比较麻烦，尤其是些多个controller的时候，有很多重复性的工作，我们可以用官方的kubebuilder，或者redhat提供的operator-sdk进行快速开发。[对比文档](https://tiewei.github.io/posts/kubebuilder-vs-operator-sdk)

K8S controller (内置和 crd)，通过 list watch模式 对k8s API资源进行通信，从而实现对资源的实时感知，从而根据资源变化触发对应的业务逻辑
### informer 角色
直接使用 List Watch API，牵扯到一些细节和优化的问题。因此k8s提供了 informer机制。
1. 缓存： informer 支持本地缓存，减轻API Server 压力
2. 事件回调：Informer 可以作为 List-Watch 操作注册回调函数，处理资源新增，更改和删除事件
3. 通知机制：Informer不仅适用于内置资源，也适用于CRD自定义资源

### controller开发流程
1. 定义CRD
2. 注册 Informer
3. 实现 Controller逻辑
4. 状态回写







