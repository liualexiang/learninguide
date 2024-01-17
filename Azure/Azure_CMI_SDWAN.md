#### 通过CMI提供的Express Route将国内外Azure打通
本次示例新加坡创建Express Route和CMI打通，北京北部2区域通过VPN Gateway和CMI打通

##### 新加坡Express Route设置

**创建Express Route**  
在Global Azure Portal界面，搜索ExpressRoute circuits，然后点击Add添加。由于本次是使用中国移动提供的线路，配置信息如下：  

    * Port type: Provider
    * Create new or import from classic: Create new
    * Provider: China Mobile International
    * Peering location: Singarpore
    * Bandwidth: 50Mbps
    * SKU: Standard
    * Billing model: Metered
    * Allow classic operations: No  
  
创建好之后，把service key给CMI支持人员，他们批准之后，express route状态则变为 provisioned. 同时他们会提供两个互联ip，vlan id ， bgp password，以及CMI的AS号。  

**创建Peering**
在Express Route circuit中，点击Peerings，创建一个Azure Private type的peering，在创建的时候需要输入之前获得的Peer ASN, Primary subnet, Secondary subnet, WLAN ID, Shared key.  
保存之后，在private peering中可以获得ARP记录（在此记录中能够看到此专线学到的MAC地址信息），路由表信息，和路由表统计信息 ，注意同时检查下Primary 和Secondary，路由表信息中应该能看到国内北二区VNET的IP段(如果没有看到需要反馈给CMI人员进行修改)

**创建一个Vnet Gateway**
搜索Virutal Network Gateway，Gateway type选择"ExpressRoute"，选择正确的region以及VNET，子网，PublicIP，然后点击创建。将此Vnet Gateway与VNET的子网关联。

**创建Connection**
在Express Route界面，点击Connections，然后创建一个，name可以随便写，在 "setting"中选择先前创建的Vnet Gateway，不要勾选"Redeem authorization"，路由权重为0，然后点击创建。  

在VNET 的子网里起一个VM，然后ping一下学到的路由的next hop地址，正常来说能ping通。



##### 国内北二区域设置

在国内Azure搜索"local network gateway"，然后创建一个本地网络网关。名字可以随便写，IP地址处输入本地IPSec设备的公网IP，Address space输入本地的网段，选择正确的资源组和位置(本次示例为中国北部2)，然后点击创建。  

在国内Azure搜索"virtual network gateway"，然后新建一个网络网关。名字可以随便写，Gateway type选择"VPN"，VPN type选择"Route-based"，SKU选择"VpnGw1"，本次测试不勾选"enable active-active mode"，选择VNET和public IP，然后点击创建。创建完成之后，点击"Connections"，新建一个链接。名字可以随便写，Connection type选择 "Site-to-Site(IPsec)"，然后选择先前出啊关键的Local network gateway，输入一个 "Shared key (PSK)"，PSK不建议使用弱密码，最好是数字字母加特殊字符，之后点击 "OK" 进行创建。  

创建完成之后，在 Virtual Network Gateway 的 Public IP address, PSK 和 VNET 的网段发给 CMI 的对接人员，CMI 目前使用了 Fortinet 作为 IPsec 接入设备，等 CMI 完成相应的配置之后，在 Virtual network gateway 的 Connections 界面，可以看到先前创建的连接状态为 "Connected".  

在国内Azure搜索"Route tables"，创建一个路由表。在路由表的 "Routes" 界面，添加一条路由，"Address prefix" 为 CMI 端的私网IP段，"Next hop type" 为 "Virtual network gateway" (一个VNET只能关联一个VNET GW，先前创建GW的时候已经与VNET关联，因此此处并没有直接列出来GW的名字)。在 "Route table" 的 "Subnets" 界面，将VNET中的私有子网与该路由表关联。 完成此操作之后，可以在该私有子网中起一个VM，然后ping 一下 CMI 提供的他们对端的私网IP地址，如果一切配置正确，则能成功ping通。  

在上述配置成功的情况下，修改先前创建的 "Route table"，在 Routes 界面，添加一条路由，Address prefix 为新加坡的 VNET 网段， Next hop type 为 "Virtual network gateway"。同时修改一下先前创建的 "Local network gateway"，在 "Configuration" 界面，Address space中添加 新加坡的 VNET 网段。


上述操作完成之后，正常来说北二区Azure和新加坡Azure就彻底打通了。由于当前CMI提供的IPsec设备放在上海，因此国内北二到上海这段是通过互联网连接，然后上海通过专线连到新加坡Azure。

##### 性能报告

性能评估方法为：从北二VM到新加坡VM每隔1分钟ping 10个包，连续抓取24小时，统计出丢包率，ping的最大值，最小值，以及平均值。   

下图为丢包率报告，从报告上来看，专线的网络更稳定，丢包率明显低于互联网。


下图为延时报告，比较有意思的是，专线网络的延时要比直接互联网要高一些。可能是与北二先通过互联网连到上海，然后从上海再专线到新加坡导致的。但从这个图上也能看出，互联网的抖动是比较明显的，虽然专线延时更高，但稳定性仍然比互联网好很多。


##### 北一区借助于北二区的VPN Gateway以及CMI线路跟新加坡VNET打通

* 在北一区的Vnet中，点击Peering，然后Add一个Peering，选择对端北二区的VNET，在这个Peering中，一定要Enable "Allow virtual network access from cmi-cnn1 to cmicnn2"，同时勾选 "use remote gateways".
* 上一步创建完成之后，在北二区的VNET中，也自动多了一个Peering，点进去之后，确保Enable "Allow virtual network access from cmicnn2 to cmi-cnn1"，以及勾选 "Allow gateway transit"
* VNET的路由不需要做任何其他调整，此时联系CMI人员，让他们在IPsec感兴趣流里面添加北一区VNET的IP段，以及在新加坡专线中的BGP路由中通告北一区VNET的IP段。
* 上述测试完成之后，就可以在北一区ping一下新加坡的VM了，理想情况可以成功ping通。