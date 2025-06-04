---
title: Chirpy+Github
date: 2024-09-23 04:15:25 +0800
categories: [other, blog]
tags: [Blog, Chripy]
description: 
---
## 相关网址

------

- [Chirpy 示例](https://chirpy.cotes.page/)：网页上有官方教程，我写的肯定不全

- [Chirpy 示例仓库](https://github.com/cotes2020/jekyll-theme-chirpy)：这个就是包含官方教程的那个示例的仓库

- [Chirpy 模板仓库](https://github.com/cotes2020/chirpy-starter)：直接 fork 这个仓库，快速搭建，没有多余的东西

- [Real Favicon Generator](https://realfavicongenerator.net/)：生成图片替换原来的蚂蚁图片

- [fontawesome](https://fontawesome.com/)：扩展侧边栏时，图标可以从这里找

- [阿里图标库](https://www.iconfont.cn/)：白嫖图标

## 先本地跑起来再说

------

### 创建站点仓库

1. 登录 GitHub 并导航到 [**Chirpy 模板仓库**](https://github.com/cotes2020/chirpy-starter)。
2. 单击 Use this template 按钮然后选择 Create a new repository。
3. 为新存储库命名`<username>.github.io`，`username`用小写的 GitHub 用户名替换。（仓库必须公开）

### 设置环境（windows）

1. 安装 Docker：
   - 在 Windows 上，安装 [Docker Desktop](https://www.docker.com/products/docker-desktop/)。
2. 安装 [VS Code](https://code.visualstudio.com/) 和 [Dev Containers 扩展](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)。
3. 克隆刚才 fork 到自己 github 账号里的仓库：
   - 对于 Docker Desktop：启动 VS Code 并[在容器卷中克隆仓库](https://code.visualstudio.com/docs/devcontainers/containers#_quick-start-open-a-git-repository-or-github-pr-in-an-isolated-container-volume)。
4. 等待 Dev Containers 设置完成。

### 启动 Jekyll 服务器

在 **VS Code** Terminal 中运行该命令：

```shell
$ bundle exec jekyll s
```

几秒钟后，本地服务器将可以通过 [http://127.0.0.1:4000](http://127.0.0.1:4000/) 访问。

## 在 Github 上再跑起来

------

### 配置 Pages 服务

- 到站点仓库的 Settings -> Pages —> Build and deployment -> Source：下拉菜单里选中 `Github Actions`

- 之后就可以在仓库的 Actions 里手动构建，构建好，别人就能通过网址 https://\<username>.github.io 访问你的博客。也可以在本地的 vscode 改好文件后 push 到远程仓库（站点仓库），github 就会==自动构建==，因为项目里的 `/.github/workflows/pages-deploy.yml` 文件已经设置了这个操作。

## 跑起来再改

------

### 自定义网站图标

#### 生成图标

准备一张尺寸为 512x512 或更大的方形图像（PNG、JPG 或 SVG），然后转到在线工具 [**Real Favicon Generator**](https://realfavicongenerator.net/) 并单击按钮 Select your Favicon image 上传图像文件。

接下来网页会展示所有使用场景，可以保留默认选项，滚动到页面底部，点击按钮 Generate your Favicons and HTML code 生成图标。

#### 下载和替换

下载生成的压缩包，解压并从解压的文件中删除以下两个：

- `browserconfig.xml`
- `site.webmanifest`

然后复制剩余的图片文件（`.PNG`和`.ICO`）覆盖 `assets/img/favicons/` 目录中的原始文件。如果没有此目录，自己创建一个。

下次构建网站时，该网站图标将被替换为自定义版本。

### 修改头像和个人信息

#### _data 目录

- `contact.yml`：设置首页左下角那几个用于联系作者的小图标
- `share.yml`：设置每篇博客结尾的分享图标

#### _site 目录

- 好像是构建的时候生成出来的，我猜的，我没做过网页

#### _tabs 目录

- 对应网页左侧四个侧边栏，可以在文件中修改侧边栏的排序和图标
- 之后也可以在这个目录里自己加个侧边栏选项，图标可以从 [fontawesome](https://fontawesome.com/) 里白嫖

#### _github 目录

- `pages-deploy.yml`：控制项目构建和部署的，学一下 [Github Action](https://docs.github.com/zh/actions) 可以知道里面大概在干啥

- 一般不用修改

#### assets 目录

- `/assets/img/favicons`：网站图标
- 可以在此目录里放其他东西，比如我把自己头像放到新建的 `/assets/img/favicons`，把博客相关的文件放到 `/assets/media/` 下

#### _config.yml 文件

`_config.yml`中可以修改许多东西：

- `lang: zh-CN`：网页显示的语言
- `timezone: Asia/Shanghai`：时区
- `title: Sprinining`：头像下的那个昵称
- `tagline: 面向谷歌，CV编程`：昵称下的简介
- `url: "https://sprinining.github.io"`：网页的地址，设置成自己仓库的
- 网页里许多小图标的超链接也都在这个文件里改
- `pageviews:`：网页浏览量，暂时没弄
- `avatar: /assets/img/avators/dog.jpg`：头像
- `toc: true`：控制博客右侧的目录显示
- `comments:`：评论系统，暂时没弄

#### _posts 目录

- 放到下面说

### 上传博文

- 详细内容，看[官方文档](https://chirpy.cotes.page/posts/write-a-new-post/)，我省略了很多

#### _posts 目录

- 可以新建多级子目录，但这个目录和网页侧边栏里的类别那一项点开后所显式的目录没关系
- 每篇博文的 md 文档就放在这个目录下，可以放在自己新建的子目录中
- 博文里引用到的图片放在这个目录下，构建后网页上显示不出来图片。图片要放到 assets 目录下

#### 博文格式要求

##### Front Matter

- md 文档里必须用如下内容开头（直接在原来的 md 文件开头插入），==否则网页不会显示这个博文==。这个部分叫做 `Front Matter`。

```yaml
---
title: 标题
date: YYYY-MM-DD HH:MM:SS +/-TTTT # YYYY-MM-DD HH:MM:SS +0800
categories: [一级目录名, 二级目录名] # 可以加三级目录名，但分类那个页面只会显示到二级
tags: [标签名称]     # TAG names should always be lowercase，但我用标签大写也能正常显示
---
```

- 里面也可以加一些其他的选项，比如加一行 `description: 博文简要描述（会显示在首页每篇文章的标题下）` 其他[参考文档说明](https://jekyllrb.com/docs/front-matter/)。

##### 文件名要求

- 文件名称必须以日期开头，严格按照 `YYYY-MM-DD-原始文件名.EXTENSION` 的格式，比如 `2024-09-07-并查集.md`，扩展名也可以是 markdown。==否则网页不会显示这个博文==。也可以使用插件 [`Jekyll-Compose`](https://github.com/jekyll/jekyll-compose) 来实现这一点，我暂时没弄。

##### 文件内容要求

- ==不能出现连续的两个左大括号== `{ {`，否则构建的时候会报错：`Liquid Exception: Liquid syntax error (line 123): Variable '{ {0,1}' was not properly terminated with regexp: /\}\}/ in xxx.md `，大括号中间加个空格就行了。

#### 用脚本修改原始的 md 文件

- 用我写的 [java 脚本](https://sprinining.github.io/posts/md%E8%BD%AC%E6%8D%A2%E6%88%90_post%E4%B8%8B%E7%9B%B4%E6%8E%A5%E4%BD%BF%E7%94%A8%E7%9A%84%E6%96%87%E4%BB%B6/) 批量修改文件名，并且插入 Front Matter。用的时候需要修改路径啥的，也可以把时间改成文件创建时间或者上次打开时间，默认是上次修改时间。
- 批量修改文件名还可以使用软件 [Bulk Rename Utility](https://www.bulkrenameutility.co.uk/Download.php)。里面可以设置成给文件名添加指定格式的日期前缀。

#### 博文插入图片

- 原始 md 文件里已经有了图片，图片的链接要修改。

- `/assets/media/pictures/algorithm/` 是自己放图片的路径

- 示例：`![image-20220506135704565](/assets/media/pictures/algorithm/排序.assets/image-20220506135704565.png)`

- 路径==一定要用反斜杠== `/`

- 可以在 Front Matter 中加入一行来设置这篇文章图片路径的父路径：

  `media_subpath: /assets/media/pictures/algorithm/`，相当于在原始路径前加上了自己设置的路径。

  `![image](排序.assets/image-25.png)` 变成 `![image](/assets/media/pictures/algorithm/排序.assets/image-25.png)`，这样配置后，构建后网页上能看见图片。但在 github 站点仓库里，直接打开这个 md 文档的话，是显示不出来图片的。

- 不在 Front Matter 里加图片父路径，直接在每个图片的路径前手动加上 `/assets/media/pictures/algorithm/`，这样 github 站点仓库里，直接打开这个 md 文档，图片就能正常显示了。

## 增加留言面板

- 安装 utterances ：点击 [github app - utterances](https://github.com/apps/utterances) 后，选择 Install，在后面的页面里选择自己的仓库。
- 设置：选好仓库后会调整到 [utterances - 首頁](https://utteranc.es/)，在 configuration 区域里设置。
  - 在 Respository 中==填好自己仓库的地址==，如 `Sprinining/sprinining.github.io`
  - 在 Blog Post ↔️ Issue Mapping 中选择一项映射方式，我选的第二个
  - 在 Issue Label 中填写标签（可选），我填的 Comment
  - 在 Theme 选个主题
- 复制代码：复制 Enable Utterances 中根据上面几个选项自动生成的代码，代码里有一项仓库名称要改成自己的。这个代码我没用到，自己定义布局文件才会用到。
- 修改项目里的 `_config.yml` 文件：

```yml
comments:
  # Global switch for the post-comment system. Keeping it empty means disabled.
  provider: utterances # [disqus | utterances | giscus]
  # The provider options are as follows:
  disqus:
    shortname: # fill with the Disqus shortname. › https://help.disqus.com/en/articles/1717111-what-s-a-shortname
  # utterances settings › https://utteranc.es/
  utterances:
    repo: Sprinining/sprinining.github.io # <gh-username>/<repo>
    issue_term: url # < url | pathname | title | ...> 这个填的内容在之前生成的代码里也有
  # Giscus options › https://giscus.app
  giscus:
    repo: # <gh-username>/<repo>
    repo_id:
    category:
    category_id:
    mapping: # optional, default to 'pathname'
    strict: # optional, default to '0'
    input_position: # optional, default to 'bottom'
    lang: # optional, default to the value of `site.lang`
    reactions_enabled: # optional, default to the value of `1`
```

- 重新部署后就能生效了，留言在 github 的 Issues 里也能看见
