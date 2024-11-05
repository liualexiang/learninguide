bitcoin-cli 连 btc 节点的端口是 8332，如果是 testnet是 18332，协议http

BTC CLI: https://chainquery.com/bitcoin-cli


```shell
# 创建一个钱包，本质是存在本地的一个 SQLite 数据库里
bitcoin-cli createwallet "alexwallet"
bitcoin-cli listwallets
# 删除钱包
bitcoin-cli unloadwallet "mywallet"

# 加载钱包
bitcoin-cli loadwallet alexwallet

# 查看钱包情况
bitcoin-cli -rpcwallet="alexwallet" getwalletinfo

# 在钱包里生成地址
bitcoin-cli -rpcwallet="alexwallet" getnewaddress

bitcoin-cli getaddressinfo tb1qt5gccdj9yyaq2vc5afj7pmx5cd9v408t2ww8mx

bitcoin-cli -rpcwallet="alexwallet" getaddressinfo "tb1qt5gccdj9yyaq2vc5afj7pmx5cd9v408t2ww8mx"

# 列出钱包里的所有地址(注意如果用 getnewaddress 之后，这里是看不到的，只有地址有钱，才能看到)
# 获得测试token https://bitcoinfaucet.uo1.net/send.php
bitcoin-cli -rpcwallet="alexwallet" listaddressgroupings
[
  [
    [
      "tb1q8uput7ms7vemlwelg00jr6tkd0cz7ypdfppvv7",
      0.00004900,
      ""
    ]
  ]
]
# 查看钱包余额
bitcoin-cli -rpcwallet="alexwallet" getbalance
bitcoin-cli -rpcwallet="alexwallet" listunspent

# 发起一笔转账
bitcoin-cli -rpcwallet="alexwallet" sendtoaddress "tb1qlj64u6fqutr0xue85kl55fx0gt4m4urun25p7q" 0.000003

# 获得钱包中所有地址，包括没有激活的
bitcoin-cli -rpcwallet="alexwallet" getaddressesbylabel ""
```

查看帮助 `bitcoin-cli help` 查看子命令的帮助 `bitcoin-cli help createwallet`


创建 Legacy 钱包 (非 HD Wallet) ，现在已经不推荐了
```shell
bitcoin-cli createwallet "my_legacy_wallet" false false "" false true false false`

address=$(bitcoin-cli -rpcwallet="my_legacy_wallet" getnewaddress "" legacy)
echo "New address: $address"


```

测试
```shell
root@ip-10-222-41-190:~# new_address=$(bitcoin-cli -rpcwallet="alexwallet" getnewaddress)
root@ip-10-222-41-190:~# echo "New Address: $new_address"
New Address: tb1q8uput7ms7vemlwelg00jr6tkd0cz7ypdfppvv7

# 获得测试token https://bitcoinfaucet.uo1.net/send.php
# browser 连接https://blockstream.info/testnet/address/tb1q8uput7ms7vemlwelg00jr6tkd0cz7ypdfppvv7

# https://coinfaucet.eu/en/btc-testnet/
# https://testnet.help/en/btcfaucet/testnet#log
# 未验证 https://support.chainstack.com/hc/en-us/articles/900001638963-Bitcoin-testnet-faucets


```