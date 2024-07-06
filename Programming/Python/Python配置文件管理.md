## 通过类的继承来管理配置
如下面的配置，则如果环境变量里有这个配置，就使用环境变量里的，否则使用 config.yaml 文件里的
```python
import boto3  
import os  
import yaml  
  
  
class DefaultConfig:  
    aws_profile = os.getenv("AWS_PROFILE")  
    es_host = os.getenv("ES_HOST")  
    es_port = int(os.getenv("ES_PORT")) if os.getenv("ES_PORT") else None  
  
  
class Config(DefaultConfig):  
    def __init__(self):  
        with open("config.yaml", "r") as f:  
            self.config = yaml.safe_load(f)  
  
        for k, v in self.config.items():  
            if getattr(self, k, None) is None:  
                setattr(self, k, v)
```