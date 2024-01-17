## 使用TPC-DS 产生压测数据

### 下载TPC-DS压测工具：(测试版本 2.11.0)
http://www.tpc.org/tpc_documents_current_versions/current_specifications5.asp

解压之后在tools目录下执行make进行编译

### 编译之后使用dsdgen产生数据，其中 -scale 指定产生多大的数据，比如下面产生 1000GB，-parallel指定将数据切成4个片段，-child指定当前产生第几个片段
```
./dsdgen -dir /home/ec2-user/data/ -scale 1000 -parallel 4 -child 1
./dsdgen -dir /home/ec2-user/data/ -scale 1000 -parallel 4 -child 2
./dsdgen -dir /home/ec2-user/data/ -scale 1000 -parallel 4 -child 3
./dsdgen -dir /home/ec2-user/data/ -scale 1000 -parallel 4 -child 4
```

### 产生查询脚本:
```
./dsqgen -output_dir /home/ec2-user/query/ -input ../query_templates/templates.lst -scale 1 -DIALECT netezza -DIRECTORY ../query_templates -QUALIFY y -VERBOSE Y
```
或者用这个方法产生
```
for id in `seq 1 99`; do ./dsqgen -DIRECTORY ../query_templates -TEMPLATE "query$id.tpl" -DIALECT netezza -FILTER Y > ~/query/"query$id.sql"; done
```

如果遇到_END的报错，那么在../query_templates路径下，对所有的tpl文件后面添加一行： define _END = "";，使用脚本做如下：
```
 ls | while read line; do echo "define _END = \"\";" >> $line; done
```

### 建表语句 
创建表的语句在 tools文件夹下的 tpcds.sql 文件中，以及tpcds_source.sql 文件中

### TPC-DS 工具说明
有关工具的使用以及目录结构说明，参考specification文件夹下的 specification.pdf 文件中的表格：Table 0-1 Electronically Available Specification Material

有关产生1G，1T，3T，10T，30T，100T的文件，每个表数据量大小，可以参考 specification文件夹下的 specification.pdf 文件中的 Table 3-2 Database Row Counts 这个表格来对比。

### 附录：在AWS EMR创建Hive表：
#### 在AWS Global账号下启动过EMR进行测试的命令 
```
aws emr create-cluster --auto-scaling-role EMR_AutoScaling_DefaultRole \
--applications Name=Hadoop Name=Hive Name=Hue Name=Ganglia Name=Spark Name=Presto --ebs-root-volume-size 10 --ec2-attributes '{"KeyName":"Virginia","InstanceProfile":"EMR_EC2_DefaultRole","SubnetId":"subnet-fc22e0a4","EmrManagedSlaveSecurityGroup":"sg-68c8f923","EmrManagedMasterSecurityGroup":"sg-08c2f343"}' \
--service-role EMR_DefaultRole \
--enable-debugging --log-uri 's3://aws-logs-372809795158-us-east-1/elasticmapreduce/' \
--name 'test-hive-spark' \
--release-label emr-5.25.0 \
--instance-groups '[{"InstanceCount":5,"EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":1000,"VolumeType":"gp2"},"VolumesPerInstance":1}],"EbsOptimized":true},"InstanceGroupType":"CORE","InstanceType":"c5.2xlarge","Name":"核心实例组 - 2"},{"InstanceCount":1,"EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":32,"VolumeType":"gp2"},"VolumesPerInstance":4}]},"InstanceGroupType":"MASTER","InstanceType":"c5.2xlarge","Name":"主实例组 - 1"}]' \
--configurations '[{"Classification":"hive-site","Properties":{"hive.metastore.client.factory.class":"com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"}},{"Classification":"spark-hive-site","Properties":{"hive.metastore.client.factory.class":"com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"}}]' \
--steps '[{"Args":["s3-dist-cp","--src","s3://xlaws/data/catalog_sales","--dest","hdfs:///catalog_sales"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"S3DistCpSales"},{"Args":["s3-dist-cp","--src","s3://xlaws/data/warehouse","--dest","hdfs:///warehouse"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"S3DistCpWarehouse"},{"Args":["s3-dist-cp","--src","s3://xlaws/data/date_dim","--dest","hdfs:///date_dim"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"S3DistCpDate"},{"Args":["s3-dist-cp","--src","s3://xlaws/data/ship_mode","--dest","hdfs:///ship_mode"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"S3DistCpShip"},{"Args":["s3-dist-cp","--src","s3://xlaws/data/call_center","--dest","hdfs:///call_center"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"S3DistCpCallCenter"}]' \
--scale-down-behavior TERMINATE_AT_TASK_COMPLETION --region us-east-1 --profile global
```

### 创建S3上的表

