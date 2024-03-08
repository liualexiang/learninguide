# Git 最基本的几个命令

## 初始化git
在一个空目录下，初始化git

```bash
git init
```

在目录中放一些文件，然后添加到本地git中

```bash
git add .
```

检查git状态

``` bash
git status
```

要提交到远程仓库，那么必须先commit一下

``` bash
git commit -m "first commit"
```

如果git commit message写错了，可以用 --amend 修改：
```bash
git commit --amend -m "new message"
```

提交到远程仓库，如果没有配置远程地址，则会报错，解决办法请参考下面的步骤

``` bash
git push origin master
```

如果不小心git add了，要删除add的文件，可以执行
```
# remove all added file
git reset .

# remove single file
git reset filename
```

使用 git stash 将未完成的工作进行暂存
```
git stash
# 或者git stash save "some comments"，暂存之后就看不到当前的改动，然后就可以继续其他工作
git stash list # 查看暂存
git stash pop # 恢复暂存，同时将原来的暂存记录删除
git stash apply [0,1] # 恢复暂存，但不删除暂存记录
```
使用 git cherry-pick 来选择将某个commit merge到当前分支。比如在 dev 分支下，有两个 test1 和 test2分支，然后在test1分支下做了一些修改，已经提交上去，但没有merge到dev分支。这会想要在test2分支下，也应用这个变更。那么可以先用 git log看一下test1提交的commit id，然后cherry-pick选择commit到test2分支
```
git log
git checkout test2
git cherry-pick COMMIT_ID
```
## Git rebase 压缩commit
使用 git rebase -i 命令，可以将多个 commit，压缩成1个commit。比如此时git log里，看到有历史3个commit，想要压缩成一个，那么可以用 git rebase -i HEAD~3 或者 git rebase-i HEAD~~~ 的方式，进行选择。之后会进入交互式界面，在交互式界面，编辑这个commit文件，将其他两个前面的pick改成s，表示squash，然后074c959 和 d38c6aa 就会被压缩到 5f7f01e 里了。如果想要从历史中，删除这两个commit，那么可以将s改成drop。之后保存退出就可以了

```
pick 5f7f01e add d
s 074c959 update b
s d38c6aa add e and f
```
### 使用 fixup 和 autosquash 自动压缩commit

虽然使用 git rebase -i 可以将多个commit压缩成一个，或者在压缩的时候，选择drop commit，但是需要手动操作，且commit message里默认是有其他commit的message，此时我们可以用 git fixup 结合 autosquash帮我们实现.

具体操作方法是：在本地先提交一个commit，然后记下commitid，此时后续的其他变动，git add 之后，都可以使用 git commit --fixup COMMITID 的方式进行提交，然后git log里，我们能看到commit message都是 !fixup开头。

接下来使用 git rebase -i --autosquash 来帮我们自动合并commit，不需要做任何额外操作，我们能看到，默认其他的commit就是fixup的，而不是squash，然后保存，git log就看到只有一个commit了。



## .git 文件夹太大压缩

如果经常对仓库里的文件操作，尤其是对一些大文件，图片之类的操作，那么 .git 文件夹有可能会非常大，比如10多G，甚至更大，可以使用 git gc 命令对其进行压缩

```
git repack -a -d --depth=250 --window=250
```

