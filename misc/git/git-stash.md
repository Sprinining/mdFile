## git stash

`git stash` 是 Git 中非常实用但常被忽视的功能之一，常用于**临时保存当前工作区和暂存区的改动**，让你可以在不提交的情况下切换分支、处理其他任务，之后再恢复。

`git stash` 就像是一个“临时抽屉”，可以把未完成的修改（包括未提交的工作区和暂存区改动）先塞进去，等处理完其他事情，再从抽屉里拿出来继续干。

### 常见使用场景

假设：

- 正在 `feature` 分支写代码，但临时需要切到 `main` 修个紧急 bug；
- 可是当前代码写了一半、无法提交；
- 又不能直接切分支，因为 Git 会阻止切换（存在未提交改动）。

此时可以：

```bash
git stash            # 把当前改动暂存起来
git checkout main    # 安全切换分支
# 修复bug、提交
git checkout feature
git stash pop        # 恢复刚才的未完成改动
```

### 基本命令

#### 存储当前改动

```bash
git stash
```

等价于：

```bash
git stash push
```

默认把 **工作区 + 暂存区** 的改动都存起来，并还原为干净状态（与 HEAD 相同）。

#### 恢复最近一次 `stash`

```bash
git stash pop
```

- 恢复改动，并把这个 stash 从列表中移除；

- 如果想恢复但**保留**这个 stash，可用：

```bash
git stash apply
```

#### 查看 stash 列表

```bash
git stash list
```

输出示例：

```css
stash@{0}: WIP on feature/login: a1b2c3d add login form
stash@{1}: WIP on main: d4e5f6g fix config bug
```

#### 查看具体某个 stash 的内容

```bash
git stash show stash@{1}
```

或更详细：

```bash
git stash show -p stash@{1}
```

#### 删除 stash

删除某一个：

```bash
git stash drop stash@{0}
```

删除所有 stash：

```bash
git stash clear
```

### 进阶用法

#### 保存时写备注

```bash
git stash push -m "临时保存登录表单改动"
```

#### 只保存工作区（忽略暂存区）

```bash
git stash push --keep-index
```

- 保留暂存区内容，只暂存工作区改动。

#### 只 stash 某些文件

```bash
git stash push -m "只保存某个文件" path/to/file.cpp
```

#### 从其他分支恢复 stash

stash 是全局的，任何分支都可以 `stash pop` 或 `apply`，不限定在哪个分支。

### 原理简述

- `git stash` 本质上是 Git 为你**自动生成一次匿名的 commit**，存放在 `.git/refs/stash` 里；
- 每个 stash 条目其实包含两个对象：
  - 一个是暂存区内容（index）；
  - 一个是工作区内容（working directory）；
- 可以通过 `git log refs/stash` 查看它们的本质。

### 注意事项

| 情况                                     | 说明                                        |
| ---------------------------------------- | ------------------------------------------- |
| `stash pop` 有冲突？                     | 需要你手动解决冲突并 `git add`              |
| 忘记在哪个分支 stash 的？                | 不影响，可以在任何分支 pop                  |
| 多次 stash 会丢吗？                      | 不会，Git 会编号（stash@{0}、stash@{1}...） |
| `stash` 后关机会丢吗？                   | 不会，stash 是 Git 内部 commit，保存在本地  |
| stash 的东西会上传远程吗？               | ❌ 不会，stash 不会自动 push 到远程          |
| 工作目录为 untracked 文件会被 stash 吗？ | 默认不会，除非用 `--include-untracked`      |

### 总结命令速查表

| 操作                  | 命令                        |
| --------------------- | --------------------------- |
| 暂存当前所有改动      | `git stash`                 |
| 带备注暂存            | `git stash push -m "说明"`  |
| 查看 stash 列表       | `git stash list`            |
| 恢复最近 stash 并删除 | `git stash pop`             |
| 恢复指定 stash 不删除 | `git stash apply stash@{n}` |
| 删除某个 stash        | `git stash drop stash@{n}`  |
| 删除全部 stash        | `git stash clear`           |

### 推荐使用模式

处理临时任务 → `git stash` → 切分支修 Bug → 切回 → `git stash pop` → 继续开发