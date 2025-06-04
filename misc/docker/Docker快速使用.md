---
title: Docker快速使用
date: 2024-10-22 11:17:34 +0800
categories: [other, docker]
tags: [Docker]
description: 镜像操作、容器操作、保存以及分享镜像、目录挂载、卷映射、自定义网络
---
## Docker快速使用

### 镜像操作

1. 检索：`docker search`

搜索 nginx：

```shell
$ docker search nginx
NAME                                     DESCRIPTION                                     STARS     OFFICIAL
nginx                                    Official build of Nginx.                        20295     [OK]
nginx/nginx-ingress                      NGINX and  NGINX Plus Ingress Controllers fo…   95
nginx/unit                               This repository is retired, use the Docker o…   63
nginx/nginx-prometheus-exporter          NGINX Prometheus Exporter for NGINX and NGIN…   43
nginx/nginx-ingress-operator             NGINX Ingress Operator for NGINX and NGINX P…   2
......
```

2. 下载：`docker pull`

下载 nginx：`docker pull nginx` 等价于 `docker pull nginx:latest`，也就是下载 Tag 为 latest 的版本。也可以下载其他版本，版本 Tag 在 dockerhub 上找。

```shell
$ docker pull nginx
Using default tag: latest
latest: Pulling from library/nginx
a480a496ba95: Pulling fs layer
......
6476794e50f4: Pull complete
70850b3ec6b2: Pull complete
Digest: sha256:28402db69fec7c17e179ea87882667f1e054391138f77ffaf0c3eb388efc3ffb
Status: Downloaded newer image for nginx:latest
docker.io/library/nginx:latest
```

下载 指定版本的 nginx：

```shell
$ docker pull nginx:1.26.2-perl
```

3. 列表：`docker images`，等价于 `docker image ls`

```shell
$ docker images
REPOSITORY                               TAG           IMAGE ID       CREATED         SIZE
mcr.microsoft.com/devcontainers/jekyll   2-bullseye    33dc21359970   5 days ago      1.63GB
nginx                                    latest        3b25b682ea82   2 weeks ago     192MB
nginx                                    1.26.2-perl   21f4ed8233e7   2 months ago    236MB
jekyll/jekyll                            latest        3c7afda80cab   23 months ago   829MB
```

4. 删除：`docker rmi`，需要指定版本，或者通过镜像的 id 删除

```shell
$ docker rmi nginx:1.26.2-perl
Untagged: nginx:1.26.2-perl
Untagged: nginx@sha256:bfe724ad249d572941b3850b144c72ef7c231d29ce12ca1afaa0a97c775e96eb
Deleted: sha256:21f4ed8233e7035aedd8f47907684ac8bd0dd60f9440632b479594af745bd901
......
```

```shell
$ docker image ls
REPOSITORY                               TAG          IMAGE ID       CREATED         SIZE
mcr.microsoft.com/devcontainers/jekyll   2-bullseye   33dc21359970   5 days ago      1.63GB
nginx                                    latest       3b25b682ea82   2 weeks ago     192MB
jekyll/jekyll                            latest       3c7afda80cab   23 months ago   829MB
```

### 容器操作

1. 运行：`docker run`，`docker run --help` 可以查看帮助文档。如果没有镜像，会自动下载。

```shell
$ docker run nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
......
```

2. 查看：`docker ps`

新建一个终端，使用 `docker ps` 查看运行中的容器：

```shell
$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS     NAMES
b150fba7e9ca   nginx     "/docker-entrypoint.…"   12 seconds ago   Up 11 seconds   80/tcp    hungry_hugle
```

`ctrl + c` 退出运行中的容器后，使用 `docker ps -a` 查看所有容器：

```shell
$ docker ps -a
CONTAINER ID   IMAGE                                               COMMAND                  CREATED              STATUS                      PORTS     NAMES
b150fba7e9ca   nginx                                               "/docker-entrypoint.…"   About a minute ago   Exited (0) 46 seconds ago             hungry_hugle
6e8d4f5323a1   mcr.microsoft.com/devcontainers/jekyll:2-bullseye   "/bin/sh -c 'echo Co…"   3 days ago           Exited (0) 30 minutes ago             laughing_sinoussi
```


3. 启动：`docker start`

```shell
$ docker start b15
b15
$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS     NAMES
b150fba7e9ca   nginx     "/docker-entrypoint.…"   3 minutes ago   Up 4 seconds   80/tcp    hungry_hugle
```

4. 停止：`docker stop`

