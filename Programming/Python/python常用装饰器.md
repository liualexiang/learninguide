# python 常用装饰器

## 实例方法，类方法，静态方法

默认情况下创建的就是实例方法，这也就是在默认类方法里要有 self 的原因，这个self则代表了被实例化后的类object。因此可以调用实例化后类的一切属性和方法。比如\_\_init\_\_ 这个方法里的属性等。

类方法 @classmethod：则不需要进行实例化就能调用（也可以实例化调用），但是类方法不能调用实例化后的属性，比如 \_\_init\_\_ 方法里定义的属性就无法获取。类方法里的函数传的是 cls，而不是self

静态方法 @staticmethod：只是将一个普通方法放到类里而已，没办法获取类以及实例化后的任何属性和方法

**总结**：classmethod 的方法，不能访问 \_\_init\_\_ 方法里的任何属性和方法，可以在不初始化类的时候调用这个方法，也可以在初始化之后调用。而类的实例方法，必须在类实例化之后才能调用

### 类实例方法

和 classmethod 以及 staticmethod想对应，在默认情况下，不使用任何装饰器，类里的方法，就是类实例方法，顾名思义，一般是类实例化之后，使用的方法。但实际上，类实例方法，在类不实例化的情况下，也能调用。但是在没有实例化的时候，直接调用类实例化方法，在方法里使用了实例化之后的某些属性或方法，则会报错 (指的是引用了self.xxx)。

示例：在下面A的类中，并没有实例化，但直接引用了 sayhello的方法，并不会报错，但如果sayhello里，引用了类实例化的属性self.a，则就报错了

```python
class A:
    def __init__(self):
        self.a = "self_a"
    def sayhello(self, something):
        print("I'm saying %s" % something)
        # print("I get get self.a, it's %s" % self.a)

A.sayhello("xx",something="ss")
```

在类实例化方法中，在 \_\_init\_\_方法里，定义的属性或方法，主要是用于下面多个类方法的相互传递，比如有 sayHello()方法，生成的某些属性或方法，想要传递给 run() 方法里，那么就可以在 sayHello()方法的返回值里，返回成 self.xxx，之后 run() 方法就能引用了

### classmethod

classmethod 类方法， 可以实现在不实例化类的时候，就能实现类的方法。同时 cls 也能接收类本身的参数，但没法接收类实例化的 \_\_init\_\_ 方法的参数或属性。

在工厂方法里特别常用，比如用户可以通过不同方式创建类实例的替代构造函数，而无需创建额外的构造函数

还有一种用法是给类当作数据类使用，然后修改这个类的属性

```python
class A:
    name = "aa"

setattr(A, "name", "bb")
print(A.name)
```

## staticmethod

staticmethod 静态方法，也是可以在不实例化的时候，使用该方法。staticmethod没办法获得和调用类本身的属性和方法，也没法获得实例化的时候\_\_init\_\_ 方法里的属性。该装饰器有点像是把类外部方法放到了类里，但没法调用和访问类里的一切。只是组织管理代码的一种方式而已。



## abstractmethod

python中并没有像java 的interface的这种概念。java 的interface可以定义一个接口，但不用具体实现接口的实际内容，由创建某一个class implement interface 的方式来override接口具体内容。python可以通过抽象类来实现，抽象类需要导入一个 abc 的库，在抽象类中定义的方法，在实现的类上必须将其实现，否则会报错。需要学习设计模式以了解更多

```python
from abc import ABC, abstractmethod
class User(ABC):
    @abstractmethod
    def get_name(self, name: str) -> None:
        pass
class Boy(User):
    def get_name(self, name: str) -> None:
        print(f'用户名是:{name}')
u1 = Boy()
u1.get_name(name='alex')

```

## dataclass

dataclass数据类：用于快速创建一个类似 C/C++/C# 等语言所支持的 结构体 struct的数据载体。主要关注数据的操作。

dataclass并非是python的内置方法，需要 ```from dataclass import dataclass``` 导入。在使用 ```@dataclass``` 装饰器对 class进行修饰的时候，实例化class的时候，必须同时进行赋值。

这个装饰器还有一个好处，就是能对类的 \_\_repr\_\_ 方法进行修改，使print 类的时候，不是直接返回类的地址，而是直接能看到类的属性以及值，显示结果更友好

在dataclass中，还可以根据属性进行对比(需要对dataclass引入 order=True的参数)，默认情况下，是将属性都放到元组里，对元组进行对比，我们也可以选择对某一个字段对比，比如只对Age对比，那么可以将 Name的compare设置为 False

这种开发方式属于声明式开发，是属于现代开发的一个发展结果。类似 k8s的yaml定义，只需要定义好最终的执行结果，然后k8s会根据定义执行成我们想要的效果。

```python
from dataclasses import dataclass, field
@dataclass(order=True)
class D:
    Name: str = field(compare=False)
    Age: int
d1 = D("alex",32)
d2 = D("jack", 31)
print(d1 > d2)
```

使用 dataclass 还可以轻松的将实例化的对象变成不可变对象，我们只需要加上 frozen=True就可以了

```python
@dataclass(frozen=Ture)
```

## property

使用 property 可以允许我们通过操作属性的方式，去操作类里面的方法，使用起来更简洁。使用property也体现了OOP里的封装的特性

```python
class Square:
    def __init__(self):
        self._side = None
    @property
    def side(self):
        return self._side
    @side.setter
    def side(self, side: int):
        assert side > 0, '边长不能为负数'
        self._side = side
    @property
    def area(self) -> int:
        return self._side * self._side
        
square = Square()
square.side = 5
print(square.area)
```



### 使用 functools 的 wraps 装饰器

在默认情况下，如果我们创建了一个装饰器，那么当我们去打印执行函数的名字，文档等，返回的是 wrapper 函数的相关信息，而并非原函数的相关内容。当然我们可以通过覆盖的方式，将 wrapper 函数的 \_\_name\_\_ 被原函数覆盖

```python
def printline(func):
    def wrapper():
        print("====")
        func()
        print("====")
    # wrapper.__name__ = func.__name__
    return wrapper

@printline
def printa():
    print("aa")

print(printa.__name__)
```

不过显然上述方法有些麻烦，此时我们就可以借助于 functools.wrapper()函数实现

```python
from functools import wraps

def printline(func):
    @wraps(func)
    def wrapper():
        print("====")
        func()
        print("====")
    return wrapper

@printline
def printa():
    print("aa")

print(printa.__name__)
```



### typing 使用简介

python是一门动态类型语言，为了在开发的时候，更好的写注解，让程序员能更清晰的描述和理解代码，我们可以使用 typing导入对应的数据类型，这样在写程序的时候，IDE也能更友好的给出提示。注意：这个只是一个注解而已，并不强制要求数据类型和注解的一致。比如下面的示例，即使我们把Dict里定义成 int类型，也不会报错

```python
from typing import Dict
def func1(urls: Dict[str, str]) -> None:
    for key, value in urls.items():
        print(key, value)
a = {"baidu":"www.baidu.com", "google": "www.google.com"}
func1(a)
```

