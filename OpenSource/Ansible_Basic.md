# Ansible_Basic



### 安装和配置ansible

安装ansible：使用 ``` python3 -m pip install ansible ``` 直接安装.

安装ansible-lint：可以检查ansible语法

## ansible-doc

查看ansible 的某一个模块的帮助

```
ansible-doc -s shell
```

列出所有模块

```
ansible-doc -l
```

### ansible 默认配置

在 ansible.cfg (/etc/ansible/ansible.cfg)里，默认没有启用，建议启用日志

### inventory 机器清单

* 配置一个 inventory 列表

可以将机器列表放到 /etc/ansible/hosts 文件中，比如下面的示例，然后使用 ``` ansible app -m ping ``` 可以测试下连通性。如果想列出所有分组的所有机器，则执行 ``` ansible all --list-hosts ``` 。如果想要单独发一个shell命令，则 ``` ansible app -a "ifconfig" ```

```ini
[app]
1.2.3.4
host1.app.com
```

* 使用yaml配置  ``` ansible app -i inventory.yaml -m ping ```

  ```yaml
  allvm:
    hosts:
      vm1:
        ansible_host: 1.1.1.1
      vm2:
        ansible_host: 2.2.2.2
  app:
    hosts:
      vm2:
        ansible_host: 2.2.2.2
  ```

* inventory 支持parenet/child 之间的关系，比如下面的 prod，则包括 appservers 和 dbservers

  ```yaml
  all:
    hosts:
      1.1.1.1:
    children:
      appservers:
        hosts:
          2.2.2.2:
      dbservers:
        hosts:
          3.3.3.3:
      prod:
        children:
          appservers:
          dbservers:
  ```

* ansible 也支持将 inventory 放到一个目录下， ansible -i folder_name 也可以引用。同时ansible也支持使用python脚本动态获取inventory。对于各大云厂商，ansible也有对应的plugin

* 查看inventory的清单

  ```shell
  ansible-inventory -i inventory/inventory2.yaml --graph
  ```

  

### ansible module

默认情况下，执行的是command 模块，虽然command 模块也能执行一些指令，但是对于一些变量，以及重定向，管道等操作，command模块是不支持的，我们可以 ``` -m shell ``` 模块来制定，比如:

``` ansible all -m shell -a 'echo $HOSTNAME' ```

但是如果是在ansible主机上有一个脚本，在不拷贝到其他机器上的时候，如果用shell模块是没法执行的，这时候可以用script模块 (实际上推送到远程机器的 ~/.ansible/tmp/ 路径下，执行完自动删除)

``` ansible all -m script -a './test.sh' ```

* copy 模块

通过copy 模块，可以拷贝单个文件，整个文件夹，以及到目标机器上创建一个文件，并直接存一些内容

```
ansible all -i inventory -m copy -a 'src=/tmp/test dest=/tmp owner=alex'
```

* fetch 模块

通过fetch 模块，可以抓取远程主机的文件。比如抓日志等.

```  ansible all -i inventory -m fetch -a 'src=/etc/resolv.conf dest=/tmp/os/' ```

* file 模块： 改变文件的属性
* lineinfile 模块：替换整行的配置，不建议使用 sed 改，因为可能会有特殊字符冲突，容易出错，使用lineinfile比较安全
* replace 模块： lineinfile 替换的是整行，使用replace替换指定字符，而不是整行替换  
* setup 模块：可以收集机器的信息: ``` -m setup -a 'filter=discovered_interpreter_python' ```

### ansible playbook

定义了执行的顺序，playbook里的几个核心元素：

Hosts: 执行的远程主机. Tasks: 任务集. Variables 变量，Templates 模板，handlers 和notify结合使用，由特定的条件出发操作，满足条件才执行，否则不执行，tags，可以选择性执行playbook中的部分代码。ansible具有幂等性，因此会自动跳过没有变化的部分，即便如此，有些代码为测试其确实没有变化的时间也非常长，此时，如果确信其没有变化，可以通过tags跳过这些代码片段。



