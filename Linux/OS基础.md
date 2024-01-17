# OS 基础

## nohup 和 & 区别

nohup 和 & 的区别，& 只是放到后台而已，任务的父进程依然是当前shell，如果将shell关闭，则进程关闭。nohup才是将父进程设置为 1号进程



## shell 基础

在 linux shell中，下面两种写法是等效的

```
. a.sh
source a.sh
```

在执行一个脚本的时候，有时候希望切换到脚本的路径，同时获取当前路径(脚本执行环境会进行切换，并不影响外部shell的路径，除非使用source引用这个文件)，那么一般有两种写法

```
cd $(dirname "$0") && pwd

cd $(dirname "${BASH_SOURCE[0]}") && pwd
```

