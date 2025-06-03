## 基于 Chirpy 的 Jekyll 博客：Docker + GitHub Actions 全自动 CI/CD 部署指南

操作系统： 

- Ubuntu 24.04 Server

最终目标：

- **本地/构建端（GitHub Actions）构建好 `_site/`**；
- **把 `_site/` 上传到服务器上的某个目录中（比如 `/home/ubuntu/chirpy-site/_site`）**；
- **服务器上用 Docker + Docker Compose 启动一个 Nginx 容器，挂载这个目录，提供服务**；
- **每次代码更新 → Actions 自动构建 + 上传 `_site` + 重启容器**。

### 替换 apt 镜像

#### 给 Ubuntu 24.04 Server 版换国内镜像（阿里云示例）

1. 备份原有的 `sources.list`

```bash
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
```

2. 替换为阿里云源

```bash
sudo nano /etc/apt/sources.list
```

清空内容，粘贴以下内容（针对 Ubuntu 24.04 `noble`）：

```bash
deb http://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
```

然后 `Ctrl+O` 保存，`Enter` 确认，`Ctrl+X` 退出。

3. 更新软件包索引

```bash
sudo apt update
```

如果看到类似：

```bash
Get:1 http://mirrors.aliyun.com/ubuntu noble InRelease [some KB]
...
```

说明镜像源生效，国内加速成功

#### 清华源 / 中科大源

清华源（TUNA）：

```txt
https://mirrors.tuna.tsinghua.edu.cn/ubuntu/
```

中科大（USTC）：

```txt
https://mirrors.ustc.edu.cn/ubuntu/
```

> 用法和上面一样，只需把 `mirrors.aliyun.com` 换成对应的域名。

关于 `# Ubuntu sources have moved to /etc/apt/sources.list.d/ubuntu.sources`

这是 Ubuntu 22.10 之后新增的一种 **`deb822` 格式源管理机制**，但：

- 它 **不会禁用你自己写在 `/etc/apt/sources.list` 里的源**；
- 两者是 **并行** 的，系统会同时读取 `/etc/apt/sources.list` 和 `/etc/apt/sources.list.d/*.sources`；
- 如果你手动设置了 `/etc/apt/sources.list`，就优先按你写的来（不会冲突）；
- 如果你希望清爽一点，也可以把 `/etc/apt/sources.list.d/ubuntu.sources` 文件**注释掉或删掉**，不过没必要。

### 安装 Docker

#### 设置 Docker 的 apt repository

```bash
# 更新系统软件包索引
sudo apt-get update

# 安装所需依赖（用于添加 HTTPS 认证源）
sudo apt-get install ca-certificates curl

# 创建 apt key 存放目录（如果已经存在不会报错）
sudo install -m 0755 -d /etc/apt/keyrings

# 下载 Docker 官方的 GPG 公钥，并保存为 docker.asc（用于验证软件源的合法性）
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

# 设置 docker.asc 文件权限为所有用户可读（必须，否则 apt 会拒绝使用）
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 添加 Docker 官方软件源到 APT 配置中
# 使用的是当前系统的版本代号（如 noble、jammy 等）
# 使用刚刚下载的 docker.asc 文件做签名验证
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 再次更新软件包索引，使新的 Docker 源生效
sudo apt-get update
```

#### 安装 Docker 相关软件包

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### 验证 Docker 安装

```bash
docker version
```

如果输出包含 Client 和 Server 字段，说明安装成功。

#### 替换 Docker 镜像

创建或编辑 Docker 配置文件：

```bash
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
```

把以下内容复制进去（包含多个国内镜像加速器）

```json
{
  "registry-mirrors": [
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
```

按 `Ctrl + O` 保存，`Ctrl + X` 退出编辑器。

重启 Docker 服务使配置生效：

```bash
sudo systemctl daemon-reexec
sudo systemctl restart docker
```

验证配置是否生效：

```bash
docker info | grep -A 5 'Registry Mirrors'
```

输出应包含刚才配置的地址。

####  测试网络连通性

可以用 `curl` 测试网络连通性：

