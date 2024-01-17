#!/bin/bash
sudo yum install -y python3 python3-devel python-setuptools gcc gcc-c++ libffi-devel python-devel python-pip python-wheel openssl-devel cyrus-sasl-devel openldap-devel
python3 -m venv venv
. ./venv/bin/activate
pip3 install apache-superset -i https://pypi.douban.com/simple 
superset db upgrade
export FLASK_APP=superset
flask fab create-admin --username admin_test --firstname adm --lastname user --email admin_test@tessdft.com --password admin_test
superset init
sudo amazon-linux-extras install nginx1.12 -y
wget https://xlaws.s3.cn-northwest-1.amazonaws.com.cn/superset/nginx/nginx.conf
cp nginx.conf /etc/nginx/nginx.conf
systemctl start nginx
gunicorn -w 10 --timeout 120 -b  0.0.0.0:6666 --limit-request-line 0 --limit-request-field_size 0 "superset.cli:create_app()"  --access-logfile /var/log/access_log --error-logfile /var/log/error_log -D

