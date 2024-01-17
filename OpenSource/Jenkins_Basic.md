#### 在centos 7系统下安装Jenkins
##### 先决条件
1. 需要安装 java  
```
sudo yum install java -y
```

2. 通过yum 安装jenkins  

参考链接：https://www.cnblogs.com/stulzq/p/9291237.html  

```
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

yum install jenkins

sudo systemctl start jenkins  
# 之后访问该机器的8080端口即可访问到Jenkins，默认密码在  /var/lib/jenkins/secrets/initialAdminPassword 这个路径，也可以在 /var/log/jenkins/jenkins.log 中看到
```

##### Jenkins参数化构建  
Jenkins 在General面板中的参数化构建，可以在构建的时候传参数。比如添加一个 branch1的字符/文本参数，值为 master，那么在构建的命令中可以通过 echo ${branch1} 来调用. 在构建的时候，以前是立即构建，现在就变成了build with parameters  

推荐另外安装一个 Extended Choice Parameter的插件，这样在使用参数化构建过程的时候，可以添加Extended Choice Parameter的参数，能够通过下拉框的方式进行选择（单选，多选等）。这个插件的参数可以直接写在Jenkis中，也可以写到一个文件中。  

再推荐一个 git Parameter 插件，这个插件可以直接获取git的分支号，版本等信息。 //需要在General 源码管理中，添加Git的用户名密码或者Private Key  

##### Jenkins Master/Slave架构  
可以将Jenkins作为前端，将构建任务交给Slave构建，解决单点性能不足，并提高可用性  
配置方法：  
在Jenkins系统管理--节点管理（默认只有master）---新建节点，然后指定名字，并发构建数，远程工作目录如/var/lib/jenkins(注意权限，需要ssh用户有权限到这个目录下创建文件)，启动方式选择为：Launch agents via SSH，指定 ssh private key。高级选项中指定java路径如/bin/java。标签可以输入如web.  

之后再创建任务的时候，勾选“限制项目的运行节点”，标签表达式输入web。这样任务就再web这个节点上运行。  

##### 定义Jenkins 触发器   
常用的2种触发方式：  
1. 定时构建，如下配置每5分钟检查一次更新  

```
H/5 * * * *
```

2. 通过HTTP API触发，触发远程构建，输入身份验证令牌，如sess20200420，然后访问jenkins url后面的 JENKINS_URL/job/testpipe/build?token=TOKEN_NAME 地址进行触发。如：  
```
http://40.73.102.61:8080/job/testpipe/build?token=sess20200420
```
提示说明：Use the following URL to trigger build remotely: JENKINS_URL/job/testpipe/build?token=TOKEN_NAME 或者 /buildWithParameters?token=TOKEN_NAME  
Optionally append &cause=Cause+Text to provide text that will be included in the recorded build cause.  
 
* 手动触发，定时触发和通过API触发，在日志中可以明确看出触发方式  
示例：  
手动触发：	启动用户alex  
定时触发：	由定时器启动  
API触发：	由远程主机 111.205.14.33 启动  




##### 更改Jenkins源，提高下载插件的速度  
默认情况下国内访问国外Jenkins源安装插件速度很慢，可以改成国内的源。修改Jenkins default.json 文件（yum安装默认在 /var/lib/jenkins/updates/default.json）  
在vim打开文件中，粘贴下面的命令来完成替换（如果手动输入了: 那么就只粘贴冒号后面的，请勿写2个冒号）  
```
:1,$s/http:\/\/updates.jenkins-ci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g
```

参考文档：https://www.cnblogs.com/hellxz/p/jenkins_install_plugins_faster.html  

