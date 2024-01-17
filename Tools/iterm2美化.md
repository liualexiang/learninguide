# item2 美化



* 几个常用的插件

```
autojump
git
zsh-syntax-highlighting
zsh-autosuggestions
git-open
kubectl
```

## item2状态栏

* 启用状态栏

  item2 --> preference --> Profiles --> Session: 勾选 Status bar enabled

* 更改状态栏位置

  item2 --> preference --> Appearance --> Status bar location

* 自定义状态栏

对于自定义的状态栏，可以用 \\(expression) 做，但如果想从shell里读取环境变量，那么需要安装[shell integration](https://iterm2.com/documentation-shell-integration.html)，安装之后，需要在 shell的rc文件里，执行下这个文件，并可以通过```iterm2_set_user_var``` 来设置变量

```# items status bar
source ~/.iterm2_shell_integration.zsh

iterm2_print_user_vars() {
  iterm2_set_user_var get_aws_profile $( echo $AWS_PROFILE )
  iterm2_set_user_var gitBranch $((git branch 2> /dev/null) | grep \* | cut -c3-)

}
```



## 窗口管理

Command + D 创建一个竖窗口

