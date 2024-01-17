# Terraform 基础

## 入门

### 下载安装Terraform
[Terraform](https://www.terraform.io/downloads.html) 为一个二进制文件，只要下载下来放到PATH路径下即可使用.

Terraform基本使用：
在下载好tf文件之后，直接执行下面的命令即可部署，如果在当前路径下有多个tf文件，则按照字母顺序执行

```
terraform init
terraform apply

terraform destroy //删除terraform资源
```

### Terraform 的基本配置
###### 环境变量配置
Terraform可以配置环境变量，也可以不配置。如果配置环境变量的话，可以将环境变量保存到variables.tf这个文件中。变量可以指定不同的数据类型，比如list，set, map等格式，详情参考： https://www.terraform.io/docs/configuration/variables.html

示例配置文件
```
variable "region" {
    default = "cn-north-1"
}

variable "profile" {
    default = "default"
}
```
### terraform中代码区间的说明

* resource 指的是要创建什么资源，引用resource的输出，直接用resource.xxx就可以. 示例如下，引用name的时候需要指定 azurerm_resource_group.example_rg.name
```
resource "azurerm_resource_group" "example_rg" {
  name     = "example-rgname"
  location = "East US 2"
}
```
* data 指的是获取现有的配置的属性，引用data的输出，要使用data.xxx.xxx这种方式，示例如下，引用name的时候要指定 data.azurerm_ssh_public_key.pub_key.name
```
data "azurerm_ssh_public_key" "pub_key" {
    name = "alex"
    resource_group_name = "xiangliu_csa"
}
```

### 将结果通过output打印出来
如果想要获得resource执行的结果，那么可以通过output进行打印，在创建module的时候，也是通过 output来实现传参的

```
output "vpc_id" {
  value = aws_vpc.terraform_vpc.id
}
```

### Terraform Doc

terraform-docs 是一个产生 terraform doc的很好的工具，在编写terraform module的时候，会根据 variable 以及 output，自动产生对应的文档。

```shell
brew install terraform-docs
terraform-docs markdown . > README.md
```

### Terraform Console

直接输入 terraform console 就可以进入 terraform 控制台界面，在这里可以进行调试。但是没办法在console里定义变量，所以需要先在当前路径下创建好 .tf 文件，在 .tf 文件里定义变量，此时对于调试来说，有点不方便。可以推荐 terraform-repl 这个第三方程序进行调试





## terraform 使用技巧

1. 验证tf文件是否有语法错误：terraform validate

2. 调用其他workspace的state文件

   ```
   data terraform_remote_state “xxx” {
    backend = “"
   }
   ```

3. 列出workspace: terraform workspace list

4. 控制日志 TF_LOG 控制terraform 的log

5. 使用编程语言来更高级的使用tf：https://www.pulumi.com/

## terraform module 开发

* 当频繁创建某些资源，且这些资源需要有相同的配置信息，或者要求创建的资源必须有某个tag。这种情况下，可以创建module，将配置信息写在module里面，这样调用module创建资源的时候，就自动复用了之前的代码，自动创建了tag。
* module 还能规范资源的创建，比如在module里，指定创建资源的名字为 ${var.project}-${var.env}-${var.service}，这样创建出来的资源名字就是这样的规范。
* 虽然module可以规范命名，但在后期维护的时候，有时候要对资源进行搜索，使用上述方法可能并不能直接搜到，所以如果创建resource的时候，有description的字段，在description字段里指定真实值。

开发一个module非常简单，按原来写创建resource的方式创建资源，只是资源的名字用某一个变量，而不给这个变量赋值。然后引用module的时候进行赋值即可。

通过创建一个 nginx docker 的module来进行测试。首先我们创建一个modules的文件夹，在这个文件夹下创建一个 docker_container 的文件夹，这个docker_container 文件夹会作为module的source名字被引入。在docker_container 文件夹下，可以创建 main.tf 和 variables.tf，将变量写到 variables.tf 文件中，将主代码写到main.tf 中。当然，实际上，也可以全部都放在一个文件中，文件名也可以随意写。

示例 variables.tf

```HCL
variable "container_name" {
    description = "docker name"
    type = string
}
```

示例main.tf

```HCL
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Pulls the image
resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_container" "foo" {
  image = docker_image.nginx.latest
  name  = var.container_name
}
```

创建资源的时候，创建一个 test_container.tf，内容如下

```HCL
module "dockertest" {
    source = "./modules/docker_container"
    container_name = "nginx_test"
}
```

之后用terraform plan和terraform apply执行。

### 开发module注意事项

* 将module的相关文件放在同一个文件夹内，然后在创建资源引用模块的时候，source里指定这个文件夹位置。

* module 后面跟的名字是可以随便写的，引用的模块主要是source位置

* module里尽量不要hard code一些变量，将变量都放到variables.tf里，然后在创建资源的时候通过参数传过去。另外module里不一定有 provider 信息，这样在创建资源的时候，会引用资源文件所在的目录里的 provider信息。

* 在写module的时候，如果在module文件的resource里，已经引用了某个参数，尽管这个参数在resource里是可选的，但如果 variables.tf 文件里并没有设置default值，这时候引用这个module的时候，这个参数就变成了required，必须指定值，否则会报错。这也就意味着，比如要求创建资源，必须有tag，那么只需要在module定义的时候，指定下tag，variables里也不需要给tag赋值，就达到了引用这个module必须指定tag的要求。

  示例：module文件里指定了dns

  ```HCL
  resource "docker_container" "foo" {
    image = docker_image.nginx.latest
    name  = var.container_name
    dns = var.dns
  }
  ```

  variable文件里定义了dns，但没赋值

  ```HCL
  variable "dns" {
      description = "docker dns"
      type = list(string)
      # default = ["8.8.8.8","8.8.4.4"]
  }
  ```

  通过module创建资源的时候，必须指定dns

  ```HCL
  module "dockertest" {
      source = "./modules/docker_container"
      container_name = "nginx_test"
      dns = [
          "114.114.114.114",
          "8.8.8.8"
      ]
  }
  ```



## Terraform 对shell命令的操作

在使用terraform 的过程中，有时候需要和本地进行交互操作。比如有时候需要在本地创建个文件，文件中的内容有引用terraform的变量，且这个文件创建好之后需要执行shell命令，比如通过git命令上传到git repo里等。这时候可以用 local_file 来创建文件， 文件内容也可以引用 templatefile() 来进行模版化，之后再使用 terraform 的 local-exec provisoner执行shell命令，将文件上传到git repo。有关file的使用点击[这里](https://www.terraform.io/docs/language/resources/provisioners/file.html)，有关local-exec使用点击[这里](https://www.terraform.io/docs/language/resources/provisioners/local-exec.html)

* 示例：创建一个空资源，调用本地的 aws cli 命令，将查询到的EC2信息保存到本地的describeEC2.txt 文件中

  ```HCL
  resource "null_resource" "none" {
    provisioner "local-exec" {
      command = "aws ec2 describe-instances --region ap-northeast-1 --profile custody-preprod > data/describeEC2.txt"
    }
    # depends_on = [local_file.testbash] # 如果需要dependson的话可以指定
  }
  
  ```

  

## terraform 的if语句

terraform不是一个图灵完备的开发语言，没有办法直接实现if else，或者while ，case等语句，但可以通过count 来判断一个变量是否存在，如果存在，则count=1，即开始创建资源，否则count=0

```
resource "aws_iam_role_policy" "secrets_permission" {
    count  = length(var.secrets_permission) != 0 ? 1 : 0
    role = aws_iam_role.task_role.name 
    policy = templatefile("${path.module}/policies/secret_manager.json.tmpl",{ secert_arns = var.secrets_permission })
}
```

或者

```
resource "aws_iam_role_policy" "secrets_permission_rw" {
    count  = var.secrets_permission_rw ? 1 : 0
    name = secrets_permission_rw"
    role = aws_iam_role.task_role.name 
    policy = file("${path.module}/policies/secret_manager_rw.json")
}
```

在资源创建的时候，可以用 count 做判断，但是如果只是给其中某一个变量赋值的时候做判断，此时要用 for_each做判断。参考下文 block 动态创建

### Terraform 的for 循环

如果有两层for循环，第二层for循环，如果返回值是一个 map (看for循环后面是否有 => ，如果有，就是map)，那么第一层for循环后面就一定要包含 map{} 的数据类型，当然也可以是map{}的超集，比如list(map{})。如果第二层for循环没有 =>即返回值不是map{}，那么第一层for循环就不需要包含map，可以直接使用list[]

```hcl
locals {
  sg_rules = {
    sg8080 = {
      sg_source   = ["10.0.0.0/16", "192.168.0.1/32"]
      sg_id       = "sg-123456"
      from_port   = 8080
      to_port     = 8080
      source_type = "sgid"
      protocol    = "tcp"
      description = "allow 8080"
    },
    sg8088 = {
      sg_source   = ["172.10.0.0/16","172.12.0.0/16"]
      sg_id       = "sg-123456"
      from_port   = 8088
      to_port     = 8088
      source_type = "sgid"
      protocol    = "tcp"
      description = "allow 8088"
    }
  }
}

## 如果想要将sg rules给彻底展开，形成4段sg的配置，可以参考如下:
# 方法一：将结果放到 map 里，map的key是sg8080_0，sg8080_1这类，然后map的value是真正的rule规则。
locals {
  merged_sg_rules = flatten([
    for rule_name, rule in local.sg_rules : {
      for idx, source_rule in rule.sg_source : "${rule_name}_${idx}" => {
        sg_source   = source_rule
        sg_id       = rule.sg_id
        from_port   = rule.from_port
        to_port     = rule.to_port
        source_type = rule.source_type
        protocol    = rule.protocol
        description = rule.description
      }
    }
  ])
}

或者也可以直接将生成的结果放到一个list里
locals {
  merged_sg_rules = flatten([
    for rule_name, rule in local.sg_rules : [
      for idx, source_rule in rule.sg_source :  {
        sg_source   = source_rule
        sg_id       = rule.sg_id
        from_port   = rule.from_port
        to_port     = rule.to_port
        source_type = rule.source_type
        protocol    = rule.protocol
        description = rule.description
      }
    ]
  ])
}
```





### Terraform 有关block动态创建

进行逻辑判断，可以通过 dynamic 实现。dynamic 里面，要有一个 for_each 循环，但我们可以根据这个循环，加上逻辑判断，如果为true，则创建，否则则不创建。由于for_each是对一个list进行的操作，因此我们让返回值为一个 list []，里面存放任意一个元素就可以，比如存放为 ["true"]，或者 ["abc"]都可以。另外，如果某一个resource里面的某个字段为 null，那么就相当于没有这个字段。如下面的示例， target_group_arn 和 "redirect" {} 是互斥字段，但如果 target_group_arn 有值，redirect 不创建出来；或者target_group_arn为null，但 redirect {} 创建出来，那么都是可以的

```
resource "aws_lb_listener" "ecs_farget_http" {
  load_balancer_arn = module.ecs_farget_alb.alb_arn
  port              = var.dispatcher_port
  protocol          = "HTTP"

 dynamic "default_action" {
   for_each = length(var.http_listner_action.type) > 0 ? ["yes"]: []
   content  {
     type             = var.http_listner_action.type
     target_group_arn = var.http_listner_action.type == "forward"?  module.ecs_farget_alb.tg_arn : null

     dynamic "redirect" {
       for_each = var.http_listner_action.type=="redirect" ? ["yes"] : []
       content {
           host        = var.http_listner_action.host
           path        = var.http_listner_action.path
           port        = var.http_listner_action.port
           protocol    = var.http_listner_action.protocol
           query       = var.http_listner_action.query
           status_code = var.http_listner_action.status_code

       }
     }
   }
 }
}
```



## Terraform State 

如果一个资源已经被terraform创建，但后期不想通过 terraform 管理，可以先通过 terraform state list将这个资源列出来，然后执行 terraform state rm 将其从state 文件中删除

```
➜ -qa git:(alex.l) ✗ terraform state list | grep flasknginx | grep service_discovery
module.flasknginx_farget.aws_service_discovery_service.ecs_service_discovery

➜  qa git:(alex.l) ✗ terraform state rm module.flasknginx_farget.aws_service_discovery_service.ecs_service_discovery

# 远程的state也会被删除
```



如果创建一个资源的时候，不小心起错名字，但资源已经创建，后面如果改名，就需要重新创建，会比较麻烦。那么可以用 state mv 的方式，对资源名进行修改。比如

```
# 先list出资源
 terraform state list
 
 # 通过 terraform state mv 进行修改
 terraform state mv module.aa.aws_vpc.vpc module.bb.aws_vpc.vpc
 
```

在新版本的terraform 中，对于state的管理，可以在 tf 文件里，通过 mv 命令进行管理，方便做 pr review



## Terraform CLI Version管理

可以下载安装 tfenv 对多个terraform 客户端的版本进行管理

```
brew install tfenv
tfenv list
tfenv list-remote
tfenv install 1.0.7
tfenv use 1.0.7

```



## TFE State 迁移

1. 将TFE workspace从一个organization迁移到另外一个organization

2. 创建相同的workspace，要保证版本以及环境变量都一致，VCS也一致

   ```
   terraform init -migrate-state
   ```