```bash
# 命令没响应，说明服务器无法直接访问 Docker Hub 的官方注册中心，这是导致拉不到官方镜像的根本原因
curl -I https://registry-1.docker.io/v2/

# 返回 HTTP 401 是正常的，说明：
# 服务器能访问阿里云镜像仓库的网络是通的；
# 401 是“未认证”，仓库要求认证（这属于正常安全流程），说明网络没问题。
curl -I https://registry.cn-hangzhou.aliyuncs.com/v2/
```

### 替换 gem 镜像

在容器内执行：

```bash
gem sources --remove https://rubygems.org/
gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/
gem sources -l
```

输出应该是：

```css
*** CURRENT SOURCES ***

https://mirrors.tuna.tsinghua.edu.cn/rubygems/
```

配置完镜像源后，**后续所有 `gem install` 和 `bundle install` 都会走新配置的源**，速度明显加快。

### 部署博客

本地项目目录应如下：

```css
your-blog/
├── _config.yml
├── Gemfile
├── Gemfile.lock
├── Dockerfile
├── docker-compose.yml
├── .github/
│   └── workflows/
│       └── deploy.yml       ← GitHub Actions 部署脚本
├── _posts/
├── _pages/
├── _site/                   ← 构建后自动生成
└── 其他 Jekyll 所需文件...
```

#### 手动下载镜像（可选）

##### 本地执行

第一步：预先拉取官方镜像（一次性）

```bash
docker pull jekyll/jekyll
docker pull nginx:alpine
```

第二步：保存镜像为压缩文件（建议 gzip）

```bash
docker save jekyll/jekyll | gzip > jekyll-jekyll.tar.gz
docker save nginx:alpine | gzip > nginx-alpine.tar.gz
```

第三步：将打包镜像上传到服务器

可以使用FileZilla

##### 服务器上操作

第一步：解压并导入镜像

```bash
gunzip -c jekyll-jekyll.tar.gz | docker load
gunzip -c nginx-alpine.tar.gz | docker load
```

可以用 `docker images` 确认是否导入成功：

```css
REPOSITORY       TAG        IMAGE ID       ...
jekyll/jekyll    latest     ...
nginx            alpine     ...
```

 第二步：运行或构建容器

现在可以使用这些已存在的镜像直接运行之后配置的 `docker-compose.yml` 或 `docker run` 命令，Docker 不会去拉取远程镜像。

比如：

```bash
docker-compose up -d --build
```

或者直接构建新的镜像：

```bash
docker build -t chirpy-blog .
```

#### GitHub Secrets 设置

进入 GitHub 仓库 -> Settings -> Secrets and variables -> Actions，点击 **New repository secret**，添加以下三个 Secret：

| Name       | 用途说明                  |
| ---------- | ------------------------- |
| `SSH_HOST` | 服务器 IP 或域名          |
| `SSH_USER` | 登录用户名（如 `root`）   |
| `SSH_KEY`  | 私钥内容（用于 SSH 登录） |

> SSH_KEY 就是用来远程登录服务器的私钥内容，通常是的 **~/.ssh/id_rsa** 文件。可以这样获取它：
>
> 1. **在本地电脑（Windows 下用 Git Bash、Linux 或 macOS 终端）执行：**
>
> ```bash
> cat ~/.ssh/id_rsa
> ```
>
> 2. 这个命令会输出你的私钥文本，形如：
>
> ```bash
> -----BEGIN OPENSSH PRIVATE KEY-----
> ...
> -----END OPENSSH PRIVATE KEY-----
> ```
>
> 3. 复制全部内容（包括开头和结尾的那两行），粘贴到 GitHub Secrets 的 Secret 框里。
>
> 服务器操作（远程服务器）:
>
> **创建 `~/.ssh` 目录（如果不存在）并设置权限**
>
> ```bash
> mkdir -p ~/.ssh
> chmod 700 ~/.ssh
> ```
>
> **把本地复制的公钥写入服务器的 `authorized_keys` 文件**
>  编辑或追加公钥：
>
> ```bash
> echo "ssh-rsa..." >> ~/.ssh/authorized_keys
> ```
>
> （这里用的是从本地复制的公钥内容，替换示例中的字符串）
>
> **设置 `authorized_keys` 文件权限**
>
> ```bash
> chmod 600 ~/.ssh/authorized_keys
> ```

#### nginx.conf

- nginx 运行在容器中，使用 80 端口

