# Python 的坑

在定义一个方法的时候，如果给了默认参数，默认参数的数据类型是一个可变类型，一定要小心。因为python会将这个参数的值保存下来，在另外一次调用的时候与其赋值

```python
def get_user(name, users=[]):
    users.append(name)
    print(users)


if __name__ == "__main__":
    get_user("a")
    get_user("b")
    print(get_user.__defaults__)
```

解决办法是：使用不可变参数，如将其设置为None，然后判断如果是None，就使其变成list就可以了

```python
def get_user(name, users=None):
    if users is None:
        users = []
    users.append(name)
    print(users)


if __name__ == "__main__":
    get_user("a")
    get_user("b")
    print(get_user.__defaults__)
```

