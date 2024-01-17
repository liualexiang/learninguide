# IDE配置

## Pycharm 

### Pycharm配置

为了性能和内存分配，默认情况下，jetbrains的IDE工具，对于打开的appcode的限制值是20000KB (20MB)。在有时候我们按CTRL键，却无法打开所使用的库的源代码，可以通过调整下面的参数来解决

help --> edit custom properties

```
idea.max.intellisense.filesize=35000
```

参考链接: https://www.jetbrains.com/help/objc/configuring-file-size-limit.html#file-length-limit

### Pycharm 配置 python 项目路径

在创建python project之后，在相应的root文件夹上右键，选择 Make Directory As --> Source Root，这样在子文件夹下 import的包能够正常显示 (默认情况下，子文件夹下import包的顺序，也是从项目的Root文件夹下开始的)。如果不设置source root，那么子文件夹下import的包，IDE会找不到报错

### Pycharm快捷键

在看代码的时候，Mac系统的 command + \[ 是后退， command + \] 是前进





