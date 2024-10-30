## Go 基础语法 

Go 程序的入口的package 和函数名，必须都是 main。如果是一个包，包里函数小写开头，只能在这个包内使用，大写开头，则包内包外都可以使用。

### 循环

```go
package main

import (
	"fmt"
)

func main() {
		for i := 1; i <= 9; i++ {
			for j := 1; j <= i; j++ {
				fmt.Printf("%d*%d=%d\t", j, i, i*j)
			}
			fmt.Println()
		}
}

```

如果是字符串、数组、slice、map或 channel的遍历，可以用 range 来进行遍历

```go
package main

import (
	"fmt"
)

func main() {
	str := "sdfajlskfa"
	for i, c := range str {
		fmt.Printf("%c", c)
		fmt.Printf("%d,", i)
	}

	result1, result2 := add(2, 3)
	fmt.Print(result1, result2)
}

func add(a, b int) (int, int) {
	return a + b, a * b
}

```

 如果是可变参数，可以在参数类型前加上 ...

```go
package main

import (
	"fmt"
)

func main() {
	sum := 0
	sum = getSum(1, 2, 3)
	fmt.Println("sum result: ", sum)
}

func getSum(num ...int) int {
	sum := 0
	for i := 0; i < len(num); i++ {
		sum += num[i]
	}
	return sum
}

```

可变参数也是支持不确定类型的参数，示例：
```go
func printType(args ...interface{}) {
	for _, arg := range args {
		switch arg.(type) {
		case int:
			fmt.Println(arg, " type is int")

		case string:
			fmt.Println(arg, " type is string")

		default:
			fmt.Println(arg, " type is unknown")
		}
	}
}
```

如果是在一个list后面加 ... 则表示解序列，示例：
```go
var s []string  
s = append(s, []string{"a", "b", "c"}...)  
fmt.Println(s)
```

### 数据类型:列表和切片
数组 array 和 slice 切片的区别： 数组是固定长度，slice是可变长度。如果改变了数组里的值，那实际上是修改的拷贝后的数组的值，原数组值不变。但如果改了slice的值，那么直接改变的就是原始slice。

```
arr := [4]int{1,2,3,4}
sli := []int{1,2,3,4}
```
### 匿名函数
直接 func() 不给函数起名，就是匿名函数，匿名函数也可以接受参数，也可以有返回值，一个示例:
```go
r := func(a, b int) int {  
    return a + b  
}(3, 5)  
  
fmt.Println(r)
```
### 函数式编程
#### 回调函数
将函数作为另外一个函数的参数，这个函数是回调函数，调用方是高阶函数。示例 add 就是回调函数
```go
func main() {  
    addR := operator(3, 4, add)  
    fmt.Println(addR)  
}  
  
func operator(a, b int, f func(int, int) int) int {  
    r := f(a, b)  
    return r  
}  
  
func add(a int, b int) int {  
    return a + b  
}
```
 
#### 闭包
当内层函数使用外层函数的变量，外层函数销毁了，但内层函数还在执行，此时变量依然能用。这种结构就叫做闭包。在支持回调函数的程序语言里，一般都是支持闭包


### 值传递和引用传递

如果是值传递，那么传过去的函数里，拿到的是副本，对其修改不会作用到原来调用方。如果是引用传递，则传递过去的修改，会作用于本身。不过需要注意的是：如果在引用的函数里，对这个变量重新赋值，则即使是引用传递，也不会作用于原函数里。
值传递的数据类型: int、string、bool、float64、array
引用传递的数据类型: slice、map、chan

举一个例子：下面定义的 l1 是一个 slice（因为没有定义list长度），所以是引用传递。也就意味着，当在调用的函数里修改了这个值，则这个变量的内存地址里的值被修改，所以在原始main函数里，执行函数后的值也发生了变化
```go
func main() {  
    l1 := []int{1, 2, 3, 4}  
    fmt.Println("传入前的值", l1)  
    updateList(l1)  
    fmt.Println("执行函数后的值", l1)  
}  
  
func updateList(l2 []int) {  
    fmt.Println("接收到的值\t", l2)  
    l2[0] = 100  
    fmt.Println("修改后的值\t", l2)  
}
```
但同样的代码，我们把 l1 定义的时候，指定长度为4，定义为 array 列表，此时就是值传递，即使调用了某一个函数传了这个值，在调用函数内部做的修改，并不会反应到原始函数上。
```go
func main() {  
    l1 := [4]int{1, 2, 3, 4}  
    fmt.Println("传入前的值", l1)  
    updateList(l1)  
    fmt.Println("执行函数后的值", l1)  
}  
  
func updateList(l2 [4]int) {  
    fmt.Println("接收到的值\t", l2)  
    l2[0] = 100  
    fmt.Println("修改后的值\t", l2)  
}
```





## package
1. 如果包里的函数名是小写字母开头，只能在包内使用。
2. 一个包内只能有一个 init() 函数，这个函数会在import的时候生效。
3. 包是可以匿名导入的， 在匿名导入的时候，只会执行 init()函数。导入方法是
```go
import _ packageName
```

4. 在调用包的时候，可以给包起一个别名。如果别名是 . 则可以直接用这个包里的函数，比如 fmt.Println 如果import的时候别名是 . ，那么就可以直接用 Println()了，而不是 fmt.Println()
```go
import (
. "fmt"
)
```



## Go 模块下载
首先项目里要有 go.mod 文件，这个文件里包含了依赖包的信息，如果想要整理下这个文件，可以用 go mod tidy，会清理没用到的包。如果没有 go mod文件，可以初始化这个go项目。比如go代码都在当前路径的 my_project 文件夹下，那么我们用下面的命令，可以在该文件夹下创建 go.mod
```shell
go mod init my_project
```
之后下载包的时候用
```
go get github.com/ethereum/go-ethereum/crypto
```








