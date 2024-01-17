#### Superset安装说明
Superset是一个airbnb贡献出开源的BI工具，在airbnb内部广泛使用，目前amazon内部也慢慢将BI工具从tableau迁移到Superset.

在测试环境中，可以用docker部署，用docker-compose up一条命令即可部署成功，但在生产环境中，不建议使用此方法。

**生产环境，可以参考下面的方法部署**

##### 系统要求

推荐内存4GB，硬盘20GB以上。
Superset 只支持python3.6以上版本，不支持python2.7
当前测试的superset版本为0.35.2
本次测试机型：AWS宁夏区Amazon Linux2 (ami-0e08e7c3821193844)

##### 安装准备工具
先升级安装一下安装工具
```
sudo yum install -y python3
sudo yum install -y python3-devel  // 不安装python3-devel，在用pip安装superset的时候会报错 gcc编译Python.h错误
sudo yum install python-setuptools   // 或者升级 sudo yum upgrade python-setuptools
sudo yum install -y gcc gcc-c++ libffi-devel python-devel python-pip python-wheel openssl-devel cyrus-sasl-devel openldap-devel
```


安装一下python虚拟环境
``` sudo pip3 install virtualenv -i https://pypi.douban.com/simple ```

激活环境
```
python3 -m venv venv
. venv/bin/activate
```

升级一下pip和setuptools
``` pip3 install --upgrade setuptools pip -i https://pypi.douban.com/simple ```

##### 开始安装
使用pip3安装superset
``` 
# Install superset
pip3 install apache-superset -i https://pypi.douban.com/simple 

# Initialize the database
superset db upgrade

# Create an admin user (you will be prompted to set a username, first and last name before setting a password)
export FLASK_APP=superset
flask fab create-admin
superset init //如果没有执行 superset init，那么虽然创建成功了用户，但是用户登录之后，superset的界面不能正常打开，使用浏览器debug会发现没有权限加载某些元素 

```

##### 测试环境部署，生产环境请跳过此步骤
在测试环境中，可以用下面的方法快速部署
```
# Load some data to play with
superset load_examples 

# Create default roles and permissions
superset init

# To start a development web server on port 8088, use -p to bind to another port
superset run -p 8088 --with-threads --reload --debugger

```

##### 在生产环境中使用gunicorn部署WSGI HTTP Server

在调试的时候，可以先不加 -D参数，等配置完成之后，再加-D将其放到后台
```
gunicorn -w 10 --timeout 120 -b  0.0.0.0:6666 --limit-request-line 0 --limit-request-field_size 0 "superset.cli:create_app()"
```

##### 使用nginx 做前端转发
安装nginx并修改nginx配置文件，添加proxy_pass转发
```
sudo yum install -y nginx // sudo amazon-linux-extras install nginx1.12 -y
sudo vim /etc/nginx/nginx.conf
sudo systemctl restart nginx
```
在http-server80 --location处修改
```
        location / {
                proxy_pass http://127.0.0.1:6666;
        }
```

##### 登录到superset上
用户名和密码为先前 flask fab create-admin 这个命令创建的
http://nginx_ip/

##### 安装mysql和aws athena连接driver
在superset网页界面的Sources--database中可以添加mysql,athena,bigquery等数据库。但默认情况下，并没有driver，需要手动安装。

先退出gunicorn启动的进程，然后使用pip来安装（venv环境中的pip）。具体安装的命令参考：https://superset.incubator.apache.org/installation.html#database-dependencies

以Athena示例：
``` pip install PyAthena -i https://pypi.douban.com/simple ```
安装之后，默认只能连接global的Athena，无法连中国区，连宁夏区域Athena，要修改一下配置文件。在venv路径下：venv/lib/python3.7/site-packages/pyathena/，修改sqlalchemy_athena.py 这个文件，在第233行添加.cn后缀，即改为：'region_name': re.sub(r'^athena\.([a-z0-9-]+)\.amazonaws\.com\.cn$', r'\1', url.host)
详情
```
        #   {schema_name}?s3_staging_dir={s3_staging_dir}&...
        opts = {
            'aws_access_key_id': url.username if url.username else None,
            'aws_secret_access_key': url.password if url.password else None,
            'region_name': re.sub(r'^athena\.([a-z0-9-]+)\.amazonaws\.com\.cn$', r'\1', url.host),
            'schema_name': url.database if url.database else 'default'
        }
```