也可以使用下面的命令(在2007年linus提供的补丁之后，git gc和repack已经没区别了，可以看[Linus的说明](https://gcc.gnu.org/legacy-ml/gcc/2007-12/msg00165.html))

```
git gc --aggressive --prune
```



## Git rebase 进行merge

如果在 master分支下，直接执行 git merge test，则会将 test分支的commit 方到master分支，同时会产生一个新的merge的commit
但是如果在 test分支下，先执行 git fetch origin master，然后 git rebase origin/master (或者执行 git pull origin master --rebase)，则表示将本地的test分支的commit 历史，更新成跟master完全一样的commit历史

## 解决冲突

在git pull origin master --rebase更新本地代码，遇到冲突的时候，git rebase --skip可以让本地代码和远程保持一致，但本地的更改将在分支上丢失.

如果想保留本地，则执行 git checkout --ours . 之后执行git add. 最后执行 git rebase --continue 就可以了



## 配置github的key

在github上创建一个repo，然后在账户设置，SSH and GPG keys里面，添加 ssh pub key
产生ssh public key方法，添加~/.ssh/id_rsa.pub文件内容

``` bash
ssh-keygen -t rsa -b 4096 -C "liualexiang@gmail.com"
```

之后可以测试一下

``` bash
ssh -T git@github.com
```

添加remote origin:
``` bash
git remote add origin git@github.com:liualexiang/learninguide.git

# 使用https方式的话不会走ssh key
git remote add origin https://github.com/liualexiang/aws_transcribe_catpions/
```

然后进行push

```  bash
git push origin master
```

默认情况下，git credential是对所有仓库都生效的，如果有多个git账号，想访问不同的git repo的时候，使用不同的git credential，那么可以启用 useHttpPath，但需要注意的是，一旦启用了，任何新仓库，都会请求credential.

```
[credential]
        helper = osxkeychain
        useHttpPath = true
```



## 将远程git同步到本地

```bash
#在一个空文件夹下，初始化git
git init

# 添加远程repo
git remote add master git@github.com:liualexiang/learninguide.git

#取回数据
git fetch origin

# 此时ls直接看到是空的，checkout到master分支
git checkout master

# 再ls就看到了

```


## git 管理多个github repo
在本地创建另外一个folder，在github上创建好repo
```bash
git init
git remote add new_repo https://github.com/liualexiang/new_repo

git remote //检查新增加的repo，在本路径下放一个文件，然后git add, git commit -m "ss"
git push new_repo mster
```


## Git 多分支管理
```bash
# 创建一个test分支
git branch test
# 切换到test分支
git checkout test
# 查看当前所在的分支
git branch
# 创建文件，然后提交到test分支
touch aa
git add .
git commit -m "add aa file"
git push origin test

# 对分支进行merge，先看一下branch
git branch
# 切换到main分支上
git checkout main
# 将master分支merge到main分支（也就是将master分支的内容复制到main分支，将main分支作为汇总）
git merge master

# 删除远程的分支
git branch -a # 先看下远程分支，比如看到的结果如下，既有本地分支，又有远程分支

* main
  remotes/origin/main
  remotes/origin/master

# 此时我们要删除远程origin下的master分支，命令为
git push origin --delete master
```

## Git 中文显示

默认情况下，git 是无法显示中文的，而是显示八进制的字符。可以通过下面的修改，使git中文可正常显示

```
git config --global core.quotepath false
```



## Git 高级使用方法

1. 使用 git add -p 对同一个文件分段进行上传管理。比如一个文件中，有多处修改，我们在这次执行commit的时候，指向提交部分的修改，不想提交这个文件中的所有修改，就可以使用 git add -p 的方式来将文件添加进去。需要注意的是：如果本次想加入到git中的修改和不想加入的修改是分开在2个不同地方的，那么输入 git add -p FILENAME 后，然后输入 s 就能进行split，之后可以选择需要添加的区块。但如果想添加的地方和不想添加的地方是在一个地方，那么就没有 s 子命令，需要输入 e 手动进行编辑
示例:

```
# 有一个文件c，已经存在git中了，有下面几行
➜  gittest git:(master) cat c
c1
c2
c3
c4
c5
➜  gittest git:(master) git status
On branch master
nothing to commit, working tree clean

# 我们添加三处修改，分别是：添加c11，添加c22，删除c4
➜  gittest git:(master) ✗ cat c
c1
c11
c2
c22
c3
c5
➜

# 那么我们可以执行 git add -p 的命令来选择要添加修改的区块
➜  gittest git:(master) ✗ git add -p c

# 需要输入 s 来进行split，之后会发现自动分割成了3份，我们对c11的修改添加进去，以及删除c4的添加进去，c22不添加，操作方法如下：
(1/1) Stage this hunk [y,n,q,a,d,s,e,?]? s
Split into 3 hunks.
@@ -1,2 +1,3 @@
 c1
+c11
 c2
(1/3) Stage this hunk [y,n,q,a,d,j,J,g,/,e,?]? y
@@ -2,2 +3,3 @@
 c2
+c22
 c3
(2/3) Stage this hunk [y,n,q,a,d,K,j,J,g,/,e,?]? n
@@ -3,3 +5,2 @@
 c3
-c4
 c5
(3/3) Stage this hunk [y,n,q,a,d,K,g,/,e,?]? y

# 那么最终存在git中的是这样的：
c1
c11
c2
c3
c5
```


## git 日志与回滚
```
# 安全方法，会创建一个新的commit
git log
git revert --no-commit 0766c053..HEAD
git commit

# 不安全，因为会将上一个commit给删除
git log
git reflog
git reset --hard commit_id
```

git reset 的时候，如果是 --soft，那么撤销的其他commit的变更，都会放到 暂存区，通过git status能看到。如果git reset --hard，则不会保留到暂存区。同时 git reset --soft HEAD~2 这种方式，可以直接回退2个commit

## 重新提交

正如在 "git 日志与回滚" 片段里提到的，我们可以用 git reset --soft 的方式，对已经提交的commit 进行撤销，撤销之后，在git status里能看到在staged中，处于git add 的状态，此时可以用 git restore --staged . 的方式对git add 进行撤销，然后重新add要提交进去的文件，再进行git commit。

这种方式在对于将 a b c 三个文件都提交到仓库里，但此时后悔了，只想提交a文件，b和c不想提交，此时就可以用git reset --soft COMMIT_ID 或 git reset origin/master 或 git reset HEAD~1 的方式，回退到指定commit，并且保留现有更改，然后再重新git add进行提交

## 撤消回退

在 "git 日志与回滚"中，我们提到可以用 git reset --hard HEAD~1 直接丢弃某一个commit，这个和 git rebase -i HEAD~1 之后，选中commit 进行drop有什么区别呢？

答案是：git reset --hard 的操作是直接丢弃commit，虽然在 git reflog 里能看到，但git reflog是保留在本地的，会自动清理的，不是很安全，如果使用这种方法，git reflog看到commit hash之后，要使用 git checkout或者 git cherry-pick 的方式添加这个commit，也不是很方便。如果使用 git rebase -i 的方式对commit进行操作，那么操作之前的HEAD信息，会保留到 ORIG_HEAD 这个分支下，这是一个特殊的分支，git branch 是看不到的，但如果git rebase -i之后后悔了，可以用 git reset --hard ORIG_HEAD的方式，轻松的撤销 git rebase 的结果，回退到 rebase之前的状态



## 查看某一个文件历史

通过 git blame 可以看文件中所有行的历史，但只能看这一行最后一次是谁修改的。如果想要看一个文件的历史改动，可以用git log。此时能看到文件改动的所有历史

```
git log file.txt
```

然后使用 git blame可以看某一个commit的时候这个文件内容

```
git blame COMMIT_ID -- file.txt
```



## **删除git历史中的一个文件**

现在不推荐使用 filter-branch，建议使用 filter-repo。不过 filter-repo需要单独安装

```shell 
git filter-branch --tree-filter 'rm -f passwords.txt' HEAD
```

如果想要从git 历史中，使用本地的某个文件，对其进行替换

```shell
git filter-branch --tree-filter 'cp /local/path/file1.txt git/repo/path/file1.txt || echo "file1 not found"' -- --all

```

其中 -- --all 指的是，对所有分支都进行修改，如果直接写 HEAD的话，则只对当前分支进行修改



## github pr merge 的三种方式

1. merged pull request:
   1. 这种方式是直接将源分支的一个或多个commit，移动到目的分支，同时再创建一个merge commit
2. squash merge:
   1. 这种方式是将源分支的一个或多个commit，压缩成一个新的commit放到目的分支。注意此事因为目的分支并没有源分支的commit，所以如果源分支下次提交的时候，没有rebase 当前目的分支，那么会将之前变更在pr里继续带上。尤其是如果更改的文件和目的分支不一样，又没有rebase，就会提示冲突
3. rebase merge:
   1. 这种方式是将源分支的一个或多个commit，创建一个或多个commit，放到目的分支

## pre-commit

如果我们本地仓库根目录里有 .pre-commit-config.yaml文件，那么在仓库根路径下执行 pre-commit install 命令，则会自动根据这个yaml文件，生成hooks脚本，放在 .git/hooks/ 文件夹下。但此时需要我们针对每一个仓库目录，在本地都执行这个 pre-commit install 命令。当然我们可以在 ~/.gitconfig 文件里，指定 templatedir 目录，然后将 hooks文件放到这个目录里，这样以后只要 git clone 一个仓库，就会自动将 templatedir 路径下的hooks文件拷贝过来了.



如果想要在 git 提交或合并PR前对代码进行一些检查，我们可以借助于 pre-commit 这个工具来做。首先需要安装一下 pre-commit 这个工具，然后在git项目的根目录，需要存在一个 .pre-commit-config.yaml 文件，将 pre-commit 的一些hook可以在这里定义，然后通过 github action pipeline，对pr 进行检查。

如果想要在本地提交到本地仓库之前，就通过pre-commit进行一些检查，而不依赖仓库的  .pre-commit-config.yaml 文件。此时我们可以通过修改 ~/.gitconfig 里init的templatedir，这样以后 git clone或者git init的时候，会将这个 templatedir 目录下的文件，都拷贝到 项目.git/ 路径下，示例配置

```toml
[init]
templatedir = /home/USERNAME/.git-template/
```

此时我们在 ~/.git-template/文件夹下，创建一个 hooks 文件夹，在里面创建 pre-commit 文件，执行 chmod +x pre-commit 将其设置为可执行文件。之后运行git clone的时候，就会将 hooks文件夹都拷贝到 项目的.git/路径下，而在本地执行 git commit 的时候，就会执行 pre-commit 这个脚本。

当然我们也可以设置 pre-push,  post-update 等脚本，我们可以执行 pre-commit install 命令 ，就会在 ~/.git/hooks/ 文件夹下，产生一些 .sample 结尾的示例文件，可以参考这个文件。

如果想要在本地也执行 pre-commit，可以将这个脚本放到 /home/USERNAME/.git-template/hooks/pre-commit 文件里

```shell

```



## git repo搭建

```shell
# 示例：再home目录下创建一个 repos 目录，然后再这个目录下创建一个 app.git 目录，之后在app.git目录中执行命令
git init --bare

# 在另外一台机器上使用git clone之前的git repo中的内容(以下两种方法都可以)
git clone ssh://username@ip/home/repos/app.git
# git clone username@ip:/home/repos/app.git

# 可以通过ssh-keygen在git server中的~/.ssh/authorized_keys文件中添加public key来实现无密钥登录


```

## 完整 clone git 仓库

如果想要完整clone git 仓库，然后迁移到另外一个仓库里，那么我们再 clone的时候，要加上 --bare 参数

示例：将远程仓库完全clone到本地，并还原成一个可以操作的仓库

```shell
git clone --bare ${base_url} .git
git config --unset core.bare
git reset --hard

```

示例：将远程仓库clone到本地后，再push到远端另外一个仓库

```shell
$ git clone --bare https://github.com/hbdoy/xxx
$ cd xxx.git
$ git push --mirror https://github.com/hbdoy/new_project
```

## Git Config

默认情况下，git 仓库将会用 ~/.gitconfig 配置文件里的配置，如果有多个不同的仓库，想要让部分仓库使用另外的邮箱和用户名，那么可以将这些仓库放在一个特定路径下，然后通过 includeIf 来包含这个路径，然后在这个路径下的repo，都会用另外一个配置文件。想要检查当前repo的git配置，可以直接在仓库路径下输入 git config user.email 或者  git config user.name (需要注意的是，git配置里尽量避免使用 ~，可能导致配置不生效)

```
[user]
        email = username@host.com
        name = username
[includeIf "gitdir:/Users/USERNAME/code/self/"]
        path = .gitconfig-self

[init]
        templateDir = /Users/USERNAME/.git-template
[filter "lfs"]
        clean = git-lfs clean -- %f
        smudge = git-lfs smudge -- %f
        process = git-lfs filter-process
        required = true
[i18n]
        commitencoding = utf-8
        logoutputencoding = utf-8
[gui]
        encoding = utf-8
[core]
        quotepath = false
[credential]
        helper = osxkeychain
        useHttpPath = false
[pull]
        rebase = false
```

如果有多个git 配置文件，那么可以用下面的命令来查看

```
git config --list --show-origin
```

Git 也有一个全局配置

```
git config --system --edit
```

## Git Debug

在执行git 任何命令的时候，如果想要显示更详细的日志，可以在前面加上 GIT_TRCE=1 来显示

```
GIT_CURL_VERBOSE=1 GIT_TRACE=1 git clone xxx
```

