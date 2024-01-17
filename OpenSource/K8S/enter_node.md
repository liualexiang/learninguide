# 登录到 Node 节点



```
#!/bin/sh

# this script allow you run a container attached to node with root privilege
# see https://securek8s.dev/exercise/65-privileged/
# usage:
# kubectl get nodes
# ./k8s_attach_node.sh <node name>

node=${1}
if [ -n "${node}" ]; then
    nodeSelector='"nodeSelector": { "kubernetes.io/hostname": "'${node:?}'" },'
else
    nodeSelector=""
fi
set -x
name="${node//./-}" # replace . with -, pod name doesn't support .
kubectl run $name --restart=Never --rm -it --image overriden --overrides '
{
  "spec": {
    "hostPID": true,
    "hostNetwork": true,
    '"${nodeSelector?}"'
    "containers": [
      {
        "name": "'$name'",
        "image": "alpine:3.7",
        "command": ["nsenter", "--mount=/proc/1/ns/mnt", "--", "sh", "-c", "hostname sudo--$(cat /etc/hostname); exec /bin/bash"],
        "stdin": true,
        "tty": true,
        "resources": {"requests": {"cpu": "10m"}},
        "securityContext": {
          "privileged": true
        }
      }
    ]
  }
}' --attach
```