```shell
$ docker stop b15
b15
$ docker ps -a
CONTAINER ID   IMAGE                                               COMMAND                  CREATED         STATUS                      PORTS     NAMES
b150fba7e9ca   nginx                                               "/docker-entrypoint.…"   4 minutes ago   Exited (0) 17 seconds ago             hungry_hugle
6e8d4f5323a1   mcr.microsoft.com/devcontainers/jekyll:2-bullseye   "/bin/sh -c 'echo Co…"   3 days ago      Exited (0) 34 minutes ago             laughing_sinoussi
```

5. 重启：`docker restart`，无论容器是运行中还是停止了，都可以用这个命令重启

```shell
$ docker restart b15
b15
$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS     NAMES
b150fba7e9ca   nginx     "/docker-entrypoint.…"   6 minutes ago   Up 3 seconds   80/tcp    hungry_hugle
```


6. 状态：`docker stats`

```shell
$ docker stats b15
CONTAINER ID   NAME           CPU %     MEM USAGE / LIMIT     MEM %     NET I/O       BLOCK I/O   PIDS
b150fba7e9ca   hungry_hugle   0.00%     15.63MiB / 15.51GiB   0.10%     1.05kB / 0B   0B / 0B     21
......

$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS     NAMES
b150fba7e9ca   nginx     "/docker-entrypoint.…"   8 minutes ago   Up 2 minutes   80/tcp    hungry_hugle
```


7. 日志：`docker logs`


8. 进入：`docker exec`


9. 删除：`docker rm`，删除停止运行的容器，或者使用 `docker rm -f` 强制删除运行中的容器

```shell
$ docker rm -f b15
b15
$ docker ps -a
CONTAINER ID   IMAGE                                               COMMAND                  CREATED      STATUS                      PORTS     NAMES
6e8d4f5323a1   mcr.microsoft.com/devcontainers/jekyll:2-bullseye   "/bin/sh -c 'echo Co…"   3 days ago   Exited (0) 41 minutes ago             laughing_sinoussi
```

### run 细节

- 启动参数：`-d` 后台启动，`--name xxx` 命名容器为 `xxx`

```shell
$ docker run -d --name ng nginx
394b272f61435eb16e78773d37ab19f0db2bc43108d75b3cc60e21ac0a0a4115
$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS         PORTS     NAMES
394b272f6143   nginx     "/docker-entrypoint.…"   10 seconds ago   Up 9 seconds   80/tcp    ng
```

- 端口映射：使用 `-p` 参数，`docker run -d --name ng -p 88:80 nginx` 中的 `88` 是本地电脑端口，`80` 是容器端口

```shell
$ docker rm -f ng
ng
$ docker run -d --name ng -p 88:80 nginx
b50f97ef0ee828ab46cfd2f71799b4e8f24d98e43f2a8ed4858efdff7e7ccc1a
$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED              STATUS              PORTS                NAMES
b50f97ef0ee8   nginx     "/docker-entrypoint.…"   About a minute ago   Up About a minute   0.0.0.0:88->80/tcp   ng
```

然后在本地电脑的浏览器中输入 `http://127.0.0.1:88/`，就能看见 nginx 的页面。

- 修改 nginx 页面：使用 `docker exec` 进入容器，找到 `/usr/share/nginx/html` 并修改。`-i` 表示交互式操作，`-t` 表示终端，`/bin/bash` 是用的交互式 Shell

```shell
$ docker exec -it ng /bin/bash
the input device is not a TTY.  If you are using mintty, try prefixing the command with 'winpty'
```

在 Windows 上运行 git bash 来执行 docker 命令，使用 -it 参数时会报此错误，切换 PowerShell 即可。

```shell
PS C:\WINDOWS\system32> docker exec -it ng /bin/bash
root@b50f97ef0ee8:/# ls
bin   dev                  docker-entrypoint.sh  home  lib64  mnt  proc  run   srv  tmp  var
boot  docker-entrypoint.d  etc                   lib   media  opt  root  sbin  sys  usr
root@b50f97ef0ee8:/# echo "haha" > /usr/share/nginx/html/index.html
```

然后在本地电脑的浏览器中输入 `http://127.0.0.1:88/`，就能看见修改后的 nginx 的页面。

### 保存镜像

1. 提交：`docker commit`，`--help` 可以查看格式。提交一个名叫 `mynginx` ，版本为 `v1.0` 的镜像

