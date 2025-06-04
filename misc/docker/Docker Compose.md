---
title: Docker Compose
date: 2024-10-24 12:08:20 +0800
categories: [other, docker]
tags: [Docker]
description: 命令式安装以及 compose.yaml 文件
---
## Docker Compose

- 上线：`docker compose up -d`，`-d` 是以后台方式
- 下线：`docker compose down`，具体参数可以用 `--help` 查看
- 启动：`docker compose start x1 x2 x3`：x1，x2，x3 是在文件 `compose.yaml` 中配置的应用
- 停止：`docker compose stop x1 x2 x3`
- 扩容：`docker compose scale x2=3`，让 x2 的实例启动 3 份

### 命令式安装

```shell
# 创建网络
$ docker network create blog

# 启动mysql
$ docker run -d -p 3306:3306 \
-e MYSQL_ROOT_PASSWORD=123456 \
-e MYSQL_DATABASE=wordpress \
-v mysql-data:/var/lib/mysql \
-v /app/myconf:/etc/mysql/conf.d \
--restart always --name mysql \
--network blog \
mysql:latest

# 启动wordpress
$ docker run -d -p 8080:80 \
-e WORDPRESS_DB_HOST=mysql \
-e WORDPRESS_DB_USER=root \
-e WORDPRESS_DB_PASSWORD=123456 \
-e WORDPRESS_DB_NAME=wordpress \
-v wordpress:/var/www/html \
--restart always --name wordpress-app \
--network blog \
wordpress:latest
```

### compose.yaml

- [官方文档](https://docs.docker.com/compose/)

```yaml
name: myblog
services:
    mysql:
        container_name: mysql # 不加这个就会使用服务名
        image: mysql:latest
        ports:
            - "3306:3306"
        environment:
            - MYSQL_ROOT_PASSWORD=123456
            - MYSQL_DATABASE=wordpress
        volumes:
            - mysql-data:/var/lib/mysql # 卷映射
            - /app/myconf:/etc/mysql/conf.d # 目录挂载
        restart: always
        networks:
            # 自定义网络
            - blog

    wordpress:
        image: wordpress
        ports:
            - "8080:80"
        environment:
            WORDPRESS_DB_HOST: mysql
            WORDPRESS_DB_USER: root
            WORDPRESS_DB_PASSWORD: 123456
            WORDPRESS_DB_NAME: wordpress
        volumes:
            - wordpress:/var/www/html
        restart: always
        networks:
            - blog
        depends_on:
            # 依赖于 mysql
            - mysql

volumes:
    # 卷映射
    mysql-data:
    wordpress:


networks:
    # 网络
    blog:
```

在文件所在的目录下，使用 `docker compose up -d` 在后台启动：

```shell
root@spring:~# docker compose up -d
[+] Running 5/5
 ✔ Network myblog_blog           Created                                                                              0.2s 
 ✔ Volume "myblog_mysql-data"    Created                                                                              0.0s 
 ✔ Volume "myblog_wordpress"     Created                                                                              0.0s 
 ✔ Container mysql               Started                                                                              1.9s 
 ✔ Container myblog-wordpress-1  Started                                                                              2.1s 
root@spring:~# 
```

或者用 `docker compose -f compose.yaml up -d` 来指定启动文件。