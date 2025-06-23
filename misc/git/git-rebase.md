## git rebase

`git rebase` 的作用是：**将当前分支的提交，重新“安置”在目标分支的末尾上**，从而实现更清晰的提交历史。

它并不会简单地“移动分支指针”，而是会**逐个复制提交，生成新的 commit ID**。

### 原理图示

#### 假设当前有这样的提交历史：

```mathematica
A---B---C  (main)
         \
          D---E  (feature)
```

现在在 `feature` 分支上，执行：

```bash
git switch feature
git rebase main
```

会变成：

```mathematica
A---B---C---D'---E'  (feature)
```

- 注意：`D`、`E` 被“重演”在 `C` 后，形成新的 `D'`、`E'`，旧的提交不会显示在历史中。

### 和 `git merge` 的区别

| 操作   | 是否保留历史？   | 是否产生新提交？     | 历史是否线性？ | 适合场景               |
| ------ | ---------------- | -------------------- | -------------- | ---------------------- |
| merge  | ✅ 是             | ✅ 是（merge commit） | ❌ 否           | 团队协作，保留分支痕迹 |
| rebase | ❌ 否（改写历史） | ✅ 是（复制提交）     | ✅ 是           | 整理历史，精简 commit  |

### 实际使用场景

#### 场景 1：开发中同步主干（替代 merge）

```bash
git switch feature
git rebase main
```

- 表示把 `feature` 分支基于 `main` 的最新提交之上重放。
- 优点：避免分叉历史、保持线性。

#### 场景 2：整理多个提交（交互式 rebase）

```bash
git rebase -i HEAD~5
```

- 对最近的 **5 个提交** 执行一次 **交互式 rebase（interactive rebase）**，让你有机会 **修改历史**。

- 交互式能干嘛

  | 操作     | 说明                                |
  | -------- | ----------------------------------- |
  | `pick`   | 保持提交不变                        |
  | `reword` | 修改提交信息                        |
  | `edit`   | 修改提交内容                        |
  | `squash` | 合并当前提交到上一个提交            |
  | `fixup`  | 类似 squash，但不保留当前提交的信息 |
  | `drop`   | 删除这个提交                        |

假设最近 5 个提交是：

```bash
git log --oneline
```

输出：

```bash
a5c9fea Fix test bug
3f1e01c Add login button
c21a7b4 Fix typo
1122abc Add login logic
d334f9a Initial commit
```

执行：

```bash
git rebase -i HEAD~5
```

将打开编辑器，显示如下：

```bash
pick d334f9a Initial commit
pick 1122abc Add login logic
pick c21a7b4 Fix typo
pick 3f1e01c Add login button
pick a5c9fea Fix test bug
```

可以进行如下修改：

```bash
pick d334f9a Initial commit
pick 1122abc Add login logic
squash c21a7b4 Fix typo
squash 3f1e01c Add login button
squash a5c9fea Fix test bug
```

这表示：把后面三个提交合并进 `Add login logic`，变成一个完整的功能提交。

按下 Esc 键，输入 :wq，按下 Enter 键 ，退出 vim 编辑器。如果选择了 `squash`，接下来 Git 会弹出第二个 Vim 界面，让你编辑**合并后的 commit message**此，编辑完 message → 再次执行 `:wq` 保存退出。

#### 场景 3：PR 前清理无意义提交

##### 背景问题

在开发过程中，可能会频繁提交一些临时或小改动，比如：

- 修复一个小 bug （`fix bug`）
- 修改代码格式（`改下格式`）
- 调整注释或者小改动

这些提交虽然能帮助记录每一步，但放到远程仓库或者合并到主分支时，会让提交历史变得杂乱无章，影响代码维护和回溯。

##### 解决方案：使用交互式 rebase (`git rebase -i origin/main`)

```bash
git fetch origin          # 先同步远程最新代码
git rebase -i origin/main
```

意思是：

- 以远程主分支 `origin/main` 为基准
- 让 Git 显示你当前分支相对于 `origin/main` 的所有提交
- 你可以对这些提交进行编辑，比如合并（squash）、修改提交信息、删除无用提交等

##### 具体操作示例

假设交互式 rebase 打开后，显示如下提交列表：

```bash
pick abcdef1 添加登录界面按钮
pick bcdefa2 fix bug: 登录失败错误提示
pick cdefab3 改下格式
pick defabc4 修复 token 失效问题
pick efabcd5 调整注释
```

你可以将无意义的提交合并，比如：

```bash
pick abcdef1 添加登录界面按钮
squash bcdefa2 fix bug: 登录失败错误提示
squash cdefab3 改下格式
pick defabc4 修复 token 失效问题
drop efabcd5 调整注释
```

- 把三个提交合并成一个，更加清晰
- 删除完全无用的提交 `drop`

##### 编辑合并后的提交信息

Git 会让你编辑合并后的提交说明，你可以写成：

```css
feat: 添加登录按钮，修复登录失败提示，调整格式
fix: 修复 token 失效问题
```

#### 对比

| 项目             | 场景 1：同步主干  | 场景 2：整理最近几次提交 | 场景 3：PR 前提交优化              |
| ---------------- | ----------------- | ------------------------ | ---------------------------------- |
| 命令             | `git rebase main` | `git rebase -i HEAD~N`   | `git rebase -i origin/main`        |
| 基准             | 本地主分支        | 当前分支最近 N 次提交    | 远程主分支                         |
| 目标             | 同步主干最新代码  | 本地开发时整理 commit    | 推 PR 前优化整体提交结构           |
| 是否重排全部提交 | ❌ 只重排差异部分  | ❌ 只影响最近 N 次提交    | ✅ 整理整个相对 `main` 的提交序列   |
| 是否依赖远程分支 | 否                | 否                       | 是                                 |
| 操作复杂度       | 低                | 中                       | 中偏高（更完整地改写整个提交历史） |

### 高级用法

#### 继续 rebase（解决冲突后）

```bash
git rebase --continue
```

#### 放弃 rebase 操作

```bash
git rebase --abort
```

#### rebase 某一特定分支

```bash
git rebase origin/main
```

此时相当于把当前分支的提交重放到 `origin/main` 后面。

### 注意事项

| 警告事项                      | 说明                                            |
| ----------------------------- | ----------------------------------------------- |
| **不要对已推送的分支 rebase** | 会导致别人的仓库无法正常合并或拉取              |
| **会丢失原始提交 ID**         | 如果你需要审计历史，这不适合用                  |
| **冲突要手动解决**            | rebase 会一个一个 replay 提交，可能触发多个冲突 |

### FAQ

#### rebase 之后为什么 commit ID 变了？

因为每次 `rebase` 相当于用新的 parent 重新“写一遍”提交，每个新提交都有新的哈希。

#### 能不能把多个功能压缩成一个提交？

可以，使用 `rebase -i` 进行 `squash`，或者 `git reset` 回退到上个提交，重新提交。

#### rebase 和 reset 有什么区别？

- `rebase` 是对提交历史的“重演”，保留内容但生成新提交。
- `reset` 是**直接移动 HEAD 或分支指针**，影响范围更大且危险。