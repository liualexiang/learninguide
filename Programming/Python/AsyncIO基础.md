# AsyncIO 基础

## 基础概念

### 同步(synchronous)与异步(asynchronous)

如果任务是同步模式，即使使用了多线程，当任务从线程A切换到线程B，由于是同步阻塞，线程A空闲，线程B开始工作，因此并不能提高效率。

如果是异步的模式，那么任务则可以同时执行

### 并发(concurrency)和并行(parallelism)

并发指的是，可以接受多个任务，表面上看，所有的任务都在同时执行，但是细看，在某一个特定的时间点，只有一个任务在执行。也就是说微观上看是交替运行。

并行指的多个任务同时发生，微观上也是同时做

### 线程(Thread)与协程(Coroutine)

python的多线程，其实本质上是单线程。因为Python中有一个 GIL 全局解释器锁，所以多线程是串行执行的。资源占用率比较高，且开发者不能限制什么时候开始切换线程。

协程又叫做轻线程，本身是在一个线程里执行，资源占用率低，开发者可以自己指定切换的时机。同时由于只有1个线程工作，可以充分利用IO的等待时间。因此使用协程适合IO密集型工作，而不适合CPU密集型工作。

Python的协程，多数时候使用 asyncio实现(python 3.7+)，除了这个之外，还有 TRIO 也可以实现，生成器也可以实现协程。



## AsyncIO 注意点

* aysncio.run 是 python 3.7 才支持的，在python3.5-3.7之间，要用 loop = asyncio.get_event_loop()然后 loop.run_until_complete(task)



## 简单Demo

先使用python创建一个 server，由于 asyncio更多的是在 IO上提高效率，因此不能在异步请求中，直接使用time.sleep

```python
from fastapi import FastAPI
import uvicorn
import time

app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}

@app.get("/timeit/{seconds}")
def timeit(seconds):
    seconds = int(seconds)
    time.sleep(seconds)
    return f"sleep seconds: {seconds}"

if __name__ == "__main__":
    uvicorn.run(app)
    
```

再创建 client，注意不能用print，否则会报错，因为要求这个函数里全部都是 corountine 

```python
import asyncio
import httpx
import time

async def get_time():
    start_time = time.time()
    async with httpx.AsyncClient() as client:
        await client.get("http://127.0.0.1:8000/timeit/2")
    end_time = time.time()
    print("whole time is: ", end_time - start_time)

asyncio.run(get_time())
```

如果是多个请求，那么可以先创建为普通的对象，然后使用 asyncio.gather将task给传进去

```python
import asyncio
import time
import httpx
import requests


async def get_timeit():
    start_time = time.time()
    async with httpx.AsyncClient() as client:
        response = client.get("http://127.0.0.1:8000/timeit/1")
        # print(response.content)
        response2 = client.get("http://127.0.0.1:8000/timeit/2")
        # print(response2.content)
        await asyncio.gather(response, response2)
    end_time = time.time()
    print("total time is: ", end_time - start_time)

asyncio.run(get_timeit())

```



## AsyncIO 详解

### asyncIO 的 task

如果有多个任务，可以通过 asyncio.create_task() 来将任务添加进去，其实也可以创建event loop，然后loop.create_task()来添加

```python
import asyncio
import time

async def real_async(n):
    print("this is real async func")
    s_time = time.time()
    await asyncio.sleep(n)
    e_time = time.time()
    d_time = e_time - s_time
    print(f"end sleep {d_time}")

async def do_it():
    print("invoke real async")
    t1 = asyncio.create_task(real_async(1))
    t2 = asyncio.create_task(real_async(2))
    await t1
    await t2

asyncio.run(do_it())
```

不过这种做法用的比较少，用的比较多的是下面的。将任务放在一个列表里，然后用 await asyncio.wait()，将列表中的任务添加进来，在 asyncio.wait()函数里，还支持 timeout，指定最多等待时长(默认是 None)。这个函数有两个返回值，分别是 done 和 pending

```python
import asyncio
import time

async def real_async(n):
    print("this is real async func")
    s_time = time.time()
    await asyncio.sleep(n)
    e_time = time.time()
    d_time = e_time - s_time
    print(f"end sleep {d_time}")

async def do_it():
    print("invoke real async")
    task_list = [
        asyncio.create_task(real_async(1)), 
        asyncio.create_task(real_async(2))
        ]
    done, pending = await asyncio.wait(task_list, timeout=10)
    print(done)

asyncio.run(do_it())
```

上述 asyncio.create_task 的本质，是在 asyncio.run()的时候，已经创建了一个 event loop，会将task添加到 event loop里。如果我们想直接将任务给 asyncio.run，不创建额外的函数，那么应该按下面的写法

```python
import asyncio
import time

async def real_async(n):
    print("this is real async func")
    s_time = time.time()
    await asyncio.sleep(n)
    e_time = time.time()
    d_time = e_time - s_time
    print(f"end sleep {d_time}")

task_list = [
    real_async(1), 
    real_async(2)
    ]

done, pending = asyncio.run(asyncio.wait(task_list))
```

### asyncio 的 future

asyncio 的 task 在执行的时候，之所以不会一直被 hang 住，是因为在 asyncio.get_running_loop()的loop中，创建了一个 future 对象，这个future 对象如果什么都不做，是会被hang住的，但一旦有 future.set_result() 赋值的时候，就会返回。而task在执行成功之后，就会自动给这个future对象赋值，因此不会hang住。一般我们不会手动的创建future对象，而是直接用task



