#### 使用parallel cluster提升CRISPR效率
如有问题，请及时反馈

##### 准备cas-Offinder 镜像
* 推荐使用ubuntu或者centos，不推荐使用amazon linux（在2019年10月份测试的时候，发现amazon linux 2安装不上opencl，不确定现在是否修复），本文以 ubuntu 16.04为例
* 在EC2上，安装opencl，opencl可以在intel官网下载.
* 在EC2上，下载安装 cas-offinder 软件，可以直接下载编译好的二进制包，无需使用源码编译。
##### 准备参考基因组和GuideRNA数据
* 以人类参考基因组为例，数据包大概3GB，下载地址：wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.38_GRCh38.p12/GCF_000001405.38_GRCh38.p12_genomic.fna.gz
* 准备guideRNA，路径/data/GCF_000001405.38_GRCh38.p12_genomic.fna： https://github.com/liualexiang/learninguide/blob/master/CRISPR/input_sgRNA_ngg_aid_5000.txt

  
##### cas-offinder单机使用方法
cas-offinder input_sgRNA_ngg_aid_500.txt C /tmp/
第一个参数input_sgRNA_ngg_aid_500.txt 为输入文件，第二个参数C为指定使用CPU计算(如果用GPU计算的话，指定为G)，第三个参数 /tmp/为输出路径
计算时常与guideRNA大小有关系，以500行的guideRNA为例，在c4.8xlarge机器上需要花费十来分钟完成。

* 可以将guideRNA拆分成更小的文件，用更多的EC2进行计算.
* Cas-offinder 软件说明: https://github.com/snugel/cas-offinder


##### 创建pcluster集群
* 测试好上述环境之后，安装pcluster: https://docs.aws.amazon.com/zh_cn/parallelcluster/latest/ug/install.html
* 配置AWS AK/SK，配置Pcluster: https://docs.aws.amazon.com/zh_cn/parallelcluster/latest/ug/getting-started-configuring-parallelcluster.html
* 示例Pcluster配置文件(在 ~/.parallelcluster/config这个文件中)
```
[aws]
aws_region_name = cn-north-1

[cluster casoffinder]
base_os = ubuntu1604
vpc_settings = public
key_name = BJSAWS
scheduler = slurm
custom_ami = ami-02c77954765785ce2
master_instance_type = r4.large
compute_instance_type = c4.8xlarge
master_root_volume_size = 50
compute_root_volume_size = 50
extra_json = { "cluster" : { "ganglia_enabled" : "yes" ,"cfn_scheduler_slots" : "cores" } }
placement = cluster
ebs_settings = shared_data
#pre_install = s3://xlaws/scripts/slurm_enable_accounting.sh
pre_install = https://xlaws.s3.cn-northwest-1.amazonaws.com.cn/scripts/slurm_enable_accounting.sh

[ebs shared_data]
shared_dir = shared
volume_type = gp2
volume_size = 100

[vpc public]
master_subnet_id = subnet-d0a02ab5
vpc_id = vpc-e9c09f8c

[global]
update_check = true
sanity_check = true
cluster_template = casoffinder

[aliases]
ssh = ssh {CFN_USER}@{MASTER_IP} {ARGS}
```

* 创建集群命令 ``` pcluster create casoffinder ```
* 创建之后可以ssh到master node上

##### 使用slurm 提交job
* 在创建pcluster的时候，我们的调度器为slumr，可以通过slurm来提交作业。我们可以将之前的5000行guideRNA单个文件拆分成10个，以文件名为 input_sgRNA_ngg_aid_5000.txt1, input_sgRNA_ngg_aid_5000.txt2 为例.
拆分文件的python脚本
```python
file_name ='input_sgRNA_ngg_aid_5000.txt'

with open(file_name, 'r') as f:
    input_path_name = f.readline()
    pam_pattern = f.readline()
    num = 1
    while True:
        for i in range(500):
            line = f.readline()
            if not line:
                break
            with open(file_name+ str(num), 'a+') as new_f:
                if i == 0:
                    new_f.write(input_path_name + pam_pattern+ line)
                else:
                    new_f.write(line)
        num += 1
        if not line:
            break
```

* 提交作业
```bash
# 生成提交任务脚本:
for i in `ls input_sgRNA_ngg_aid_5000*` ;do echo '#!/bin/sh' > $i.sh;echo "cas-offinder $i C /data/output/$i.output" >> $i.sh;chmod +x $i.sh; done
# 提交任务:
 for i in `ls input*sh` ;do sbatch -N 1 -n 1 -c 2 $i;done
```

* 常用的几个监控命令
```
 查看集群中节点配置
sinfo -o "%#P %.5a %.10l %.6D %.6t %C %e %O %N"

使用18颗cpu，58G内存提交任务。测试机型 c4.8xlarge, 一个任务一台机器
for i in `ls input*sh` ;do sbatch -N 1 -n 1 -c 18 --mem=58000 $i;done

查看任务，job id以及运行的实例ip
squeue -o "%j %A %B"


sacct -o "JobID, JobName%40, State, Elapsed, NodeList, ExitCode"
```

##### 对slurm启用accounting功能

* 启用accounting功能: 
```
sudo vim /opt/slurm/etc/slurm.conf
# Acct
AccountingStorageEnforce=1
AccountingStorageLoc=/opt/slurm/acct
AccountingStorageType=accounting_storage/filetxt

JobCompLoc=/opt/slurm/jobcomp
JobCompType=jobcomp/filetxt

JobAcctGatherFrequency=30
JobAcctGatherType=jobacct_gather/linux
```

* 创建 acct 和 jobcomp 文件，并将权限修改为777 
sudo touch /opt/slurm/jobcomp
sudo chmod 777 /opt/slurm/jobcomp
sudo touch /opt/slurm/acct
sudo chmod 777 /opt/slurm/acct

* 找到slurmctld进程id，将其终止
sudo ps -ef | grep slurmctld
sudo kill -9 17707

* 重启slurmctld 服务
sudo /opt/slurm/sbin/slurmctld

* 确认 slurmctld 服务已经启动
sudo ps -ef | grep slurmctld