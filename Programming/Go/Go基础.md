# Go 基础 

Go 程序的入口的package 和函数名，必须都是 main。

一个简单的go for循环程序

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

数组 array 和 slice 切片的区别： 数组是固定长度，slice是可变长度。如果改变了数组里的值，那实际上是修改的拷贝后的数组的值，原数组值不变。但如果改了slice的值，那么直接改变的就是原始slice。

```
arr := [4]int{1,2,3,4}
sli := []int{1,2,3,4}
```













