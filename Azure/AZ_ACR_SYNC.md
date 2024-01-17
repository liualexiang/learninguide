### Azure Container Registries 镜像同步

#### 创建Azure Function
#### 配置 VS Code Extension
#### 上传代码到Function
 func azure functionapp publish xiangacrcopy


#### 代码实现

##### 同一个region内，不同的ACR Repo之间的copy

```python
import logging,json
import azure.functions as func

from msrestazure.azure_active_directory import MSIAuthentication
credentials = MSIAuthentication()

SUBSCRIPTION_ID = '5fb605ab-c16c-4184-8a02-fee38cc11b8c'
SRC_RESOURCE_GROUP = 'xiangliu_csa'

import  azure.mgmt.containerregistry as acr
acrclient = acr.ContainerRegistryManagementClient(credentials=credentials, subscription_id=SUBSCRIPTION_ID)

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    acr_event=json.loads(req.get_body())
    SRC_REGISTRY_NAME = acr_event['request']['host'].split('.')[0]
    SOURCE_IMG = acr_event["target"]['repository'] + ':' + acr_event["target"]['tag']
    SRC_REGISTRY_URI = acr_event['request']['host']
    TARGET_IMG_TAG = [SOURCE_IMG]
    TARGET_RESOURCE_GROUP = 'xiangliu_csa'
    TAEGET_IMG_REPO = 'xiangliurepo2'

    src_image_url = acr_event['request']['host'] + '/' + acr_event["target"]['repository'] + ':' + acr_event["target"]['tag']

    passwd = acrclient.registries.list_credentials(registry_name= SRC_REGISTRY_NAME , resource_group_name= SRC_RESOURCE_GROUP).passwords[0].value
    imp_src_cred = acrclient.models().ImportSourceCredentials(password= passwd, username= SRC_REGISTRY_NAME)
    import_img_src = acrclient.models().ImportSource(source_image = SOURCE_IMG ,registry_uri= SRC_REGISTRY_URI , credentials = imp_src_cred)
    img_mode = acrclient.models().ImportMode.force
    import_img_para=acrclient.models().ImportImageParameters(source=import_img_src, target_tags = TARGET_IMG_TAG, mode= img_mode)
    imp_img = acrclient.registries.import_image(resource_group_name= TARGET_RESOURCE_GROUP, registry_name =TAEGET_IMG_REPO, parameters=import_img_para)
    return func.HttpResponse(src_image_url + " copied successfully")
    # return func.HttpResponse(result)

```

