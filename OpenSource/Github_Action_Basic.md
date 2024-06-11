# Github Action 基础使用

## Github Action 是做什么的？
* Github Action 是一个基于repo的Push或Pull Request触发的事件驱动的workflow，在当前项目的.git/workflow/路径下的以 .yml 后缀的文件中定义工作流。
* 一个工作流中，可以包含有一个或多个job，每个job可以有一个或多个Step。
* Runners是运行workflow的环境，可以使用Github自带的runner(windows,ubuntu,mac, 预装了特定的软件环境)，也可以使用自己的runner环境(只要具备联网能力的机器都可以)。
* Github Action 使用的github host的runner，预装了aws cli，azure cli等各种工具，在通过Github Action做CD的时候，可以将 secrets 放在Github的 repository secret中，然后通过 ${{SECRET_NAME}} 的方式调用。secrets里面的值只有第一次存放的时候能看到，以后就看不到了，因此安全性会更有保障一些，尤其是对于运维人员不可见。

有关Github Action的介绍，参考：https://docs.github.com/en/actions/learn-github-actions/introduction-to-github-actions

## 一个Github Action的示例

* 示例：获取Azure VM的list。有关在workflow中配置azure creds的方法，参考[这里](!https://github.com/Azure/login)

```
name: GitHubAction-Example01

# Controls when the workflow will run
on:
  # Triggers the workflow on push or pull request events but only for the master branch
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  getlocation:
    runs-on: ubuntu-latest
    steps:
      - name: Get GITHUB_WORKSPACE_LOCATION
        run: echo $GITHUB_WORKSPACE
  echotest:
    runs-on: ubuntu-latest
    steps:
      - name: Run a one-line script
        run: echo Hello, world !
      - name: Run a multi-line script
        run: |
          echo echo another line,
          echo echo two more lines.
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
      # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
      - uses: actions/checkout@v2

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{secrets.AZURE_CREDENTIALS}}
          environment: 'AzureCloud'
          enable-AzPSSession: false
          allow-no-subscriptions: false
      - name: Get AZ VM List
        run: |
          az vm list

```

## 有关uses

* 上述代码中的 uses: actions/checkout@v2，相当于 git clone 项目到本地，就不用自己写了，使用起来比较方便.

* 从上述示例中也可以看出， uses可以从github的repo中下载和部署应用，这样就能在环境内配置自己的应用依赖了。比如我们可以用下面的这个示例来配置k8s的kubectl: https://github.com/steebchen/kubectl

## 搜索github action

在将Github的代码部署到某个地方的时候，很多时候网上都有各种大神写好了 actions的插件，可以搜索Github Actions Azure或者 Github Actions AWS，Github Actions Kubectl 等方法直接使用别人写好的插件。

## Github Action的触发

github action支持多种触发途径，比如可以通过 tag 触发，一旦打了tag就执行某个操作

```yaml
name: label create
on:
  push:
    tags:
     - "*"
jobs:
  tagjob:
    runs-on: ubuntu-latest
    steps:
      - name: tag job
        run: |
          echo "hello tag created"
      
```

也可以手动触发，在触发的时候，可以通过文本框传变量，也可以通过下拉框传变量

```yaml
name: manually

on:
  workflow_dispatch:
    inputs:
      username: 
        description: "input your username"
        default: "world"
        required: false
        type: string
      job:
        description: "select job from droplist"
        default: "none"
        type: choice
        options:
          - IT
          - DevOps
          - Dev
        required: true

jobs:
  manuallyjob:
    runs-on: ubuntu-latest
    steps:
      - name: manually trigger event
        run: |
          echo "hello ${{inputs.username}}"
          echo "your job is: ${{inputs.job}}"

```

也可以基于pr 创建，更新pr里的commit来进行触发。甚至在触发的时候，可以调用另外一个 workflow（需要指定这个workflow的yaml文件路径，同仓库，或者跨仓库都可以）

```yaml
name: pr-open-update

on:
  pull_request:
      types: [opened, synchronize] 
jobs:
  call-workflow-in-local-repo:
    uses: ./.github/workflows/reuse-workflow.yaml
  testjob:
    runs-on:  ubuntu-latest
    steps:
    - name: pr open event
      run: |
        echo "this event is created when pr created"

```

上述 reuse-workflow.yaml 在编写的时候，需要on workflow_call事件，比如

```yaml
name: reused-workflow
on:
  workflow_call:
jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: reuse
      run: |
        echo "this is reused workflow"
```



Github Action 里的checkout拉代码，是通过 graft 嫁接commit得方式获得，但是这个 graft commit 也是主分支的commit。我们在github action里获得主分支最新tag

```yaml
      - name: get_tag
        id: get_tag
        run: |
          git fetch --tags
          tag=$(git describe --tags --exact-match)
          echo "latest_tag=${tag}"
          echo "tag=${tag}" >> $GITHUB_OUTPUT
      -
        name: Docker meta
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: myrepo.gcr.io/my_service
          tags: type=raw,value=${{ steps.get_tag.outputs.tag }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          tags: ${{ steps.meta.outputs.tags }}
          push: true

```





## 自己写github action

默认github action可以支持其他仓库，使用的时候为uses: org/repo:tag 的方式调用。github action编写支持Docker，js，以及composite三种方式，在action的git repo里，一定要指定 action.yaml或 action.yml，在这个文件的run里，定义了action runner的入口



## 学习链接:

https://docs.github.com/en/actions/quickstart
https://blog.csdn.net/qq_39969226/article/details/106216566