```nginx
server {
    listen 80;                # 监听服务器的80端口

    server_name blog.n1ce2cu.com;

    root /usr/share/nginx/html; # 静态文件根目录
    index index.html;           # 默认首页文件

    location / {
        try_files $uri $uri/ =404;  # 访问文件或目录，找不到返回404
    }

    # 静态资源缓存配置（js、css、图片等）
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;             # 缓存时间最大化，提升访问速度
        access_log off;          # 关闭访问日志，减少磁盘写入
    }
}
```

#### docker-compose.yml

- 映射服务器的9527端口到容器内部的80端口

```yml
version: "3.8"

services:
  blog:
    image: nginx:alpine # 使用轻量级的 nginx 官方镜像
    container_name: chirpy_blog # 容器名字，方便管理
    ports:
      - "9527:80" # 映射服务器的9527端口到容器内部的80端口
        # 服务器外访问9527端口，实际上是访问容器内的80端口（nginx默认端口）
    volumes:
      - ./_site:/usr/share/nginx/html:ro # 挂载本地的 _site 目录到容器的 nginx 静态资源目录，只读模式
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro # 挂载自定义 nginx 配置文件，替换默认配置，只读模式
    restart: unless-stopped # 容器异常退出自动重启，除非手动停止
```

#### GitHub Actions

chirpy 原有的 `pages-deploy.yml` 不需要改动，新建：`.github/workflows/deploy-to-server.yml`

```yaml
name: Build and Deploy Chirpy Blog

on:
  push:
    branches:
      - main # 只监听 main 分支的提交，触发此工作流

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest # 在 GitHub 提供的 Ubuntu 虚拟环境中运行

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        # 拉取仓库代码到 runner 本地

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.1
        # 安装指定版本的 Ruby 环境，Jekyll 需要 Ruby 支持

      - name: Install dependencies
        run: |
          gem install bundler
          bundle install
        # 安装 bundler 以及 Gemfile 中声明的所有依赖包（包括 Jekyll 和插件）

      - name: Build Chirpy static site
        run: JEKYLL_ENV=production bundle exec jekyll build
        # 使用 Jekyll 生成生产环境的静态站点，生成的文件在 _site 目录

      - name: Ensure deploy directory exists on server
        uses: appleboy/ssh-action@v0.1.7
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            mkdir -p /home/ubuntu/chirpy-site/_site
            chown -R $USER:$USER /home/ubuntu/chirpy-site
        # 在服务器上确保部署目录存在，并且设置目录权限为当前用户

      - name: Upload _site to server
        uses: appleboy/scp-action@master
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          source: "_site/**"
          target: "/home/ubuntu/chirpy-site/"
        # 上传本地生成的静态文件夹 _site 内所有文件到服务器对应目录

      - name: Upload docker-compose.yml
        uses: appleboy/scp-action@master
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          source: "docker-compose.yml"
          target: "/home/ubuntu/chirpy-site/"
        # 上传 docker-compose 配置文件到服务器，方便管理 Docker 容器

      - name: Upload nginx.conf
        uses: appleboy/scp-action@master
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          source: "nginx.conf"
          target: "/home/ubuntu/chirpy-site/"
        # 上传 nginx 配置文件到服务器，用于 Nginx 容器配置

      - name: Start or Restart blog container
        uses: appleboy/ssh-action@v0.1.7
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /home/ubuntu/chirpy-site
            docker compose down
            docker compose up -d
        # 进入部署目录，先关闭旧的 Docker 容器，再后台启动新的容器，使配置和静态文件生效
```

 注意：

- **博客是在 GitHub Actions 运行环境构建的**（Ubuntu 虚拟机）

- **上传和部署是通过 SCP 和 SSH 远程操作到服务器的**

- `_site/**` 是构建好的静态网页，会通过 SSH 上传到服务器
- `chirpy-deploy` 是服务器上的部署目录

#### 服务器端部署准备

1. 创建部署目录，例如 `/home/ubuntu/chirpy-deploy/`

手动登录服务器执行：

```bash
mkdir -p /home/ubuntu/chirpy-site
chown -R root:root /home/ubuntu/chirpy-site
```

2. 确保端口 9527 已打开，或配合 nginx 反向代理（可加 HTTPS）

3. GitHub Actions 每次 push 都会自动上传 `_site/` 并在此目录重新构建容器