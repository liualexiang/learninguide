
## Pytest 的默认命名规范

* 类名必须Test开头
* 类里方法名必须 test_开头或者 _test 结尾
* 文件名必须 test_开头
* 如果想要修改默认的配置，则需要创建一个 pytest.ini 配置文件。无论是主函数模式运行，还是命令行运行，都会读这个配置文件。
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
## coverage
使用coverage可以轻松查看pytest的覆盖率
```python
# run test
python -m pytest test_all.py

# run report by coverage command
coverage run -m pytest test_all.py
coverage report

# get html report
coverage html
```

## pytest 使用

### 改变执行顺序
通过pytest.mark.run 来改变之行顺序，默认情况下，pytest是按函数名从上往下之行的。这个跟unitest不同，unitest是根据函数名ascii顺序执行。
```python
@pytest.mark.run(order=2)
def test_xxx():
	print("xxxx")
```

### 分组执行
如果我们的测试比较复杂，分不同的模块（文件夹），下面分别又有不同的测试样例，我们想测试某些文件夹下特定的某几个文件。比如执行冒烟测试，分接口测试等。

此时可以在需要进行测试的函数上面，通过 @pytest.mark.xxxx 做标记，注意xxx是可以自己随便写的，比如我们写smoke，usermanage, productmanage，即使分布在不同的模块下，不同的函数里，我们也可以在测试的时候，来执行那类标记被执行
```python

@pytest.mark.smoke
def test_aa():
	print("aa")

@pytest.mark.usermanage
def test_bb():
	...

@pytest.mark.productmanage
def test_cc():
	...
```
另外，还需要创建一个 pytest.ini 文件，将这些自定义marker注册进去
```toml
[pytest]  
markers =  
    smoke: anything you can input here
    usermanage: xxxx
    productmanage: xxxx
```

执行的时候输入 pytest -m "smoke" test.py 则只执行 smoke里的样例。如果想一次性执行两个，则是 pytest -m "smoke or usermanage" test.py

### 跳过
如果想要跳过某一个测试用例，则用 pytest.mark.skip 就可以了，这样默认就不执行了 
```python
@pytest.mark.skip
def xxx():
	...
```
在跳过的时候，还可以指定条件

```python
bb=16
@pytest.mark.skipif(bb < 18, reason='小于18')  
def test_bb():  
    print("bb")
```


### pytest.fixture 与setup/teardown
#### setup/teardown 与 setup_class 与 teardown_class
这个方法比较直接，适合简单测试场景
在pytest里面，如果想要在执行测试前，和测试后，做一些事情。比如在测试前，第一步要打开浏览器，测试完成，最后一步关闭浏览器，那么我们就要用到 setup_method和 teardown_method的函数（对每一个测试用例，即每一个函数都执行前后都会执行这个操作），注意函数名必须这么写（小写），如果函数在类里(比如日志对象，数据库连接等)，则是 setup_class 和 teardown_class（在类初始化以及执行完成只做一次）。示例：
```python
import pytest  
  
bb = 20  
  
  
class TestAA:  
  
    def setup_class(self):  
        print("\nsetup class")  
  
    def setup_method(self, method):  
        print("\nsetup class===")  
  
    def test_aa(self):  
        print("aa")  
  
    @pytest.mark.skipif(bb < 18, reason='大于18')  
    def test_bb(self):  
        print("bb")  
  
    def test_cc(self):  
        print("cc")  
  
    def teardown_method(self, method):  
        print("\nteardown method+++")  
  
    def teardown_class(self):  
        print("\nteardown")
```

#### pytest.fixture
pytest.fixture适合更灵活，需要复用参数的复杂测试场景。在fixture里，函数名可以随便起，如果后面的参数想自动引用，则 autouse=True，如果没有，需要将这个函数名作为参数，传给后面真正的方法。
在fixture里，yield相当于会把函数分成两部分，上面是setup，后面是 teardown

```python
class TestMain:

    @pytest.fixture(scope="session", autouse=True)
    def set_env(self):
        os.environ["ES_HOST"] = "mydomain.com"
        os.environ['REGION'] = 'ap-northeast-1'
        yield
        del os.environ["ES_HOST"]
        del os.environ['REGION']

```

#### conftest.py
整个项目中所有需要使用的 fixture 固件，都会放到 conftest.py 文件里，pytest会自动引用，无需手动指定


## Pycharm debug

在 debug python代码的时候，程序会卡在断点的那一样的位置，那一行的代码处于未被执行的状态。pycharm 对查看断点有几个按钮:

step over: 直接执行这一行的代码

step into：进入到这一行代码内部看具体执行过程

Step into my code：跳过系统包和第三方包，只看自己的代码的执行过程。由IDE判断哪些包是第三方。

step out：在 step into 的过程中，将 step into的剩余部分一次性执行完。step into + step out 相当于 step over