* Ansible-playbook [cheatsheet](https://docs.ansible.com/ansible/latest/command_guide/cheatsheet.html)， 加上 -C 表示测试，但不真正应用

```
ansible-playbook -i /path/to/my_inventory_file -u my_connection_user -k -f 3 -T 30 -t my_tag -m /path/to/my_modules -b -K my_playbook.yml
```

* 一个简单的示例，state默认就是present，意味着只要机器上存在就行，如果设置为 latest，则表示nginx必须为最新版本，如果有其他版本，则会更新。同时创建一个文件，文件名通过 vars 传过来的。通过命令执行 ``` ansible-playbook -i inventory -b -f 3 playbook/playbook.yaml ``` ，其中 -b 则表示become成某个user，默认为root。-f 表示fork出3个线程执行

  ```yaml
  - name: configure nginx
    hosts: appservers
    become: yes
    tasks:
    - name: install nginx (state=present is optional)
      ansible.builtin.apt:
        name: nginx
        state: present
    - name: touch a file
      file: path=/tmp/{{ file_name }} state=touch mode='0644'
    vars:
      file_name: "alexliutest"
  ```

* 在playbook里，可以加上 gather_facts: no 不收集机器信息，这样加快执行速度

* 使用角色 role 可以解决一些复杂项目

* Handler 和 Notify，是配对一起使用。handler有点类似于mysql的触发器(比如mysql里的第一张表进行修改，会触发另外一张表的改变)。在ansible里 notify就是触发器，handler就是触发后执行的动作。handler的本质就是一个task 列表。比如我们可以用这个功能做到，当配置文件发生变化后，就重新启动服务。示例:

  ```yaml
  - name: configure nginx
    hosts: appservers
    become: true
    tasks:
    - name: create nginx group
      group: name=nginx state=present
    - name: craete nginx user
      user: name=nginx groups=nginx
    - name: install nginx
      apt:
        name: nginx
        state: present
    - name: create log folder
      file: path=/var/log/nginx owner=nginx group=nginx state=directory
    - name: copy nginx config
      copy: src=conf/nginx.conf dest=/etc/nginx/nginx.conf owner=nginx
      notify: restart nginx
  
    handlers:
    - name: restart nginx
      systemd: name=nginx enabled=true state=restarted
  ```

  

* tags，给task 指定tag，这样在执行的时候，可以执行指定的tag，执行的时候，可以加上 -t 来指定tag，示例: ``` ansible-playbook -i inventory -t config playbook/playbook.yaml ```

```yaml
  - name: copy nginx config                                                                                
    copy: src=conf/nginx.conf dest=/etc/nginx/nginx.conf owner=nginx                                       
    notify: restart nginx                                                                                  
    tags: config
```

如果想要列出来某个playbook里的所有tag，可以使用 --list-tags 参数

```
ansible-playbook --list-tags playbook/playbook.yaml
```

* 变量. 通过 \{\{ variable_name \}\} 的方式来进行调用。变量的定义和引用方法有以下几种: 

1. 如果是playbook中， Ansible 的 setup gather_facts 中已经定义好的，引用的时候可以通过setup模块中输出的变量 ``` {{ ansible_nodename }} ``` 引用，需要注意的是，使用这个功能，必须在playbook中，且不能关闭 gather_facts

2. 如果playbook中引用了变量，也可以在执行playbook的时候，通过 -e 参数来指定变量值，比如 ```  -e software_name=telnet``` 将 software_name定义为 telnet

3. 在playbook中，直接通过 vars 代码块进行定义

   ```yaml
   - hosts: appservers
     become: true
     vars:
       - filename: test1
     tasks:
       - name: craete test1 file
         file: path=/tmp/{{ filename }}.log state=touch
   ```

4. 使用变量文件，示例

   ```
   # 创建变量文件
   cat playbook/var_file.yaml
   ---
   # variable files
   package_name: vsftpd
   service_name: vsftpd
   
   # 在playbook中引用
   - hosts: appservers
     become: true
     vars_files:
       - var_file.yaml
     tasks:
       - name: install {{ package_name }}
         apt: name={{ package_name }} state=present
       - name: start service
         systemd: name={{ service_name }} state=started
   
   ```

* 使用template，可以将变量，以及一些if，for等逻辑判断(jinja2语法)，放到 template file文件中(文件名一定要是 .j2)，这样在playbook的时候，通过template指令动态的加载配置文件。一般template文件要单独放到一个文件夹下。示例：

  ```
  # 比如先改nginx.conf.j2文件，将worker_processes 的数量，设置为当前主机的 cpu的数量的3倍(当前主机的vcpu可以根据 ansible_processor_vcpus 变量获得，注意要开启gather_fact，如果关闭就获取不到了)。nginx.conf.j2部分配置如下(其余部分就是nginx.conf)，将文件放到 playbook 文件夹同级的 templates文件夹下:
  worker_processes  {{ ansible_processor_vcpus ** 3 }};
  
  # 创建 playbook文件，注意观察是从 template里将配置文件渲染过来的
  - hosts: appservers
    become: true
    tasks:
      - name: install nginx
        apt: name=nginx state=present
      - name: copy nginx conf
        template: src=../templates/nginx.conf.j2 dest=/etc/nginx/nginx.conf
        notify: restart nginx
      - name: start nginx
        systemd: name=nginx state=started enabled=yes
    handlers:
      - name: restart nginx
        systemd: name=nginx state=reloaded
  
  ```

  * 在template里使用 for 循环动态生成文件，示例：

    ```
    #创建 nginx.conf.j2 配置文件，通过 server_lists 变量，读出来 port 和domain，然后生成 server block块
    {% for list in server_lists %}
    
      server {
        listen       {{ list.port }};
        server_name  {{ list.domain }};
        access_log   logs/domain1.access.log  main;
        root         html;
      }
    
    {% endfor %}
    # playbook 示例
    - hosts: appservers
      become: true
      vars:
        server_lists:
          - domain: www.abc.com
            port: 8888
          - domain: www.bcd.com
            port: 8080
      tasks:
        - name: create nginx config
          template: src=../templates/nginx2.conf.j2 dest=/etc/nginx/nginx.conf
          notify: restart nginx
      handlers:
        - name: restart nginx
          systemd: name=nginx state=restarted
    ```

  * 在 template 通过if 来判断变量是否存在，如果存在，则生成，如果不存在，则不生成

    ```
    # 在server_lists变量里，判断是否有domain定义，如果有，则增加 server_name ，如果没有就不增加
    {% for list in server_lists %}
      server {
        listen       {{ list.port }};
    {% if list.domain is defined %}
        server_name  {{ list.domain }};
    {% endif %}
        access_log   logs/domain1.access.log  main;
        root         html;
      }
    {% endfor %}
    
    # playbook的定义如下
    - hosts: appservers
      become: true
      vars:
        server_lists:
          - domain: www.abc.com
            port: 8888
          - domain: www.bcd.com
            port: 8080
          - port: 9999
      tasks:
        - name: create nginx config
          template: src=../templates/nginx3.conf.j2 dest=/etc/nginx/nginx.conf
          notify: restart nginx
      handlers:
        - name: restart nginx
          systemd: name=nginx state=restarted
    
    ```

* 在tasks中使用when来进行条件判断，比如使用when判断操作系统，如果是 redhat则执行某个操作，如果是ubuntu，则执行另外一个。也可以根据操作系统版本，比如redhat 6，拷贝某一个template，如果是redhat 7，拷贝另外一个tempate文件等

  ```
  - host: appservers
    become: true
    tasks:
      - name: install nginx
        apt: name=nginx state=present
        when: ansible_os_family == "Debian"
      - name: install nginx on redhat
        yum: name=nginx state=present
        when: ansible_os_family == "RedHat"
  ```

* 在tasks中使用 with_items 中进行循环，使用for只能在template文件中进行循环，with_items 则可以在playbook的tasks中进行循环。示例：创建2个用户

  ```
  - hosts: appservers
    become: true
    tasks:
      - name: add some users
        user: name={{ item }} state=present groups=root
        with_items:
          - testuser1
          - testuser2
  ```

### ansible roles 目录编排

Roles比较适合于较大的项目，Roles 的概念来自于这样的想法：通过 include 包含文件并将files, tasks, handlers, vars，templates组合在一起，组织成一个简洁、可重用的抽象对象。这种方式可使你将注意力更多地放在大局上，只有在需要时才去深入了解细节。

* files: 存放由copy或者 script模块调用的文件
* templates: 放 .j2的模板文件
* tasks: 放 task,role等基本元素，至少要有一个 main.yml 文件，其他文件需要在此文件中通过include包含
* handlers：至少有一个 main.yml文件，其他文件通过 include 包含
* vars: 定义变量，至少有一个main.yml
* meta: 定义当前角色的特殊设定及其依赖关系，至少一个main.yml
* default: 设置默认变量时使用此目录中的main.yml文件，优先级比 vars 低

#### 创建role

 按照特定的目录结构，将yaml文件放到指定的role中，注意main.yml是入口

* 调用角色

  ```
  - hosts: appservers
  	become: true
  	roles:
  	  - mysql
  	  - nginx
  	  - memcached
  ```

  

### ansible-galaxy 安装第三方playbook

* 从互联网上下载ansible各种role，本质就是一个文件夹，在 ~/.ansible/roles/ 路径下

```
 ansible-galaxy install geerlingguy.mysql
```

* 安装第三方collection

  ```
  # 列出现有的collection 
  ansible-galaxy collection list
  # 安装第三方，比如azure的插件
  ansible-galaxy collection install azure.azcollection
  ```

  

