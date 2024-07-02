# Python 的语法糖

## 推导式

从效率上看，推导式生成数据的方式，要比直接写 if 要快一些

### 列表推导式

比如生成0 到100里的偶数

```
list1 = [ i for i in range(0, 101) if i %2 == 0 ]
```

支持推导式的还有 元组、字典和集合

### 字典推导式

```
{ k: 1 for k in range(0,10) }
```

### 集合推导式

集合和列表的区别：不重复

```
{ s for s in range(0,101) }
```

## 三元运算

```python
a = 15
print("a is 15") if a == 15 else print("a is not 15")
```

三元运算的嵌套： 可以先将第一个 if else 摘出来，然后写成三元运算符的 else 部分，也就是下面的 成绩错误的else部分写出来，但成立的部分，是另外一个 if else，而这个if else，则放在刚写出来的if 前面作为成立的部分。

```python
score = 85

if  score in range(101):
    if score < 60:
        print("成绩不合格")
    else:
        print("成绩合格")
else:
    print("成绩错误！")
```

改成三元运算符为

```python
print("成绩不合格") if score < 60 else print("成绩合格") if score in range(101) else print("成绩错误")
```

三元运算符是有返回值的，示例如下

```python
score = 85
status = "ok" if score > 90 else "no"
print(status)
```



### 海象运算符

使用海象运算符，最主要的是能将中间过程存成变量。

1. 将numbers 这个list的每个元素求平方，产生新list

```python
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]

# 海象运算符
[ ( j := i * i ) for i in numbers ]
# 旧的列表推导式
 [ ( i * i) for i in numbers ]
  

```

2. 将下面的list中长度大于4的单词提取出来，并说明其长度

```python
 words = ['apple', 'banana', 'kiwi', 'pear', 'plum']
 [ (word, length) for word in words if (length := len(word)) > 4 ]
```



### assset

通过 asset可以对某个属性值进行约束，asset是一种保护式编程。比如下面的示例，如果年龄不在0-150范围内，就会报错

```
def user(age: int):
    assert age > 0 and age < 150, '年龄不能为负数，也不能大于 150'
user( 20 )
```

### 使用 * 和 ** 进行解包

当我们对list或dict进行遍历的时候，可以用 * 或者 ** 对其进行操作(list 用 \*， dict 用 **)

```python
a = {"a": 1, "b": 2}
b = { "c": 3 , "d": 4}
```

如果只想取 a 和 b 字典中的key，那么用一个* 号，比如

```python
print(*a)
```

合并a 和b 里的key的话，则可以用

```python
{*a, *b}
```

如果想要取字典的全部，包括key 和 value，注意value 也可以是一个字典，或list，那么需要用两个星号

```python
{**a, **b}
```





## 使用 functiontools

### 通过 lru_cache 提高递归效率

比如在进行递归的时候，有时候会有大量的重复计算，比如像计算斐波那契数列，那么可以用 funciotntools 的 lru_cache来提高效率

```python
from functools import lru_cache

@lru_cache()
def fib(n):
    if n <= 2:
        return 1
    return fib(n-1) + fib(n-2)

print(fib(100))
```

如果递归深度超出了限制，那么可以用 sys.setrecursionlimit(5000) 来设置递归深度