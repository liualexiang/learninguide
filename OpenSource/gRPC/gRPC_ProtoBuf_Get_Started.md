# 有关gRPC和protobuf的理解

## 协议网络传输层的理解
gRPC是跑在HTTP2之上的（可以是明文的HTTP，不加TLS），protobuf可以通过gRPC协议进行传输，使用WireShark抓包分析如下
![demo](./img/protobuf_grpc_wireshark.png)

## gRPC和Protobuf测试环境搭建：

* 安装gRPC的python 模块(runtime)  
``` pip install grpcio ``` 

* 安装grpcio-tools，使用这个工具，可以将.proto文件转换成python代码  
``` pip install grpcio-tools```  

* 创建一个helloworld.proto的文件，proto语法有proto2和proto3，本次示例用的是proto3  

```
// helloworld.proto
syntax = "proto3";

service Greeter {
    rpc SayHello(HelloRequest) returns (HelloReply) {}
    rpc SayHelloAgain(HelloRequest) returns (HelloReply) {}
}

message HelloRequest {
    string name = 1;
}

message HelloReply {
    string message = 1;
}
```

* 使用grpc_tools将.proto文件转换成python代码，下面的代码编译之后，会产生两个文件.  helloworld_pb2.py: 用来和 protobuf 数据进行交互, helloworld_pb2_grpc.py: 用来和 grpc 进行交互  
  ``` python -m grpc_tools.protoc --python_out=. --grpc_python_out=. -I. helloworld.proto ```

  * 也可以使用protoc命令来生成

    ```
    protoc --python_out=. message.proto
    ```

    

* 最后需要编写一个 helloworld的gRPC实现，这个分服务器端和客户端。服务端会监听在50051端口，host一个gRPC(HTTP2)服务，客户端执行的时候，会向这个端口发起gRPC请求   


a. 服务器端：hello_server.py  

``` 
from concurrent import futures
import time
import grpc
import helloworld_pb2
import helloworld_pb2_grpc

# 实现 proto 文件中定义的 GreeterServicer
class Greeter(helloworld_pb2_grpc.GreeterServicer):
    # 实现 proto 文件中定义的 rpc 调用
    def SayHello(self, request, context):
        return helloworld_pb2.HelloReply(message = 'hello {msg}'.format(msg = request.name))

    def SayHelloAgain(self, request, context):
        return helloworld_pb2.HelloReply(message='hello {msg}'.format(msg = request.name))

def serve():
    # 启动 rpc 服务
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    helloworld_pb2_grpc.add_GreeterServicer_to_server(Greeter(), server)
    server.add_insecure_port('[::]:50051')
    server.start()
    try:
        while True:
            time.sleep(60*60*24) # one day in seconds
    except KeyboardInterrupt:
        server.stop(0)

if __name__ == '__main__':
    serve()
```

b.	客户端: hello_client.py  

```
import grpc
import helloworld_pb2
import helloworld_pb2_grpc

def run():
    # 连接 rpc 服务器
    channel = grpc.insecure_channel('localhost:50051')
    # 调用 rpc 服务
    stub = helloworld_pb2_grpc.GreeterStub(channel)
    response = stub.SayHello(helloworld_pb2.HelloRequest(name='czl'))
    print("Greeter client received: " + response.message)
    response = stub.SayHelloAgain(helloworld_pb2.HelloRequest(name='daydaygo'))
    print("Greeter client received: " + response.message)

if __name__ == '__main__':
    run()
```

## 使用WireShark对gRPC进行调试

* 本次只考虑gRPC明文传输，不考虑TLS加密
* 在WireShark首选项中，Protocols中找到Protobuf，然后修改 Profocol Buffers search paths，将.proto 的文件夹，以及protobuf的库文件地址添加进去
![wireshark](./img/protobuf_wireshark.png)

本次测试参考了下文：https://www.jianshu.com/p/43fdfeb105ff?from=timeline&isappinstalled=0

