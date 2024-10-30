
## 公钥私钥计算过程

先选两个质数 p 和 q，则计算出 模数 N = p * q
欧拉函数 (p-1) * (q-1)，得到 T
选公钥E：需要是质数； 1 < 公钥 < T; 不是T的因子。公钥包含 (E,N)
算私钥D: (D * E) % T = 1

RSA 算法的密钥长度至少为12为，下面以2048为例（以前有用1024位，现在认为不安全，建议2048或者4096位）。注意：密钥长度指的是模数 N 的长度，而并非D 的长度
```go

func main() {  
    prikey, _ := rsa.GenerateKey(rand.Reader, 2048)  
  
    // 明文^E % N = 密文  
    // public key  
    n := prikey.N  
    e := prikey.E  
  
    // 密文 ^ D % N = 明文  
    //private key  
    d := prikey.D  
  
    fmt.Printf("质数相乘的 N is: %d\n, 公钥 E is %d, 私钥 D is: %d", n, e, d)  

    }
```