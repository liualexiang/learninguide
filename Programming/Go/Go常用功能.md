## 信号控制
通过捕获 SIGTERM 或SIGINT（sig interrupt）来关闭程序
```go
package main  
  
import (  
    "github.com/zserge/lorca"  
    "log"    "os"    "os/signal"    "syscall")  
  
func main() {  
    ui, err := lorca.New("https://www.baidu.com", "", 800, 600, "--disable-sync", "--remote-allow-origins=*")  
    if err != nil {  
       log.Fatal(err)  
    }  
    chSignal := make(chan os.Signal, 1)  
    signal.Notify(chSignal, syscall.SIGINT, syscall.SIGTERM)  
    select {  
    case <-chSignal:  
    case <-ui.Done():  
    }  
    defer ui.Close()  
}
```
