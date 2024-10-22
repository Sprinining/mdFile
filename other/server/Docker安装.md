---
title: Docker安装
date: 2024-10-22 04:01:47 +0800
categories: [other, server]
tags: [Server, Linux, Docker]
description: Debian 11.1.0 64位 安装 Docker
---
## Docker安装

- 操作系统：Linux
- 服务器镜像：Debian 11.1.0 64位
- 官方文档：[dockerdocs](https://docs.docker.com/engine/install/debian/#install-from-a-package)
- 最好先替换下源

### 安装流程

#### 步骤 1：卸载旧版本

在安装 Docker Engine 之前，需要卸载所有有冲突的软件包。

发行版维护者在其存储库中提供 Docker 软件包的非官方发行版。必须先卸载这些软件包，然后才能安装 Docker Engine 的官方版本。

要卸载的非官方软件包包括：

- `docker.io`
- `docker-compose`
- `docker-doc`
- `podman-docker`

此外，Docker Engine 依赖于`containerd`和`runc`。Docker Engine 将这些依赖项捆绑为一个包：`containerd.io`。如果之前安装了`containerd`或`runc`，需要卸载它们以避免与 Docker Engine 捆绑的版本冲突。

运行以下命令卸载所有冲突的包：

```shell
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
```

#### 步骤 2：使用 apt 存储库安装

##### 设置 Docker 的 `apt` 存储库。

```shell
# Add Docker's official GPG key:
sudo apt-get update
# 安装或更新 ca-certificates（用于验证 SSL 证书的 CA 证书）和 curl（一个用于在命令行中发送 HTTP 请求的工具）
sudo apt-get install ca-certificates curl
# 创建 /etc/apt/keyrings 目录，并设置其权限为 0755（即所有者可读写，组和其他用户可读和执行）
sudo install -m 0755 -d /etc/apt/keyrings
# 使用 curl 下载 Docker 的 GPG 密钥文件，并将其保存到 /etc/apt/keyrings/docker.asc
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
# 修改 /etc/apt/keyrings/docker.asc 文件的权限，使所有用户都可以读取该文件
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
# 将 Docker 的 APT 源添加到系统中，以便可以安装 Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

##### 报错处理

1. `sudo: unable to resolve host spring: Name or service not known`

`/etc/hosts` 原始内容：

```
127.0.0.1	localhost
127.0.1.1	localhost.ctyun.cn	localhost

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

加上主机名称 spring，改为：

```
127.0.0.1	localhost spring
127.0.1.1	localhost.ctyun.cn	localhost

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

2. 执行命令 `curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc` 时，返回 `curl: (35) OpenSSL SSL_connect: Connection reset by peer in connection to download.docker.com:443`

手动下载文件 `https://download.docker.com/linux/debian/gpg`，放到 `/etc/apt/keyrings/` 下，然后改名为 `docker.asc`。

### 测试

终端输入 `docker -v` 查看版本号。

```shell
root@spring:~# docker -v
Docker version 27.3.1, build ce12230
```

### 镜像加速

对于 Ubuntu16.04+、Debian8+、CentOS7 系统，在 `/etc/docker/daemon.json` 中写入如下内容（如果文件不存在新建该文件）：

```json
{
    "registry-mirrors": [
        "https://docker.mirrors.ustc.edu.cn/"
    ]
}
```

之后重新启动服务：

```shell
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```

执行 **docker info**，如果从结果中看到了如下内容，说明配置成功：

```shell
$ docker info
 Registry Mirrors:
  https://docker.mirrors.ustc.edu.cn/
```



