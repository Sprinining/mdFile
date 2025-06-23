## git switch

`git switch` 是 Git 在 **2.23 版本引入的新命令**，目的是简化原本由 `git checkout` 承担的“分支切换”功能，使语义更清晰、更不容易误用。`git switch` 用于在不同分支之间切换，或创建并切换新分支。 相比 `git checkout`，它语义单一，只处理 **分支切换相关功能**，**不能用于还原文件**。

### 基本语法

#### 切换到已有分支

```bash
git switch <branch-name>
```

等价于：

```bash
git checkout <branch-name>
```

#### 创建并切换到新分支（等价于 `checkout -b`）

```bash
git switch -c <new-branch>
```

例如：

```bash
git switch -c feature/login
```

会新建 `feature/login` 分支，并切换过去。

### 更多实用选项

| 命令                                               | 说明                                     |
| -------------------------------------------------- | ---------------------------------------- |
| `git switch -c <新分支> --track origin/<远程分支>` | 创建本地分支并追踪远程分支               |
| `git switch -`                                     | 快速切换回上一个分支（和 checkout 一样） |
| `git switch --detach <commit>`                     | 进入 Detached HEAD 模式                  |
| `git switch --force <branch>`                      | 强制切换分支，即使有未提交改动           |

### 与 `checkout` 对比总结

| 功能                                | `git checkout` | `git switch`    |
| ----------------------------------- | -------------- | --------------- |
| 切换分支                            | ✅              | ✅               |
| 创建分支                            | ✅（`-b`）      | ✅（`-c`）       |
| 检出旧 commit（进入 Detached HEAD） | ✅              | ✅（`--detach`） |
| 还原文件内容                        | ✅              | ❌               |
| 恢复文件到某提交版本                | ✅              | ❌               |

### 底层机制（简化版）

`git switch` 本质还是操作 `.git/HEAD` 文件，把它指向某个 `refs/heads/<branch>`，并把当前工作区与暂存区的文件同步为该分支的最新快照。

### 常见注意事项

| 问题                                    | 说明                                            |
| --------------------------------------- | ----------------------------------------------- |
| `git switch` 命令不存在？               | 你的 Git 版本 < 2.23，建议升级                  |
| 有未提交改动不能切换？                  | Git 会提示你 commit 或 stash 改动，否则可能冲突 |
| `git switch --detach <commit>` 有何用？ | 临时查看某提交，不影响任何分支，进入“分离 HEAD” |

### 总结速查表

| 操作                       | 命令                                   |
| -------------------------- | -------------------------------------- |
| 切换分支                   | `git switch dev`                       |
| 创建并切换分支             | `git switch -c new-feature`            |
| 切换到上一个分支           | `git switch -`                         |
| 创建本地分支并跟踪远程分支 | `git switch -c dev --track origin/dev` |
| 进入分离 HEAD 状态         | `git switch --detach <commit>`         |