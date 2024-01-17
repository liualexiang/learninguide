#### 使用Azure Service Principal 登录Azure CLI
##### 创建 Azure Service Principal 
Azure Service Principal 是Azure AD 中提供的一种身份验证功能，可以通过Azure SP登录Azure CLI, Teraform, Azure PowerShell, SDK 等。Azure Service Prinicipal还提供了OAuth 2.0，OIDC(Open ID Connect), SAML, Microsoft Graph API等多种身份验证接口，方便开发人员快速开发应用。

下面以在Azure Portal中创建Service Principal示例：
1. 在Azure AD 中，点击App registrations，然后选择New registration, Name 可以输入任意名称，如xiangliu-demo，在Supported account types中选择Accounts in this organizational directory only(Microsoft only - Single tenant), Redirect URI留空不填，然后点击 Register。创建成功之后，在Overview界面，记录下Clinet ID以及Tenant ID
2. 在Certificates & secrets 里面，创建一个Client secrets，过期时间可以设置为1年，2年或永不过期。创建好之后一定要复制一下key，Azure不会保存此Key，因此如果丢失就只能删除重建。
用azure cli也可以重置key。奇怪的是：azure cli创建的key的格式为0000-0000-0000-0000-0000，但portal上创建出来的为 xxxxxxxxxxxxxxx，都能使用。
```
 az ad sp credential reset --name $appId
```
##### 对Service Principal 进行授权
上述步骤就已经创建了service principal，接下来在Subscripitons里面对其授权。选择当前活跃的subscription，然后点击Access control(IAM)，在check access里面可以搜一下 xiangliu-demo，会发现没有任何权限。然后点击Add a role assignment，role选择为 Contributor（这个role有权限创建资源，但没权限在订阅中添加用户，如果想要所有权限，可以选择owner），Select里面搜索xiangliu-demo，之后选择Save保存。

##### 在Azure CLI中配置Service Principal
先检查一下Azure CLI的配置情况
```
# 检查已配置的azure account
az account list
#将已登录的用户注销
az logout
# 清空azure account
az account clear

#再次确认没有配置azure account
az account list

# 使用刚创建的service principal 登录
az login --service-principal -t $tenant_id -u $appid -p $password
```

##### 使用azure cli创建sp并登录
如果觉得上面手动操作方式比较复杂，也可以用azure cli快速创建，方法如下：
```
# 创建service principal，记录下appid(client id), password(client_secret), tenant id
az ad sp create-for-rbac --name xiang-demo-cli

az login --service-principal -t $tenant_id -u $appid -p $password

#注销登录
az logout

```


##### 使用azure cli登录到不同的云
```
 az cloud list --output table
 az cloud set --name AzureChinaCloud
 az login
 # https://docs.microsoft.com/zh-cn/cli/azure/manage-clouds-azure-cli?toc=%2Fcli%2Fazure%2Ftoc.json&bc=%2Fcli%2Fazure%2Fbreadcrumb%2Ftoc.json&view=azure-cli-latest
```
