#### 通过源码build azure cli
在某些时候，当az cli有一些bug或者不足，产品组会发布新版本，但产品组review新版本的时间可能会比较长，这时候可以自己在github的pull request里面找到fix的pr，然后自行pull下来进行编译

##### 示例
###### 下载某一个branch
在2020年5月13日，这个分支里面修复了使用az cli管理cdn的自定义证书
```
git clone -b cdn/byoc https://github.com/lsmith130/azure-cli
```

###### 安装python，python虚拟环境，安装 azdev工具
```
sudo apt-get install python3
sudo apt-get install python3-venv

```

创建python虚拟环境，这样不影响本地原来环境，在虚拟环境中安装azdev
```
python3 -m venv venv
cd venv/bin
source activate
pip install azdev
```
##### 安装az cli
进入到az cli的下载目录里面，然后执行``` azdev setup -c```进行安装

使用az cdn管理自定义证书示例：
```
az cdn custom-domain enable-https --profile-name xiangliums --endpoint-name xiangliucdn --name cdn-liuxianms-com --resource-group xiangliu_csa --user-cert-group-name xiangliu_csa --user-cert-protocol-type sni --user-cert-vault-name xiangkeys --user-cert-secret-name selfweb --user-cert-secret-version e87d7edae7644c499af14077771f1bee --user-cert-subscription-id 5fb605ab-c16c-4184-8a02-fee38cc11b8c
```