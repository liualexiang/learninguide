# IO 多路复用

Linux有三种方式实现IO多路复用，分别是 Select, poll和 epoll，但windows 只支持 Select。Select是最早的IO 多路复用技术，后来才有的poll，之后才有 epoll

Select 有一个限制，就是只能支持1024个以内的文件描述符，超出的话就没法监听了。是通过 for 循环实现的。 poll也是类似的，但没有1024个显示。

epoll是通过异步的方式实现的，底层的描述符谁有变化了，谁告诉 epoll，不用程序去做for循环去看描述符的变化了。



## Select IO 多路复用示例

以python程序为例，socket 监听了8001和8002两个端口，使用 select.select 来查看这两个 socket的状态，一旦文件描述符发生变化，就会将变动传送给 r_list 里，其中 e_list 是指有错误的话，会发到这里。select.select 接收的4个参数，第一个指的是，监听哪个list的变化，第二个参数是永久固定的将这个list返回给 w_list，第三个参数指的是有错误发给 e_list，最后一个1指的是每隔1秒检查一次。



```python
import socket, select
s1 = socket.socket()
s1.bind(("127.0.0.1",8001))
s1.listen()

s2 = socket.socket()
s2.bind(("127.0.0.1",8002))
s2.listen()

s_list = [s1, s2]
while True:
    r_list, w_list, e_list = select.select(s_list,[],s_list, 1)
    for sk in r_list:
        conn, address = sk.accept()
        conn.sendall(bytes("ok",encoding="utf-8"))
        conn.close()

    #如果有这一步的话，指的是谁出错，就将其从list里移除
    for sk in e_list:
        s_list.remove(sk)
```

