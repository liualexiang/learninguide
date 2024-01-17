# ETCD

## ETCD 基础命令



```
export PATH=/usr/local/bin:$PATH

etcdctl --user USER:PASSWORD user list
etcdctl --user USER:PASSWORD user create USERNAME

etcdctl --user USER:PASSWORD role list
etcdctl --user USER:PASSWORD role create ROLENAME
etcdctl --user USER:PASSWORD role get ROLENAME


etcdctl --user USER:PASSWORD role grant-permission ROLENAME write '/PATH'

etcdctl user --user USER:PASSWORD grant-role USERNAME ROLENAME
```

参考文档: https://etcd.io/docs/v3.3/op-guide/authentication/

