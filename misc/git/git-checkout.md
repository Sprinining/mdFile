## git checkout

`git checkout` 可以用来：

- **切换到某个分支或提交**；

- **还原工作区/暂存区的文件内容到某个版本**。

### 使用场景与语法大全

#### 切换分支

```bash
git checkout branch-name
```

- 作用：将当前工作目录切换到指定分支。

- 会更新 `.git/HEAD` 为该分支名。

- 会刷新工作区为该分支的文件快照。

创建新分支并切换过去（常见用法）

```bash
git checkout -b new-branch
```

等价于：

```bash
git branch new-branch
git checkout new-branch
```

#### 检出特定 commit（分离 HEAD）

```bash
git checkout <commit-hash>
```

- 会进入“Detached HEAD”状态。

- 常用于调试旧版本、测试回滚，但不建议在此状态下开发。

#### 还原文件到某个版本（恢复误删/误改）

```bash
git checkout <branch/commit> -- <file>
```

- 用于将某个文件还原到指定分支或提交下的状态。

- 如果省略 `<branch>`，默认是 `HEAD`。

示例：

```bash
git checkout HEAD -- src/main.cpp     # 把 main.cpp 恢复为当前分支最后一次提交的版本
git checkout dev -- config.yml        # 用 dev 分支的 config.yml 覆盖当前工作区
```

### `git checkout` 有多重语义，需结合参数判断行为

| 用法                              | 意义                            |
| --------------------------------- | ------------------------------- |
| `git checkout dev`                | 切换到分支 `dev`                |
| `git checkout -b hotfix`          | 创建并切换到 `hotfix` 分支      |
| `git checkout abc123`             | 切换到某个提交（Detached HEAD） |
| `git checkout -- file.txt`        | 恢复文件到最近提交版本          |
| `git checkout branch -- file.txt` | 用某个分支的版本覆盖当前文件    |

### HEAD 和 `git checkout` 的关系图解

正常切换分支：

```css
HEAD → main         # 当前在 main 分支
git checkout dev
HEAD → dev          # 切换到 dev 分支
```

分离 HEAD：

```css
git checkout 1a2b3c4
HEAD → 1a2b3c4      # 不再指向任何分支名（Detached HEAD）
```

还原文件：

```css
git checkout main -- app.cpp
# 把 main 分支里的 app.cpp 拿过来覆盖当前分支的 app.cpp（只影响工作区）
```

### 低层机制

`checkout` 会：

- 更新 `HEAD`（分支切换时）；
- 修改工作区文件（替换内容）；
- 有时还会修改暂存区内容。

所以，使用 `git checkout` 会影响 **HEAD、index（暂存区）、working directory（工作区）**。

### 注意事项

| 注意点                       | 说明                                                     |
| ---------------------------- | -------------------------------------------------------- |
| 会覆盖工作区改动             | 切换分支时若有未提交的改动，Git 会阻止 checkout 以防丢失 |
| 分离 HEAD 下提交不会自动保存 | 需要手动 `git switch -c 新分支` 否则提交历史易丢失       |
| 想恢复历史文件，建议加 `--`  | 否则 Git 会把你当成切分支了，比如 `git checkout config`  |

### Git 新版本推荐使用 `git switch` 和 `git restore`

从 Git 2.23 起，为了**简化语义、避免混淆**，Git 引入了：

| 新命令        | 原功能             |
| ------------- | ------------------ |
| `git switch`  | 专用于切换分支     |
| `git restore` | 专用于还原文件内容 |

示例对比：

| 操作                   | `checkout` 命令                | 新推荐命令                    |
| ---------------------- | ------------------------------ | ----------------------------- |
| 切换到分支 `dev`       | `git checkout dev`             | `git switch dev`              |
| 创建并切换到 `feature` | `git checkout -b feature`      | `git switch -c feature`       |
| 恢复文件 `file.txt`    | `git checkout -- file.txt`     | `git restore file.txt`        |
| 恢复指定分支的文件     | `git checkout dev -- file.txt` | `git restore -s dev file.txt` |

### 总结速查表

| 操作                 | 命令                           |
| -------------------- | ------------------------------ |
| 查看所有分支         | `git branch`                   |
| 切换分支             | `git checkout dev`             |
| 创建并切换分支       | `git checkout -b feature`      |
| 检出某个提交         | `git checkout abc1234`         |
| 恢复文件到最新提交   | `git checkout -- file.cpp`     |
| 用某分支版本还原文件 | `git checkout dev -- file.cpp` |