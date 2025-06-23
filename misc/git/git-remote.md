## git remote

`git remote` 是 Git 中用于**管理远程仓库连接（remote repository）\**的命令。它本身不涉及具体的「上传」或「拉取」，而是\**负责告诉本地仓库：有哪些远程仓库、它们叫什么名字、地址在哪儿**。

`git remote` 是用来 **管理远程仓库的名字与地址（URL）映射关系** 的命令。

### 常见用途速查表

| 任务                 | 命令                                  |
| -------------------- | ------------------------------------- |
| 查看远程仓库列表     | `git remote`                          |
| 查看远程仓库详细地址 | `git remote -v`                       |
| 添加远程仓库         | `git remote add <name> <url>`         |
| 删除远程仓库         | `git remote remove <name>`            |
| 修改远程地址         | `git remote set-url <name> <new-url>` |
| 重命名远程仓库       | `git remote rename <old> <new>`       |

### 常用命令详解

#### 查看当前有哪些远程仓库

```bash
git remote
```

输出：

```css
origin
```

说明有一个叫 `origin` 的远程仓库。

#### 查看远程仓库详细地址（含读/写 URL）

```bash
git remote -v
```

输出：

```css
origin  https://github.com/user/myrepo.git (fetch)
origin  https://github.com/user/myrepo.git (push)
```

- `fetch` 是用于 `git pull` 等操作的地址；

- `push` 是用于 `git push` 的地址。

#### 添加远程仓库

```bash
git remote add origin https://github.com/user/myrepo.git
```

这会把 `origin` 这个名字绑定到远程仓库 URL 上。

注意：

- `origin` 是个默认名称，不强制；
- 可以添加多个远程，比如：

```bash
git remote add backup git@backup.example.com:repo.git
```

#### 删除远程仓库

```bash
git remote remove origin
```

或：

```bash
git remote rm origin
```

这只是删除「地址记录」，不会影响远程仓库本身。

#### 修改远程仓库地址

```bash
git remote set-url origin git@github.com:xxx/yyy.git
```

适用于：

- 仓库迁移了；
- HTTP 改成 SSH；
- 换成备用源。

#### 重命名远程仓库

```bash
git remote rename origin github
```

之后再 push 时写的是：

```bash
git push github main
```

### `git remote` 与实际同步的关系

`git remote` 只是「记录名字和地址」，**并不会执行任何上传/下载操作**，例如：

| 操作                   | 作用                      |
| ---------------------- | ------------------------- |
| `git fetch origin`     | 从 origin 下载提交        |
| `git push origin main` | 将本地 main 推送到 origin |
| `git pull origin main` | 从 origin 拉 main 并合并  |

这些命令才会真正使用通过 `git remote` 添加的地址。

### 多远程仓库使用示例

可以同时添加多个远程：

```bash
git remote add origin  https://github.com/my/main.git
git remote add backup  https://gitlab.com/my/backup.git
```

分别执行：

```bash
git push origin main
git push backup main
```

### 深层理解：`remote`、`refspec` 与本地分支

`git remote` 还配合 `.git/config` 中的配置一起使用。可以查看：

```bash
cat .git/config
```

示例内容：

```bash
[remote "origin"]
  url = https://github.com/user/repo.git
  fetch = +refs/heads/*:refs/remotes/origin/*
```

这表示：

- 把远程所有分支 `refs/heads/*` 拉取到本地的 `refs/remotes/origin/*`；
- 本地你可以通过 `origin/main` 等方式访问远程分支。

#### 什么是 `refs`

- **`refs` 全称是 references，翻译为“引用”**。
- Git 中所有的分支、标签、远程跟踪分支，都是通过 `refs` 来管理和指向具体的提交（commit）对象的。
- 简单来说，`refs` 是 Git 用来给某个提交打“标签”的机制，是 Git 中**指针的抽象**。

#### `refs` 的常见类型和作用目录结构

Git 中的 `refs` 存储在 `.git/refs/` 目录下，常见的主要类型有：

| 类型            | 路径示例                        | 说明                               |
| --------------- | ------------------------------- | ---------------------------------- |
| `refs/heads/`   | `.git/refs/heads/main`          | 本地分支指针，指向分支最新提交     |
| `refs/remotes/` | `.git/refs/remotes/origin/main` | 远程分支指针，指向远程仓库对应分支 |
| `refs/tags/`    | `.git/refs/tags/v1.0`           | 标签，指向特定提交（一般是发布点） |

```css
fetch = +refs/heads/*:refs/remotes/origin/*
```

- 左边的 `refs/heads/*` 是 **远程仓库（origin）**中的所有分支。
- 右边的 `refs/remotes/origin/*` 是 **本地仓库**存放远程分支快照（remote-tracking branches）的路径。

换句话说：

- 远程仓库里的分支在它的 `refs/heads/` 下。
- `git fetch` 时，把远程的 `refs/heads/*` 拉下来，映射成本地的 `refs/remotes/origin/*`。

### 小技巧

设置默认推送分支：

```bash
git push -u origin main
```

这会把当前分支和 `origin/main` 建立**追踪关系**，以后你只需：

```bash
git push
```

就能自动推到 `origin/main`。

### 总结

| 功能         | 命令                              |
| ------------ | --------------------------------- |
| 查看远程仓库 | `git remote -v`                   |
| 添加远程仓库 | `git remote add <name> <url>`     |
| 删除远程仓库 | `git remote remove <name>`        |
| 修改地址     | `git remote set-url <name> <url>` |
| 重命名       | `git remote rename <old> <new>`   |