### concurrent的future

concurrent 里的future对象和 asyncio的future没有任何关系，在使用线程池，或进程池实现异步操作的时候，会用到的。但由于使用协程的时候，await后面跟的对象必须是一个协程对象(或协程task或协程future)，但有些第三方包可能未必支持协程，那这时候就需要将 asyncio 和多 线程/进程  的模块结合起来做异步。

#### 使用 concurrent 模块创建一个基本的多线程

```python
import time
from concurrent.futures import Future
# IO密集的任务,用ThreadPoolExecutor;CPU密集任务,用ProcessPoolExcutor
from concurrent.futures import ThreadPoolExecutor
from concurrent.futures import ProcessPoolExecutor

def func(value):
    time.sleep(1)
    print(value)
    return 123

# 创建线程池
pool1 = ThreadPoolExecutor(max_workers= 5)
# 创建进程池
#pool1 = ProcessPoolExecutor(max_workers= 5)

for i in range(10):
    fut = pool1.submit(func, i)
    print(fut)
```

#### 将asyncio 和 concurrent 多线程结合使用

一个最简单的示例，可以在 asyncio 中，通过 loop.run_in_executor 将 进程池或线程池的future，转换为 asyncio 协程的 future

```python
import asyncio, time
import concurrent.futures
from concurrent.futures import ThreadPoolExecutor

def sleep_it():
    print("sleep 1s")
    time.sleep(1)
    return "sleep 1"

async def main():
    loop = asyncio.get_running_loop()
    fut = loop.run_in_executor(None, sleep_it)
    result = await fut
    print("default thread pool", result)

    # 这个是创建了自定义的线程池，但实际上，上述None默认也是线程池
    with concurrent.futures.ThreadPoolExecutor() as pool:
        result = await loop.run_in_executor(pool, sleep_it)
        print("custom thread pool", result)

    # 创建自定义进程池
    with concurrent.futures.ThreadPoolExecutor() as pool:
        result = await loop.run_in_executor(pool, sleep_it)
        print("custom process pool", result)
        
asyncio.run( main() )
```



### 有关await 和 asyncio.run

await后面只能跟3类对象：

1. 协程对象 (coroutine object)，这里指的是使用 async 定义的函数，返回的对象就是协程对象。他们可以直接用 await 关键字出发执行
1. 可等待的对象 (awaitable object)，可以被await语句使用的对象，其中包括了协程函数，任务和其他抽象基类实现了 \_\_await\_\_()方法的对象。我们可以使用 asyncio.iscoroutine() 或者 asyncio.iscoroutinefunction() 函数来检查对象是否可等待
1. Future对象，asyncio.future 对象表示一个尚未完成的计算，await可以等待 future对象完成。

* 协程对象示例：

  下面的cc()和 dd()就是协程对象，可以直接通过 run_until_complete() 给运行起来

```python
import asyncio
async def cc():
    print("cc")

async def dd():
    print("dd")

loop = asyncio.get_event_loop()
loop.run_until_complete(cc())
loop.run_until_complete(dd())

```

在python3.7，可以不用 get_event_loop 和 run_until_complete，直接使用 asyncio.run（），则上面代码可改成

```python
async def cc():
    print("cc")
async def dd():
    print("dd")

asyncio.run(cc())
asyncio.run(dd())
```

如果任务比较多，我们可以使用 gather 来收集多个任务

```python
async def cc():
    print("cc")

async def dd():
    print("dd")

main_task = asyncio.gather(cc(),dd())
loop = asyncio.get_event_loop()
loop.run_until_complete(main_task)
```

有时候为了使得代码更容易阅读，我们会把 gather对象放到list里，然后再解包，比如

```python
task_list = [cc(), dd()]
main_task = asyncio.gather(*task_list)
```

如果使用 asyncio.run，由于默认gather返回的是一个 gather future对象，因此要用await，为了使用 await，我们要再定义一个task函数

```python
import asyncio
async def cc():
    print("cc")

async def dd():
    print("dd")
    
task_list = [cc(), dd()]
async def task():
    await asyncio.gather( *task_list )

asyncio.run(task())
```

除了使用gather方法之外，我们还可以直接使用wait方法，这样不用定义额外的函数，会更简单一些

```python
async def cc():
    print("cc")
    await asyncio.sleep(1)

async def dd():
    print("dd")

task_list = [cc(), dd()]
wait_task = asyncio.wait(task_list)
asyncio.run(wait_task)
```



2. 对于awaitable对象，也比较好理解，就是在 async 函数里，加上 await。示例

```python
async def dd():
    print("dd")
    await asyncio.sleep(2)
 asyncio.run(dd())
```

当然如果跟1一样，如果有多个任务的话，我们可以用 asyncio.gather()来收集起来

```python
async def cc():
    print("cc")
    await asyncio.sleep(1)

async def dd():
    print("dd")
    await asyncio.sleep(2)
    
task_list = [cc(), dd()]

async def task():
    await asyncio.gather(*task_list)

asyncio.run(task())
```

3. 如果是Gatherfuture对象，那么asyncio.run()是运行不起来的，不过loop.run_until_complete是可以的.

