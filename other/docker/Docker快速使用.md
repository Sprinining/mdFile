---
title: Docker快速使用
date: 2024-10-22 11:17:34 +0800
categories: [other, docker]
tags: [Docker]
description: 镜像操作、容器操作、保存以及分享镜像
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