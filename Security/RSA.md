RSA算法，是先找两个质数，然后再找出来公钥（公钥是一个质数），再基于欧几里得算法找出私钥。私钥可以是无限多的，一般用最小的。
### 公钥私钥计算过程

先选两个质数 p 和 q，则计算出 模数 N = p * q
欧拉函数 (p-1) * (q-1)，得到 PhiN
选公钥E：需要是质数； 1 < 公钥 < PhiN; 不是PhiN的因子。公钥包含 (E,N)
算私钥D: (D * E) % PhiN = 1

这里需要注意的是：由于私钥的算法是 D * E % (p-1)(q-1) = 1，那么在E是确定的时候，D是无限多的。在我们平时使用的时候，D往往是选取最小的一个

### 加解密过程
明文^E % N = 密文
密文^D % N = 明文
举例： p,q = 3, 11，则 N = 33, PhiN = 20, 公钥选择为 (3, 33)，私钥可以是 (7, 33)，也可以是 (27, 33)。对数据 3 进行加密可以验证。
公钥加密 pow(3, 3, 33) = 27
私钥解密 pow(27, 7, 33) = 3 或者 pow(27, 27, 33) = 3

但是由于N太小，容易出现数据折叠 (模数太小引起的碰撞)，比如数据为 100 的时候，公钥加密为 1，私钥解密为 pow(1, 7, 33) = 1 ，解密的数据不对。
公钥的公共指数 E 为 65537，即 2 ** 16 + 1， 是因为 65537 是一个费马素数，在快速模幂计算中效率很高。而且已经形成一个行业标准(hamming weight 与指数运算的效率)。

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


### RSA 签名原理
RSA的签名，本质上，就是先对消息进行一次 Hash，如SHA 256，然后使用私钥对这个 SHA 256 进行加密。加密后的数据就是签名。
之后发送方将签名和原始数据一起发给对端，对端算出SHA256的值，之后用公钥对这个签名进行解密，解密后就是原始消息的SHA256的值。
用这个方法，来保障数据传输过程中没有被篡改，消息确实是由私钥持有者发出的。
由此来看，RSA在做签名确认的时候，是需要有原始消息，以及加密过的SHA256的值（即签名）的。

从这个过程来看，能做加解密的算法，可以用来做签名，比如RSA。但是能做签名的算法，不能做加解密，比如 ECDSA




