---
title: 使用Docker搭建Chirpy博客
date: 2024-10-25 02:01:02 +0800
categories: [other, blog]
tags: [Blog, Chripy, Docker]
description: 制作镜像部署Chirpy
---
## 使用Docker搭建Chirpy博客

### 成功版

```shell
docker pull n1ce2cv/chirpyblog

docker run -dit --name blogok -p 4100:4000 -v .:/srv/jekyll --workdir /srv/jekyll chirpyblog:v1.0 bundle exec jekyll serve --host 0.0.0.0 --port 4000
```

### 失败版1（待解决）

方案：基于 `debian:bullseye`，构建一个新的镜像，用于部署。

修改基础镜像 `debian:bullseye`：

```shell
# 更新源
cat > /etc/apt/sources.list << EOF
deb http://mirrors.ustc.edu.cn/debian bullseye main contrib non-free
deb http://mirrors.ustc.edu.cn/debian bullseye-updates main contrib non-free
deb http://mirrors.ustc.edu.cn/debian bullseye-backports main contrib non-free
deb-src http://mirrors.ustc.edu.cn/debian bullseye-backports main contrib non-free
EOF

# 更新系统
sudo apt update
sudo apt upgrade -y

# 安装构建 Ruby 所需的依赖包
sudo apt install -y build-essential libssl-dev libreadline-dev zlib1g-dev
# 使用 rbenv 来管理 Ruby 版本。首先，安装 rbenv 和 ruby-build
# 安装 git
sudo apt install -y git
# 克隆 rbenv 仓库
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
# 设置环境变量
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
# 克隆 ruby-build 仓库
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
# 安装完成后，rbenv 就可以使用 curl 或 wget 来下载所需的依赖包
sudo apt install -y curl wget
# 安装 OpenSSL 和相关依赖
sudo apt install -y libssl-dev zlib1g-dev build-essential libreadline-dev
sudo apt install -y libffi-dev libyaml-dev
rbenv install 3.3.5
# 设置全局使用 Ruby 3.3.5
rbenv global 3.3.5
# 确认 Ruby 安装成功并检查版本
ruby -v

# Ruby 安装完成后，Gem 会自动安装。然后可以安装 Bundler
gem install bundler -v 2.3.25

# 使用 Bundler 安装 Jekyll：
gem install jekyll -v 4.3.4

# 验证安装
ruby -v      # 应该显示 3.3.5
gem -v       # 应该显示 3.5.16
bundler -v   # 应该显示 2.5.16
git --version # 应该显示 2.30.2
jekyll -v    # 应该显示 4.3.4
```

制作镜像 `debianchirpy:latest`

启动容器

```shell
docker run -dit --name blogtest -p 4200:4000 -v .:/srv/jekyll --workdir /srv/jekyll debianchirpy:latest /bin/bash
```

进入容器内 `/srv/jekyll` 更新包

```shell
bundle install
```

然后启动博客，启动失败

```shell
bundle exec jekyll serve --host 0.0.0.0 --port 4000
```

### 失败版2（待解决）

方案：基于 `debian:bullseye`，构建一个新的镜像，用于部署。

#### 构建镜像

Dockfile 文件（确保在博客的根目录下）：

```dockerfile
FROM jekyll/jekyll:latest

# 将当前目录中的文件复制到容器中的 /srv/jekyll
COPY . /srv/jekyll

# 设定工作目录
WORKDIR /srv/jekyll

# 安装依赖并构建站点
RUN bundle install

# 启动服务
CMD ["jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--watch"]
```

docker-compose.yml 文件（确保在博客的根目录下）：

```yaml
services:
chirpy:
build:
  context: .
  dockerfile: Dockerfile
image: chirpyblog # 设置镜像名称
ports:
      - "8888:4000" # 将容器的 4000 端口映射到宿主机的 8888 端口
    volumes:
      - .:/srv/jekyll # 将本地目录挂载到容器内，以便实时更新
    environment:
      - JEKYLL_ENV=production # 设置环境变量
```

然后在博客的根目录下执行构建命令 `docker compose build`：

```shell
root@spring:~/GithubRepo/sprinining.github.io# docker compose build
[+] Building 685.0s (10/10) FINISHED                                                                        docker:default
 => [chirpy internal] load build definition from Dockerfile                                                           0.0s
 => => transferring dockerfile: 343B                                                                                  0.0s
 => [chirpy internal] load metadata for docker.io/jekyll/jekyll:latest                                                0.0s
 => [chirpy internal] load .dockerignore                                                                              0.0s
 => => transferring context: 2B                                                                                       0.0s
 => [chirpy internal] load build context                                                                              0.1s
 => => transferring context: 65.25kB                                                                                  0.0s
 => CACHED [chirpy 1/4] FROM docker.io/jekyll/jekyll:latest                                                           0.0s
 => [chirpy 2/4] COPY . /srv/jekyll                                                                                   0.4s
 => [chirpy 3/4] WORKDIR /srv/jekyll                                                                                  0.1s
 => [chirpy 4/4] RUN bundle install                                                                                 682.2s
 => [chirpy] exporting to image                                                                                       2.1s 
 => => exporting layers                                                                                               2.0s 
 => => writing image sha256:288e34cbff59701f4d6e95b404d71b2a190ab875f958c5c0a1b8a353d97a1fab                          0.0s 
 => => naming to docker.io/library/chirpyblog                                                                         0.0s 
 => [chirpy] resolving provenance for metadata file                                                                   0.0s 
```

#### 运行容器

- 手动运行（推荐）

```shell
docker run -dit --name test -v .:/srv/jekyll -p 8888:4000 chirpyblog:latest /bin/bash
```

- 通过 docker-compose.yml 运行

```shell
docker compose up -d
```

#### 启动博客

进入容器的终端后，在容器内执行下面的命令，会生成 `_site` 目录，其中包含网站的静态文件：

```shell
jekyll serve --host 0.0.0.0 --port 4000 --watch
```

#### 常见报错

报错 1：`fatal: detected dubious ownership in repository at '/srv/jekyll' To add an exception for this directory, call: 	git config --global --add safe.directory /srv/jekyll`

进入容器内部修改文件权限：

```shell
chmod -R 777 /srv/jekyll
```

报错 2：`Conversion error: Jekyll::Converters::Scss encountered an error while converting 'assets/css/jekyll-theme-chirpy.scss':`

导入缺失的文件 `assets/css/jekyll-theme-chirpy.scss`，放到主机的这个位置就行，会同步到容器内，因为设置了目录挂载。

报错 3（未解决）：`fatal: detected dubious ownership in repository at '/srv/jekyll'`

容器内执行(git最好大于 2.35 版本)：

```shell
git config --global --add safe.directory /srv/jekyll
```

无法把 git 升级到 2.35 版本，软件源没有这个版本。
