# systemd



### Systemd的进程管理文件可以存放在两个地方

1. 存放在 /usr 路径下: ``` /usr/lib/systemd/system/alertmanager.service; ```
2. 存放在 /etc 路径下 ```/etc/systemd/system/prometheus.service; ```

如果两个路径冲突，那么以 /etc/路径下优先



示例:

```shell
wget https://github.com/prometheus/pushgateway/releases/download/v1.4.2/pushgateway-1.4.2.linux-amd64.tar.gz

tar zxvf pushgateway-1.4.2.linux-amd64.tar.gz

mv pushgateway-1.4.2.linux-amd64 /opt/
# create a user
useradd -s /sbin/nologin pushgateway -u 2000
chown -R pushgateway:pushgateway /opt/pushgateway-1.4.2.linux-amd64


# create systemd servcie
cat << EOF  > /usr/lib/systemd/system/pushgateway.service
[Unit]
Description=pushgateway
Wants=network-online.target
After=network-online.target

[Service]
User=pushgateway
Group=pushgateway
Type=simple
ExecStart=/opt/pushgateway-1.4.2.linux-amd64/pushgateway
Restart=on-failure

ExecReload=/bin/kill -HUP $MAINPID
KillMode=process

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl enable pushgateway
systemctl start pushgateway
```



## 有关systemd 的配置

如果是一个shell程序，或者是一个前台的程序，当启动的时候，一直挂在前台，那么Type要使用 simple。如果本身是一个后台程序，那么Type 要使用 Forking。对于forking的程序，应该是会将进程挂到PID=1的进程里.

Install的位置，说明了会将 systemd 的启动脚本，放在 /etc/systemd/system/ 的那个路径下。而unit里的 wants 和 after，则说明是当计算机启动的时候，什么时候开始引导这个程序。



## 有关日志

在创建一个服务的时候，如果是simple类型的，默认会将日志输出到 stdout，如果我们想自定义让日志输出到某个文件中，可以借助于rsyslog服务来做。比如在systemd中，将 StandardOutput 以及StandardError 设置为 syslog，同时指定SyslogIdentifier 为服务名

```shell
cat /etc/systemd/system/xmr.service
[Unit]
Description=XMR Coin Mining

[Service]
Type=simple
ExecStart=/home/alex/xmrig
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=xmr
Restart=on-failure

LimitNOFILE=16384

[Install]
WantedBy=multi-user.target
Alias=xmr.service

```

然后创建 rsyslog配置文件，在配置文件中，判断日志写入的位置

```shell
cat /etc/rsyslog.d/22-xmr.conf 

if $programname == 'xmr' then /var/log/xmr.log
& stop

EOF

```

