#### 将Gitlab的用户系统和AzureAD集成

##### 在Ubuntu 18.04系统下安装Gitlab

* 先更新一下系统和相关软件，使用curl一键更新gitlab-ce的repo，然后使用apt安装

```
sudo apt-get update
sudo apt-get install -y curl openssh-server ca-certificates
curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo apt-get install gitlab-ce
```

参考文档：https://packages.gitlab.com/gitlab/gitlab-ce/install

安装完成之后，需要修改一下配置，在gitlab.rb中修改 external_url 为IP地址，如 'http://ip'
需要注意的是：如果要和Azure AD集成，必须在 external_url中输入域名，IP是无法通过的.

```
sudo vim /etc/gitlab/gitlab.rb
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

配置完成之后，在浏览器使用http://ip 就可以打开gitlab页面了，需要设置初始化密码，之后登录的用户名为root，密码即为刚才设置的。

##### 设置与Azure集成

在Azure AD中，创建一个App registrations，注意不是Enterprise applications，Supported account types选择"	Accounts in this organizational directory only (liuxianms only - Single tenant)"即可。Redirect URI要设置为gitlab的地址，注意一定要用https，无法使用http，不过证书可以是自己颁发的，可以不用受信任的第三方证书(使用上述方法创建出来的gitlab默认就是自己颁发的证书)。
创建好之后，在这个app的左侧Certificates & secretsz中，创建一个client secret，并将其记录下来，同时在Overview中记录下Client ID和tenantID.

之后需要编辑一下/etc/gitlab/gitlab.rb

```
gitlab_rails['omniauth_allow_single_sign_on'] = ['azure_oauth2']
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'azure_oauth2'
gitlab_rails['omniauth_providers'] = [
          {
            "name" => "azure_oauth2",
            "args" => {
                "client_id" => CLIENTID,
                "client_secret" => CLIENTSECRET,
                "tenant_id" => TENANTID
                }
            }
]
```

创建好之后重启一下服务:

```
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

之后打开Gitlab的登录界面，然后会发现自动跳转到了Global Azure上，输入Azure AD中的任意一个用户，即可实现登录。