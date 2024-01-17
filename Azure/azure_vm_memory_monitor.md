#### 将Azure VM的内存和硬盘等指标发布到Azure Monitor上
##### 说明
无论是Windows和Linux，均可以在Azure VM的Diagnostic settings里面开启将指标发送到Azure Monitor上。但需要注意的是：该指标实际上是存储在Azure Storage Account的Table Store中，虽然Azure Monitor Portal上可以看到这个指标，但通过Azure Monitor的API查询不到自定义指标(REST API和Azure CLI均查不到，其他SDK应该也一样)。为了能够查询到内存和磁盘的指标，Windows VM可以在配置Diagnostics settings的时候启用Sinks功能，将自定义指标保存到Azure Monitor服务中；Linux VM需要配置telegraf来发送指标。

##### 示例：使用Azure CLI查询Windows内存信息
* 首先要在VM的设置界面配置Diagnostic setttings，将custom metric sink到Azure Monitor中，否则只能利用Azure Table Store的API查询Storage Account表中的信息了。Sink之后可以先通过REST API 获取一下metricnamespace的名字，Windows Diagnostics settings的namespace名字应该为"Azure.VM.Windows.GuestMetrics"
获取namespace的API：
```
GET GET https://management.azure.com/{resourceUri}/providers/microsoft.insights/metricNamespaces?api-version=2017-12-01-preview
# 参考文档
# https://docs.microsoft.com/en-us/rest/api/monitor/metricnamespaces/list
```
* 之后在Azure Monitor里面，可以看到多出来2个namespace，一个是"Guest(classic)"，这个指标是Azure Portal读取Azure Table Store获得的，另外一个namespace是"Virtual Machine Guest"，这个namespace下的指标才是sink到azure monitor中，可以通过azure monitor的api接口查询。查询语句示例：
```
az monitor metrics list --resource /subscriptions/5fb605ab-c16c-4184-8a02-fee38cc11b8c/resourceGroups/xiangliu_csa/providers/Microsoft.Compute/virtualMachines/win-ad --start-time 2020-05-21T06:10:00Z --end-time 2020-05-21T10:00:00Z --interval PT1M --namespace 'Azure.VM.Windows.GuestMetrics' --metric 'Memory\Available Bytes'
```

##### 示例：使用Azure CLI查询Linux指标
* 截至目前为止(2020/05/26)，Azure Diagnostics settings 中无法将Linux VM的指标sink到Azure Monitor上，因此无法使用和Windows一样的方式获得操作系统内部指标。
* 不过可以在Linux操作系统内安装telegraf软件，并且在Azure VM上配置Identity(配置Identity就类似于在VM上配置Azure service principal，这样Azure VM就有能力向Azure Monitor发布指标)，telegraf会将内存磁盘等指标信息发布到Azure Monitor上。具体配置可以参考文档：https://docs.microsoft.com/en-us/azure/azure-monitor/platform/collect-custom-metrics-linux-telegraf
* 配置成功之后，在Azure Monitor Portal上确认一下能够看到对应的指标，使用Azure CLI查询的语句示例如下：
```
# namespace 也可以通过REST API获得，也可以直接查看azure portal上的名字
 az monitor metrics list --resource /subscriptions/5fb605ab-c16c-4184-8a02-fee38cc11b8c/resourceGroups/xiangliu_csa/providers/Microsoft.Compute/virtualMachines/xiangliu-shadowsocks --start-time 2020-05-21T06:10:00Z --end-time 2020-05-21T10:00:00Z --interval PT1M --namespace 'telegraf/mem' --metric 'Available'
```



##### 有关为何Azure默认无内存和磁盘等监控指标，以及为何自定义指标收费的解释
Azure的产品在设计的时候就把安全放在了首位，内存和磁盘这类指标在hypervisor虚拟化层取不到，我们给您分配了多大的内存，那么操作系统就实实在在拥有了多大的内存，但操作系统内给程序分配多少内存，还剩多少空闲内存，这些信息都属于os内部的信息，Azure不会主动去抓取客户的任何数据，因此我们无法探知到您操作系统内的内存使用情况，除非您主动将这些信息发布到azure监控平台
当您将内存信息发布到Azure上的时候，这就相当于发布了自定义指标，不在azure标准服务指标之内，azure后台要存储这些数据点，尤其是有成千上万的客户，每个客户每一秒钟都有成百上千的机器发布各种指标，这些信息对于azure后台的服务器也产生了很大的压力，需要大量的服务器存储和处理这类新增数据，因此这种指标是收费的