bitcoin-cli 连 btc 节点的端口是 8332，如果是 testnet是 18332，协议http。signet是38332.

signet 与 testnet的不同：testnet跟mainnet对应，是完全一样的，每一个节点都可能是出块节点，这也就导致了可能不稳定，效率低等。signet控制了出块节点，只有特定的节点是测试节点，这样就能保证整个网络的稳定性以及效率。

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


## BTC Multisig wallet

创建一个multisig wallet的脚本
```bash
#!/bin/bash -l

for ((n=1;n<=3;n++))
do
        echo "creating wallet"
        bitcoin-cli -testnet createwallet "participant_${n}"
        echo "done"
done


declare -A xpubs

for ((n=1;n<=3;n++))
do
 xpubs["internal_xpub_${n}"]=$(bitcoin-cli -testnet -rpcwallet="participant_${n}" listdescriptors | jq '.descriptors | [.[] | select(.desc | startswith("wpkh") and contains("/1/*"))][0] | .desc' | grep -Po '(?<=\().*(?=\))')

 xpubs["external_xpub_${n}"]=$(bitcoin-cli -testnet -rpcwallet="participant_${n}" listdescriptors | jq '.descriptors | [.[] | select(.desc | startswith("wpkh") and contains("/0/*") )][0] | .desc' | grep -Po '(?<=\().*(?=\))')
done
for x in "${!xpubs[@]}"; do printf "[%s]=%s\n" "$x" "${xpubs[$x]}" ; done

external_desc="wsh(sortedmulti(2,${xpubs["external_xpub_1"]},${xpubs["external_xpub_2"]},${xpubs["external_xpub_3"]}))"
internal_desc="wsh(sortedmulti(2,${xpubs["internal_xpub_1"]},${xpubs["internal_xpub_2"]},${xpubs["internal_xpub_3"]}))"

external_desc_sum=$(bitcoin-cli -testnet getdescriptorinfo $external_desc | jq '.descriptor')
internal_desc_sum=$(bitcoin-cli -testnet getdescriptorinfo $internal_desc | jq '.descriptor')

multisig_ext_desc="{\"desc\": $external_desc_sum, \"active\": true, \"internal\": false, \"timestamp\": \"now\"}"
multisig_int_desc="{\"desc\": $internal_desc_sum, \"active\": true, \"internal\": true, \"timestamp\": \"now\"}"

multisig_desc="[$multisig_ext_desc, $multisig_int_desc]"

echo $multisig_desc

# create a multi sig wallet
bitcoin-cli -testnet -named createwallet wallet_name="multisig_wallet_01" disable_private_keys=true blank=true


bitcoin-cli  -testnet -rpcwallet="multisig_wallet_01" importdescriptors "$multisig_desc"

bitcoin-cli  -testnet -rpcwallet="multisig_wallet_01" getwalletinfo

# bitcoin-cli -testnet -rpcwallet="multisig_wallet_01" getnewaddress

# 获得一些测试币，注意要安装 imagemagick
# python3 get_coin_testnet.py -c /root/bitcoin-27.0/bin/bitcoin-cli  -a tb1q0tzzd43zw6v6mr22rjwvjpqykdsat8kmyhdr2qkecv3pwsnph85qcjvz3m
```

测试

```shell
bitcoin-cli -rpcwallet="multisig_wallet_01" getnewaddress
tb1qdg5pfx9p4dg3z4dj47j0fjfrq5c3jrj7s9tg4ulyggx2razqf6lsfrtk9j
```