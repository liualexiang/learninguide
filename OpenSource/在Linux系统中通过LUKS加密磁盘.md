#### LUKS 介绍

LUKS(Linux Unified Key Setup)为Linux硬盘分区加密提供了一种标准，它不仅能通用于不同的
Linux发行版本，还支持多用户/口令。因为它的加密密钥独立于口令，所以如果口令失密，我们可以
迅速改变口令而无需重新加密整个硬盘。通过提供一个标准的磁盘上的格式，它不仅方便之间分布的
兼容性，而且还提供了多个用户密码的安全管理。必须首先对加密的卷进行解密,才能挂载其中的文件
系统。 

文件系统在加密层之上，当加密层被破坏掉之后，磁盘里的内容就看不到，因为没有设备对
它解密

crypsetup工具加密的特点： 
（1）加密后不能直接挂载 
（2）加密后硬盘丢失也不用担心数据被盗 
（3）加密后必须做映射才能挂载

#### 使用LUKS加密非系统卷

LUKS加密的时候，会擦出现有卷中的数据，因此一定要做好数据备份.

使用LUKS加密卷演示:

1. 使用 ```sudo -i ``` 切换到root 用户
2. 使用 ```lsblk``` 命令列出当前卷，如:
   
   ```
   [ec2-user@ip-10-10-1-212 ~]$ lsblk
   NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
   xvda    202:0    0    8G  0 disk
   └─xvda1 202:1    0    8G  0 part /
   xvdf    202:80   0  100G  0 disk
   ```
3. 使用 ```cryptsetup luksFormat ```格式化卷
   
   ```
   [root@ip-10-10-1-212 ~]# cryptsetup luksFormat /dev/xvdf
   ```

WARNING!
========

This will overwrite data on /dev/xvdf irrevocably.

Are you sure? (Type uppercase yes): YES     //要输入大写的YES
Enter passphrase:
Verify passphrase:

```
1. 使用```cryptsetup open ```对卷进行解密(以后卸载卷或者重启机器都要输入密码)，mydev可以随便输入
```

[root@ip-10-10-1-212 ~]# cryptsetup open /dev/xvdf mydev
Enter passphrase for /dev/xvdf:

```
5. 格式化文件系统为xfs格式，也可以通过-t参数指定为ext2,ext3,ext4.
```

[root@ip-10-10-1-212 ~]# mkfs -t xfs /dev/mapper/mydev
meta-data=/dev/mapper/mydev      isize=512    agcount=4, agsize=6553472 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=0
data     =                       bsize=4096   blocks=26213888, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=12799, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

```
6. 挂载磁盘
```

[root@ip-10-10-1-212 ~]# mount /dev/mapper/mydev /mnt

```
#### 帮助
帮助命令
```

cryptsetup --help
cryptsetup luksFormat --help

```
帮助文档:
https://wiki.archlinux.org/index.php/Dm-crypt
https://gitlab.com/cryptsetup/cryptsetup/wikis/FrequentlyAskedQuestions
```
