##### python申请内存
申请内存的方法很简单，可以复制字符“a”指定次数，即可占用系统指定的内存，将下面命令保存成 test.py 脚本
```
import time
GB = 1024 * 1024 * 1024
a = "a" * 20 * GB
time.sleep(3600)
```

##### taskset指定任务跑在那颗cpu上
taskset -c 2 python test.py

##### 验证单颗cpu申请20GB内存
* 查看进程id
```ps -elf | grep test.py```
* 看进程跑在哪个cpu上
  ``` ps -o psr -p 3364 ```
* 查看内存使用情况 
  ```free -h ```
* 或每隔1s打印一次内存情况，可以实时看到内存消耗变化情况
  ``` vmstat 1```