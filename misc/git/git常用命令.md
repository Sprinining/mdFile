## git 常用命令

### 基础配置

| 命令                                                      | 说明                                         |
| --------------------------------------------------------- | -------------------------------------------- |
| `git config --global user.name "Your Name"`               | 设置用户名                                   |
| `git config --global user.email "your.email@example.com"` | 设置邮箱                                     |
| `git config --global core.editor vim`                     | 设置默认编辑器                               |
| `git config --list`                                       | 查看所有配置项                               |
| `git config --global alias.co checkout`                   | 设置别名（例：`git co` 代替 `git checkout`） |

### 仓库操作

| 命令              | 说明           |
| ----------------- | -------------- |
| `git init`        | 初始化本地仓库 |
| `git clone <url>` | 克隆远程仓库   |

### 提交相关

| 命令                       | 说明                                         |
| -------------------------- | -------------------------------------------- |
| `git add <file>`           | 添加文件到暂存区                             |
| `git add .`                | 添加所有改动到暂存区                         |
| `git commit -m "message"`  | 提交到本地仓库                               |
| `git commit -am "message"` | 添加并提交（跳过 `add`，适用于修改过的文件） |
| `git status`               | 查看当前状态                                 |
| `git diff`                 | 查看未暂存的改动                             |
| `git diff --cached`        | 查看已暂存的改动                             |

### 分支管理

| 命令                   | 说明                   |
| ---------------------- | ---------------------- |
| `git branch`           | 查看本地分支           |
| `git branch <name>`    | 创建新分支             |
| `git checkout <name>`  | 切换分支               |
| `git switch <name>`    | 切换分支（推荐用法）   |
| `git switch -c <name>` | 创建并切换新分支       |
| `git merge <branch>`   | 合并指定分支到当前分支 |
| `git branch -d <name>` | 删除本地分支           |
| `git stash`            | 暂存当前修改           |
| `git stash pop`        | 恢复暂存修改           |

### 远程操作

| 命令                          | 说明                       |
| ----------------------------- | -------------------------- |
| `git remote -v`               | 查看远程仓库地址           |
| `git remote add origin <url>` | 添加远程仓库地址           |
| `git push -u origin main`     | 推送本地主分支并与远程关联 |
| `git push`                    | 推送当前分支到远程仓库     |
| `git pull`                    | 拉取并合并远程分支         |
| `git fetch`                   | 拉取远程仓库（不合并）     |
| `git clone <url>`             | 克隆远程仓库               |

### 历史回溯

| 命令                | 说明                                           |
| ------------------- | ---------------------------------------------- |
| `git log`           | 查看提交历史                                   |
| `git log --oneline` | 历史简略模式                                   |
| `git reflog`        | 查看所有 HEAD 的移动记录（包括 reset、rebase） |
| `git show <commit>` | 查看某次提交的内容                             |

### 回退/重置

| 命令                     | 说明                                   |
| ------------------------ | -------------------------------------- |
| `git reset HEAD <file>`  | 取消暂存某文件                         |
| `git checkout -- <file>` | 丢弃工作区更改                         |
| `git reset --soft HEAD^` | 回退 commit 保留改动                   |
| `git reset --hard HEAD^` | 强制回退到上一个 commit                |
| `git revert <commit>`    | 生成一个新的 commit 用于“撤销”某次提交 |

### 标签（Tag）

| 命令                        | 说明         |
| --------------------------- | ------------ |
| `git tag`                   | 查看所有标签 |
| `git tag <tagname>`         | 创建标签     |
| `git tag -d <tagname>`      | 删除本地标签 |
| `git push origin <tagname>` | 推送标签     |
| `git push origin --tags`    | 推送所有标签 |

### 进阶操作

| 命令                       | 说明                                   |
| -------------------------- | -------------------------------------- |
| `git cherry-pick <commit>` | 应用某次提交到当前分支                 |
| `git rebase <branch>`      | 把当前分支变基到指定分支上             |
| `git rebase -i HEAD~n`     | 交互式 rebase（用于整理提交历史）      |
| `git clean -fd`            | 清理未被追踪的文件和目录（危险操作！） |
| `git stash list`           | 查看 stash 列表                        |
| `git stash drop`           | 删除最近一次 stash                     |

### 建议工作流（简略版）

```bash
# 初始化项目
git init

# 克隆项目
git clone https://github.com/xxx/xxx.git

# 日常开发流程（基于 dev 分支）
git switch dev
git switch -c feature/xxx      # 创建功能分支
git add .
git commit -m "feat: 实现 xxx 功能"
git push origin feature/xxx

# 创建 PR，合并到 dev
# 检查测试后，合并 dev 到 main，发布版本
```