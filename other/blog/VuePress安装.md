---
title: VuePress安装
date: 2024-07-20 08:03:35 +0800
categories: [other, blog]
tags: [Blog, VuePress]
description: 
---
## linux 下预构建二进制文件安装 Nodejs

 [Nodejs预购建二级制文件下载地址](https://nodejs.org/en/download/prebuilt-binaries)

- 安装 Nodejs 和 npm

```sh
# 解压
tar xvf node-v20.15.1-linux-x64.tar.xz
# 移动解压出的文件夹到 /usr/local下，并且重命名为nodejs
mv ./node-v20.15.1-linux-x64 /usr/local/nodejs
# 添加软连接，之后就能直接在命令行中使用nodejs
ln -s /usr/local/nodejs/bin/* /usr/bin/
```

- 关于软件安装位置：
  - `/opt 目录`：opt 是 optional(可选) 的缩写，这是给主机额外安装软件所摆放的目录，是用户级的程序目录，默认是空的。这里常用于放置额外的大型软件，比如你安装一个 ORACLE 数据库就可以放到这个目录下。
  - `/usr 目录`：usr 是 unix shared resources(共享资源) 的缩写，这是一个非常重要的系统级目录，系统的很多应用程序和文件都放在这个目录下。其中 /usr/src 是系统的源码存放目录。此目录一般由软件包管理器(yum、apt)来管理。
  - `/usr/local 目录`：/usr/local 是 /usr 下的一个用户级的程序目录，用户自己安装的软件一般选择安装到这个目录下。其中 /usr/local/src 是用户级的源码存放目录。此目录一般由用户自己管理。

- 使用 npm 安装 pnpm

```sh
# 安装
npm install -g pnpm
# 查看全局模式下的安装位置
npm root -g
# 添加软连接
ln -s /usr/local/nodejs/lib/node_modules/pnpm/bin/pnpm /usr/bin/pnpm
```

## 创建 VuePress

- 创建并进入一个新目录

```sh
mkdir vuepress-starter
cd vuepress-starter
```

- 初始化项目

```sh
git init
pnpm init
```

- 安装 VuePress

```sh
# 安装 vuepress 和 vue
pnpm add -D vuepress@next vue
# 安装打包工具和主题
pnpm add -D @vuepress/bundler-vite@next @vuepress/theme-default@next
```

如果报错 `ERR_PNPM_META_FETCH_FAIL`、`WARN  GET https:...`、`reason: connect ECONNREFUSED`

更换镜像为淘宝的：

```bash
npm config set registry https://registry.npmmirror.com
# 清理缓存
npm cache clean --force
```

- 创建 `docs` 目录和 `docs/.vuepress` 目录

```sh
mkdir docs
mkdir docs/.vuepress
```

- 创建 VuePress 配置文件 `docs/.vuepress/config.js`

```sh
import { viteBundler } from '@vuepress/bundler-vite'
import { defaultTheme } from '@vuepress/theme-default'
import { defineUserConfig } from 'vuepress'

export default defineUserConfig({
  bundler: viteBundler(),
  theme: defaultTheme(),
})
```

- 创建你的第一篇文档

```sh
echo '# Hello VuePress' > docs/README.md
```

- 在 docs 目录下添加 gitignore 文件

```sh
# VuePress 默认临时文件目录
.vuepress/.temp
# VuePress 默认缓存目录
.vuepress/.cache
# VuePress 默认构建生成的静态文件目录
.vuepress/dist
```

## 使用 VuePress

### [启动开发服务器](https://vuepress.vuejs.org/zh/guide/getting-started.html#启动开发服务器)

你可以在 `package.json` 中添加一些 [scripts](https://classic.yarnpkg.com/zh-Hans/docs/package-json#toc-scripts) ：

```
{
  "scripts": {
    "docs:dev": "vuepress dev docs",
    "docs:build": "vuepress build docs"
  }
}
```

运行 `docs:dev` 脚本可以启动开发服务器:

```
pnpm docs:dev
```

VuePress 会在 http://localhost:8080 启动一个热重载的开发服务器。当修改你的 Markdown 文件时，浏览器中的内容也会自动更新。