```shell
$ docker commit -m 'update index.html' ng mynginx:v1.0
sha256:430bf70e704e03ce31c24b59529e508b9d303a9a2f6e2a2ffafda5506a87245e
$ docker images
REPOSITORY                               TAG          IMAGE ID       CREATED              SIZE
mynginx                                  v1.0         430bf70e704e   About a minute ago   192MB
mcr.microsoft.com/devcontainers/jekyll   2-bullseye   33dc21359970   5 days ago           1.63GB
nginx                                    latest       3b25b682ea82   2 weeks ago          192MB
jekyll/jekyll                            latest       3c7afda80cab   23 months ago        829MB
```

2. 保存：`docker save`，`-o` 参数把镜像写到一个文件里

```shell
$ docker save -o mynginx.tar mynginx:v1.0
$ ls
 mynginx.tar
```

3. 加载：`docker load`

先删除这两个已有的 nginx 镜像：

```shell
$ docker rm -f ng
ng
d
$ docker images
REPOSITORY                               TAG          IMAGE ID       CREATED         SIZE
mynginx                                  v1.0         430bf70e704e   5 minutes ago   192MB
mcr.microsoft.com/devcontainers/jekyll   2-bullseye   33dc21359970   5 days ago      1.63GB
nginx                                    latest       3b25b682ea82   2 weeks ago     192MB
jekyll/jekyll                            latest       3c7afda80cab   23 months ago   829MB
$ docker rmi 430bf70e704e 3b25b682ea82
Untagged: mynginx:v1.0
Deleted: sha256:430bf70e704e03ce31c24b59529e508b9d303a9a2f6e2a2ffafda5506a87245e
......
$ docker images
REPOSITORY                               TAG          IMAGE ID       CREATED         SIZE
mcr.microsoft.com/devcontainers/jekyll   2-bullseye   33dc21359970   5 days ago      1.63GB
jekyll/jekyll                            latest       3c7afda80cab   23 months ago   829MB
```

再导入之前导出的 nginx 镜像，`-i` 参数表示从一个文件中导入：

```shell
$ docker load -i mynginx.tar
Loaded image: mynginx:v1.0
$ docker images
REPOSITORY                               TAG          IMAGE ID       CREATED         SIZE
mynginx                                  v1.0         430bf70e704e   9 minutes ago   192MB
mcr.microsoft.com/devcontainers/jekyll   2-bullseye   33dc21359970   5 days ago      1.63GB
jekyll/jekyll                            latest       3c7afda80cab   23 months ago   829MB
$ docker run -d --name app -p 89:80 mynginx:v1.0
f4afb14bc79c6f7e8f964cee09aef2925213f95442a69913c24dae5e3024977e
$ docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                NAMES
f4afb14bc79c   mynginx:v1.0   "/docker-entrypoint.…"   15 seconds ago   Up 14 seconds   0.0.0.0:89->80/tcp   app
```

然后在本地电脑的浏览器中输入 `http://127.0.0.1:89/`，就能看见修改后的 nginx 的页面。

### 分享镜像

1. 登录：`docker login`

```shell
$ docker login
Authenticating with existing credentials...
Login Succeeded
```

2. 命名：`docker tag`，`--help` 查看用法为 `docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]`，推送到 dockerhub 的镜像名称必须以用户名开头

```shell
$ docker tag mynginx:v1.0 n1ce2cv/myng:v1.0
$ docker images
REPOSITORY                               TAG          IMAGE ID       CREATED          SIZE
n1ce2cv/myng                             v1.0         430bf70e704e   18 minutes ago   192MB
mynginx                                  v1.0         430bf70e704e   18 minutes ago   192MB
mcr.microsoft.com/devcontainers/jekyll   2-bullseye   33dc21359970   5 days ago       1.63GB
jekyll/jekyll                            latest       3c7afda80cab   23 months ago    829MB
```

3. 推送：`docker push`

```shell
$ docker push n1ce2cv/myng:v1.0
The push refers to repository [docker.io/n1ce2cv/myng]
de60cfb9b744: Preparing
......
```

然后就能在 dockerhub 中看见推送上去的镜像。最好制作一个 `Tag` 为 `latest` 的镜像，这样不带 `Tag` 的 `pull` 就会默认下载这个最新的镜像。

### 目录挂载

1. 将**本地目录**挂载到**容器内的目录**。

```shell
root@spring:~# docker run -d -p 82:80 -v /app/nghtml:/usr/share/nginx/html --name ng nginx
```

这里的 `-v /app/nghtml:/usr/share/nginx/html` 选项是一个**绑定挂载**，其含义是：

