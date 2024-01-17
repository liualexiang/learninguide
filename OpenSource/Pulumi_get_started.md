# Pulumi 使用基础

## Pulumi 是什么

Pulumi 是一个类似 AWS CDK 的 IaC 工具，提供了各种开发语言的 SDK，借助于 Pulumi，可以快速创建和维护资源，并通过 state 对资源的状态进行管理

## 使用基础

1. 在一个空文件夹下执行 下面的命令，登录到pulumi，然后根据向导创建一个python 项目
   
   ```
   pulumi login
   pulumi new python
   ```

```
2. 如果想存在其他地方，如azure blob，那么就需要执行( 需要 export下 storage account 以及 key) ```pulumi login azblob://<container-path>``` 

3. 如果需要安装某个云的provider，那么需要在项目的requirements.txt文件中指定，然后pip install -r requirements.txt 安装一下。之后就可以修改 __main__.py 文件，编辑自己想要的代码，之后执行 pulumi up 进行部署
```

# endit the __main__.py file

pulumi up

```
4. 查看当前的部署命令
```

pulumi stack ls

```
5. 查看当前登录的用户
```

pulumi whoami
```