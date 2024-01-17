# 自动化测试pytest

## Pytest 的默认命名规范

* 类名必须Test开头
* 类里方法名必须 test_开头或者 _test 结尾
* 文件名必须 test_开头

## 入门示例

创建一个all.py文件，同时创建一个user文件夹

```python
import pytest  
   
if __name__ == "__main__":
    pytest.main(["-sv","./user", "-n=2"])
```

在user文件夹下，创建一个 test_get_user.py文件

```python
class TestGetUser:
    def test_get_user(self):
        print("test get user function")
```

此时pytest会执行 user 文件夹下的所有测试case，当然如果main 函数里不指定参数也是可以的，则会执行当前文件夹以及遍历其子文件夹下的所有测试案例。

如果使用pytest cli那么命令为 ``` pytest -sv ./user ```

如果想要用多线程的话，可以加上 -n 参数，比如 ``` pytest -sv ./user -n 2```

如果想要让测试案例失败的时候，重跑，那么main函数里可以加 "--reruns=2"，这样当失败的时候，会再重试2次(一共3次)



## 简化版

比如下面的目录结构，mymath.py里只有一个 add(num1, num2) 函数，在pycharm里，将 src 和test所在的目录，设置为 Source Root，

```shell
.
├── src
│   └── mymath.py
└── test
    └── all.py
```

all.py 的内容为

```python
from src.mymath import add

def test_add():
    result = add(3,4)
    assert result == 7
```

那么只需要执行下面的测试命令即可

```shell
python -m pytest test/all.py
```