- `/app/nghtml` 是**本地主机**上的目录（服务器上的）。
- `/usr/share/nginx/html` 是**容器内部**的目录。

挂载的效果是：容器内部的 `/usr/share/nginx/html` 目录将映射到主机的 `/app/nghtml` 目录（没有会自动新建）。也就是说，**当你在容器内修改 `/usr/share/nginx/html` 中的文件时，这些变化会反映在主机的 `/app/nghtml` 中，反之亦然**。

2. 文件覆盖。

使用 `-v` 进行挂载时，挂载的本地目录会覆盖容器内的相应目录。如果本地目录是空的，容器内原本的文件就会被隐藏或看不到。此时容器内的 `/usr/share/nginx/html` 目录是空的，没有 `index.html` 文件。

```shell
root@spring:~# curl localhost:82
<html>
<head><title>403 Forbidden</title></head>
<body>
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.27.2</center>
</body>
</html>
root@spring:~# docker exec -it ng /bin/bash
root@8dfbb8b56a75:/# cd /usr/share/nginx/html/
root@8dfbb8b56a75:/usr/share/nginx/html# ls
root@8dfbb8b56a75:/usr/share/nginx/html# ls
```

若此时在本地目录 `/app/nghtml/` 下新建文件 `index.html` 并输入内容，此时 `localhost:82` 网页就会有内容。并且容器内部的目录 `/usr/share/nginx/html` 下也会出现这个文件。

```shell
root@spring:~# cd /app/nghtml/
root@spring:/app/nghtml# ls
root@spring:/app/nghtml# echo "haha" > index.html
root@spring:/app/nghtml# curl localhost:82
haha
```

如果将容器删除，容器内的数据会丢失，本地的 `/app/nghtml/` 仍会保存，下次再创建容器且把本地的这个目录挂载到容器中后，再打开网页，会直接显示 `haha`。

### 卷映射

1. 映射到卷 `nghtml`。

```shell
root@spring:~# docker run -d -p 82:80 -v nghtml:/usr/share/nginx/html --name ng nginx
```

**Docker 会创建一个卷**，并将该卷挂载到容器内的 `/usr/share/nginx/html` 目录中。卷的数据默认保存在 Docker 管理的空间中，不会直接与本地主机的文件系统关联。`nghtml` 在主机的 `/var/lib/docker/volumes/` 目录下。

```shell
root@spring:/var/lib/docker/volumes/nghtml/_data# ls
50x.html  index.html
```

使用 `docker volume inspect nghtml` 可以查看卷的内容

```shell
root@spring:~# docker volume inspect nghtml
[
    {
        "CreatedAt": "2024-10-24T10:14:57+08:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/nghtml/_data",
        "Name": "nghtml",
        "Options": null,
        "Scope": "local"
    }
]
```

2. 与目录挂载的区别

| 特性         | 目录挂载 (Bind Mount)              | 卷映射 (Volume)                              |
| ------------ | ---------------------------------- | -------------------------------------------- |
| 数据存储位置 | 宿主机上的指定路径                 | Docker 自动管理的存储区域                    |
| 管理方式     | 由宿主机文件系统控制               | 由 Docker 自动管理                           |
| 性能         | 性能取决于宿主机文件系统           | 高效，专为容器设计，性能较好                 |
| 适用场景     | 开发环境，调试时需要实时同步       | 数据持久化、生产环境、多容器数据共享         |
| 移植性       | 依赖宿主机路径，不利于跨平台和环境 | 不依赖宿主机路径，容易跨平台和多环境使用     |
| 宿主机访问   | 宿主机可以直接读写挂载目录         | 宿主机无法直接访问，需通过 Docker 操作卷     |
| 数据安全性   | 容器销毁时，宿主机上的文件不受影响 | 容器销毁时，卷仍保留数据                     |
| 多容器共享   | 不能直接共享，需挂载相同宿主机路径 | 可以轻松实现多个容器挂载同一卷，实现数据共享 |

如果需要灵活、直接与宿主机目录交互，使用目录挂载；如果需要更好的数据管理和持久化方案，使用卷映射。

3. 删除卷

```shell
root@spring:~# docker volume ls
DRIVER    VOLUME NAME
local     nghtml
root@spring:~# docker rm -f ng 
ng
root@spring:~# docker volume rm nghtml 
nghtml
```

