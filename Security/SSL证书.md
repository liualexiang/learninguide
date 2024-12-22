## x509公钥
一般公钥有几种格式，可以是hex 格式， DER 二进制格式，也可以是pem 格式。比如ECDSA的公钥为02/03/04，后面跟x或x+y坐标，这个hex格式则是直接拼接。如果是pem格式，则会包含加密的长度，以及曲线。
看一个例子
```
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEQdWiBHWGz+lFCCdQcFM4jdgrqczV
E1itDYN7xTALH3hPCZMnBPTL7sTej2qVjdWGceh8/Fe+VXGh68bSduJ4JA==
-----END PUBLIC KEY-----
```

使用 openssl 命令，对这个 x509 pem格式的公钥进行查看，我们能看出是一个EC椭圆曲线的公钥，长度为256位，曲线为 secp256r1 (P-256)。如果是 RSA的话，能看出RSA的模数，以及会发现pub key会更长
```
# openssl pkey -inform PEM -pubin -text -noout -in test.pem

Public-Key: (256 bit)
pub:
    04:41:d5:a2:04:75:86:cf:e9:45:08:27:50:70:53:
    38:8d:d8:2b:a9:cc:d5:13:58:ad:0d:83:7b:c5:30:
    0b:1f:78:4f:09:93:27:04:f4:cb:ee:c4:de:8f:6a:
    95:8d:d5:86:71:e8:7c:fc:57:be:55:71:a1:eb:c6:
    d2:76:e2:78:24
ASN1 OID: prime256v1
NIST CURVE: P-256
```

## x509 证书