重新启动gunicorn，并刷新一下Superset网页
``` gunicorn -w 10 --timeout 120 -b  0.0.0.0:6666 --limit-request-line 0 --limit-request-field_size 0 "superset.cli:create_app()" ```

添加一个DB，测试成功之后，网页弹窗显示：Seems OK!
``` awsathena+rest://AWS_AK:AWS_SK@athena.cn-northwest-1.amazonaws.com.cn/default?s3_staging_dir=s3://xlaws/athena_temp/ ```

添加MySQL示例：
``` 
sudo yum install mysql-devel
pip install mysqlclient -i https://pypi.douban.com/simple  \\mysqlclient 依赖于mysql-devel
```
这次把gunicorn放在后台(加上-D参数)，同时启用access_log和error_log

```
gunicorn -w 10 --timeout 120 -b  0.0.0.0:6666 --limit-request-line 0 --limit-request-field_size 0 "superset.cli:create_app()" --access-logfile access_log --error-logfile error_log -D
```

添加mysql的数据源:
``` mysql://DB_USERNAME:DB_PASSWORD@dbmysql.ckvg6d2mvjkp.rds.cn-northwest-1.amazonaws.com.cn ```

最后可以在Sources中添加table，然后可以根据自己的需要构建Charts和Dashboard。


* 关闭gunicorn进程
  
```
ps aux | grep  "gunicorn" | grep -v 'grep' |  awk '{print $2}' | while read line; do kill -9 $line; done;

也可以创建配置文件，将gunicorn放在系统服务中，参考:
https://blog.csdn.net/liangkiller/article/details/101299753
```

##### 使用Redis做Cache，使用MySQL RDS做metastore
使用pip安装redis，这样Superset才能连到redis上
``` pip install redis -i https://pypi.douban.com/simple ```

在PYTHONPATH路径下，创建一个[superset_config.py](https://github.com/apache/incubator-superset/blob/master/superset/config.py)文件.
获取PYTHONPATH路径的方法：
进入python3 shell

```
import sys
print(sys.path)
```

在superset_config.py文件中，指定mysql和redis的地址端口以及用户名密码

```
SQLALCHEMY_DATABASE_URI = 'mysql://DB_USER:DB_PASSWORD@dbmysql.ckvg6d2mvjkp.rds.cn-northwest-1.amazonaws.com.cn/superset'
CACHE_CONFIG = {
        "CACHE_TYPE": "redis",
        "CACHE_REDIS_URL": "redis://redis-log-cache.pe5q7k.0001.cnw1.cache.amazonaws.com.cn:6379/0",
        "CACHE_KEY_PREFIX": "SUPERSET_",
}
```
之后要重新初始化数据库
```
superset db upgrade
export FLASK_APP=superset
flask fab create-admin
superset init
```

重新启动gunicorn进程:
``` gunicorn -w 10 --timeout 120 -b  0.0.0.0:6666 --limit-request-line 0 --limit-request-field_size 0 "superset.cli:create_app()" -D ```

创建database，table，chart，dashboard之后，登录到mysql和redis，可以看到已经有数据写入.

##### Superset高可用
创建另外一个superset，指定redis和mysql，然后前端挂载负载均衡器，测试当任意一台Superset宕机，另外一个superset都能正常提供服务，且之前创建的dashboard等信息依然保留。

##### 故障排查
在使用Superset和AWS Athena集成的时候，遇到botocore版本冲突的报错，具体报错信息为：
pkg_resources.ContextualVersionConflict: (botocore 1.15.26 (/home/ec2-user/venv/lib/python3.7/site-packages), Requirement.parse('botocore<1.16.0,>=1.15.27'), {'boto3'})

此时出问题的boto3和botocore版本为：
```
boto3                  1.12.27
botocore               1.15.26
```

另外一台正常使用的boto3的版本为：
```
boto3                  1.12.26
botocore               1.15.26
```

解决办法为：
``` pip install boto3==1.12.26 --upgrade -i https://pypi.douban.com/simple ```


##### 在AWS上使用CloudFromation部署SuperSet
链接：https://github.com/liualexiang/learninguide/blob/master/Superset/Superset_CloudFormation/Superset_on_EC2.template

##### 在AWS上使用terraform部署superset
链接：https://github.com/liualexiang/learninguide/tree/master/Superset/Superset_on_EC2_Terraform

##### 参考资料
https://superset.incubator.apache.org/installation.htm
https://docs.gunicorn.org/en/stable/run.html#integration