- `docker volume ls` ：查看所有的卷。
- `docker volume rm <volume_name>`：删除指定卷。
- `docker volume prune`：强制删除未使用的卷（即没有被任何容器使用的卷），加上 `-f` 参数可以不用确认操作，直接删除。
- `docker volume rm volume1 volume2 volume3` ：删除多个卷。
- 卷被删除后，存储在该卷中的数据也会永久丢失，无法恢复。如果卷仍然在被运行中的容器使用，需要先停止并删除使用该卷的容器，或者使用 `docker rm -f` 强制删除容器后再删除卷。

### 自定义网络

1. 通过外部网络访问另一个容器的端口。

先启动两个容器：`ng1`，`ng2`，映射到主机的端口分别为 `4100`，`4200`。

```shell
root@spring:~# docker run -d -p 4100:80 --name ng1 nginx
e796fcd9626976257704ecea3b0bfd8b3ae9b64f166f3c610e54b27bc28ccd56
root@spring:~# docker run -d -p 4200:80 --name ng2 nginx
160c2f68e0c9fe905056206190ef1c60783d9f68e459bfcbf41cdef1a600ae7f
```

然后进入容器 `ng1` 内部，访问容器 `ng2` 的页面。确保安全组中已经开放了 4100 的端口，不如访问不了。

```shell
root@spring:~# curl 服务器的公网ip:4100
```

2. docker 为每个容器分配唯一 ip，使用`容器 ip + 容器端口`可以互相访问

每一个容器启动的时候都会加入 docker 的默认网络 `docker0`，在安装 docker 的时候就会有这个网络。使用 `ip a` 可以看到这个 `docker0` 网卡。

```shell
root@spring:~# ip a
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:a5:46:07:fc brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:a5ff:fe46:7fc/64 scope link 
       valid_lft forever preferred_lft forever
```

可以看见 ip 地址为 `172.17.0.1`。使用 `docker inspect ng1` 也能查到网络信息（等价于 `docker container inspect ng1`）。

```shell
root@spring:~# docker inspect ng1
root@spring:~# docker inspect ng2
```

查到 `ng1` 的为：`"Gateway": "172.17.0.1", "IPAddress": "172.17.0.4"`

查到 `ng2` 的为：`"Gateway": "172.17.0.1", "IPAddress": "172.17.0.5"`

进入容器 `ng1` 通过内部网络访问容器 `ng2` 的端口：

```shell
root@spring:~# docker exec -it ng1 /bin/bash
root@e796fcd96269:/# curl 127.17.0.5:80
```

注意：访问的是容器 `ng2` 的 `80` 端口，而不是映射到主机并对外暴露的 `4200` 端口。

3. 创建自定义网络，容器名就是稳定域名。

使用 `docker network create mynet` 创建一个名叫 `mynet` 的自定义网络。之前的 `docker0` 就是 `bridge`，`docker0` 默认不支持主机域名。

```shell
root@spring:~# docker network create mynet
1db9050c72fcf19637089db491aafbd12da2295f0669517a559cd49dc23358d8
root@spring:~# docker network ls
NETWORK ID     NAME                         DRIVER    SCOPE
ba608dc5d5d9   bridge                       bridge    local
051c14b34e86   host                         host      local
1db9050c72fc   mynet                        bridge    local
444b1b1ee344   none                         null      local
```

使用 `--network mynet` 参数，让容器加入自定义网络 `mynet`：

```shell
root@spring:~# docker run -d -p 4100:80 --name ng1 --network mynet nginx
25afdae56ff2b225d0e9328540f96a8bfd94eff3a396421f9771a4a1d16a2413
root@spring:~# docker run -d -p 4200:80 --name ng2 --network mynet nginx
a37ffb9606a096ef081dd9e2403fe047ef7017097983beda5de46caf3cf40de2
```

现在就能使用域名进行访问：

```shell
root@spring:~# docker exec -it ng1 /bin/bash
root@25afdae56ff2:/# curl ng2:80
```

4. 删除自定义网络

- `docker network ls`：列出所有现有的 Docker 网络，找到想要删除的自定义网络。

- `docker network inspect <network_name>`：查看是否有容器在使用。

- `docker network disconnect <network_name> <container_name_or_id>`：如果不想删除容器，只是想将它们从自定义网络中移除，可以使用这个命令。

- `docker network rm <network_name>`：删除指定网络。
- `docker network prune`：删除所有未使用的网络，加上 `-f` 参数可以跳过确认，直接删除。

- **默认网络**（如 `bridge`、`host` 和 `none`）是 Docker 自动创建的，不能被删除。