创建catalog_sales表
```
CREATE EXTERNAL TABLE `catalog_sales`(
  `cs_sold_date_sk` bigint, 
  `cs_sold_time_sk` bigint, 
  `cs_ship_date_sk` bigint, 
  `cs_bill_customer_sk` bigint, 
  `cs_bill_cdemo_sk` bigint, 
  `cs_bill_hdemo_sk` bigint, 
  `cs_bill_addr_sk` bigint, 
  `cs_ship_customer_sk` bigint, 
  `cs_ship_cdemo_sk` bigint, 
  `cs_ship_hdemo_sk` bigint, 
  `cs_ship_addr_sk` bigint, 
  `cs_call_center_sk` bigint, 
  `cs_catalog_page_sk` bigint, 
  `cs_ship_mode_sk` bigint, 
  `cs_warehouse_sk` bigint, 
  `cs_item_sk` bigint, 
  `cs_promo_sk` bigint, 
  `cs_order_number` bigint, 
  `cs_quantity` bigint, 
  `cs_wholesale_cost` double, 
  `cs_list_price` double, 
  `cs_sales_price` double, 
  `cs_ext_discount_amt` double, 
  `cs_ext_sales_price` double, 
  `cs_ext_wholesale_cost` double, 
  `cs_ext_list_price` double, 
  `cs_ext_tax double` double, 
  `cs_coupon_amt` double, 
  `cs_ext_ship_cost` double, 
  `cs_net_paid` double, 
  `cs_net_paid_inc_tax` double, 
  `cs_net_paid_inc_ship` double, 
  `cs_net_paid_inc_ship_tax` double, 
  `cs_net_profit double` double)
ROW FORMAT DELIMITED 
  FIELDS TERMINATED BY '|' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://xlaws/data/catalog_sales';
```

创建call_center 表
```
CREATE EXTERNAL TABLE `call_center`(
  `cc_call_center_sk` bigint, 
  `cc_call_center_id` string, 
  `cc_rec_start_date` string, 
  `cc_rec_end_date` string, 
  `cc_closed_date_sk` string, 
  `cc_open_date_sk` bigint, 
  `cc_name` string, 
  `cc_class` string, 
  `cc_employees` bigint, 
  `cc_sq_ft` bigint, 
  `cc_hours` string, 
  `cc_manager` string, 
  `cc_mkt_id` bigint, 
  `cc_mkt_class` string, 
  `cc_mkt_desc` string, 
  `cc_market_manager` string, 
  `cc_division` bigint, 
  `cc_division_name` string, 
  `cc_company` bigint, 
  `cc_company_name` string, 
  `cc_street_number` bigint, 
  `cc_street_name` string, 
  `cc_street_type` string, 
  `cc_suite_number` string, 
  `cc_city` string, 
  `cc_county` string, 
  `cc_state` string, 
  `cc_zip` bigint, 
  `cc_country` string, 
  `cc_gmt_offset` bigint, 
  `cc_tax_percentage` double)
ROW FORMAT DELIMITED 
  FIELDS TERMINATED BY '|' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://xlaws/data/call_center/';

```

创建 date_dim 表

```
CREATE EXTERNAL TABLE `date_dim`(
  `d_date_sk` bigint, 
  `d_date_id` string, 
  `d_date` string, 
  `d_month_seq` bigint, 
  `d_week_seq` bigint, 
  `d_quarter_seq` bigint, 
  `d_year` bigint, 
  `d_dow` bigint, 
  `d_moy` bigint, 
  `d_dom` bigint, 
  `d_qoy` bigint, 
  `d_fy_year` bigint, 
  `d_fy_quarter_seq` bigint, 
  `d_fy_week_seq` bigint, 
  `d_day_name` string, 
  `d_quarter_name` string, 
  `d_holiday` string, 
  `d_weekend` string, 
  `d_following_holiday` string, 
  `d_first_dom` bigint, 
  `d_last_dom` bigint, 
  `d_same_day_ly` bigint, 
  `d_same_day_lq` bigint, 
  `d_current_day` string, 
  `d_current_week` string, 
  `d_current_month` string, 
  `d_current_quarter` string, 
  `d_current_year` string)
ROW FORMAT DELIMITED 
  FIELDS TERMINATED BY '|' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://xlaws/data/date_dim/';
  ```

创建ship_mode表
```
CREATE EXTERNAL TABLE `ship_mode`(
  `sm_ship_mode_sk` bigint, 
  `sm_ship_mode_id` string, 
  `sm_type` string, 
  `sm_code` string, 
  `sm_carrier` string, 
  `sm_contract` string)
ROW FORMAT DELIMITED 
  FIELDS TERMINATED BY '|' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://xlaws/data/ship_mode/';

```

创建ware_house表
```
CREATE EXTERNAL TABLE `warehouse`(
  `w_warehouse_sk` bigint, 
  `w_warehouse_id` string, 
  `w_warehouse_name` string, 
  `w_warehouse_sq_ft` bigint, 
  `w_street_number` bigint, 
  `w_street_name` string, 
  `w_street_type` string, 
  `w_suite_number` string, 
  `w_city` string, 
  `w_county` string, 
  `w_state` string, 
  `w_zip` bigint, 
  `w_country` string, 
  `w_gmt_offset` bigint)
ROW FORMAT DELIMITED 
  FIELDS TERMINATED BY '|' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://xlaws/data/warehouse/';
```

