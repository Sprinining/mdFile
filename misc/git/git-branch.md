## git branch

`git branch` 是 Git 中用于管理分支的一个核心命令。**分支（branch）** 是 Git 用来实现并行开发、隔离特性和版本控制的基本机制。可以把分支理解为项目历史的「时间线快照」，每个分支都是提交记录的一条路径。

### 核心概念

**分支是什么？**

- Git 中的分支本质上是一个指向某个 commit 的可变指针（指针就是引用 hash 值）。

**HEAD 是什么？**

- HEAD 是 Git 当前工作的分支引用，指向当前所在的分支名，再由分支名去指向最新的提交。

**创建分支是否复制代码？**

- 不。Git 创建分支只是添加一个新的指针，不会复制代码或文件，**极其轻量级**。

### 常用命令大全

#### 查看分支

```bash
git branch            # 列出本地所有分支，当前所在分支前面有 *
git branch -a         # 列出所有分支（包括远程分支）
git branch -r         # 列出所有远程分支
```

#### 创建分支

```bash
git branch new-branch         # 创建新分支（但不会切换过去）
git checkout -b new-branch    # 创建并切换到该分支（推荐）
git switch -c new-branch      # 新语法（>=Git 2.23）
```

#### 删除分支

```bash
git branch -d branch-name     # 删除分支（只能删除已合并的）
git branch -D branch-name     # 强制删除（未合并也删）
```

#### 切换分支

```bash
git checkout branch-name      # 切换到某个分支
git switch branch-name        # 新语法（推荐）
```

#### 重命名分支

```bash
git branch -m new-name        # 当前分支重命名
git branch -m old new         # 指定旧分支改为新名
```

#### 比较分支差异

```bash
git diff main..dev            # 查看 dev 相对于 main 的差异
```

### 实战场景案例

#### 场景 1：多人协作开发

```bash
# 主干 main
# 每个人创建自己的功能分支
git checkout -b feature/login

# 完成功能后合并到 main
git checkout main
git merge feature/login
```

#### 场景 2：修复 bug 快速切换

```bash
git switch -c hotfix/crash
# 修改代码并提交
git switch main
git merge hotfix/crash
```

#### 场景 3：查看哪些分支已合并/未合并

```bash
git branch --merged     # 查看已合并到当前分支的分支
git branch --no-merged  # 查看还未合并的
```

### 底层原理和结构

```css
.git/
├── HEAD                 # 当前分支引用
├── refs/
│   └── heads/           # 存储所有本地分支的指针（每个分支一个文件）
│       ├── main         # 内容是某个 commit 的 hash
│       └── dev
└── logs/                # 分支操作历史
```

举例：

```bash
# HEAD 指向 refs/heads/main
# main 文件中存的是提交 hash：abc123...

# 切换到 dev 分支时：
HEAD → refs/heads/dev
```

### 图示理解分支（简化版）

```css
* c3 (main)
|
* c2
|
* c1
```

如果新建分支 `dev`：

```css
* c3 (main, dev)
|
* c2
|
* c1
```

提交新的 commit：

```css
* c4 (dev)
|
* c3 (main)
|
* c2
```

这说明分支只是指针的不同位置，Git 可以轻松地回滚、合并或切换。

### FAQ

| 问题                         | 解答                                                 |
| ---------------------------- | ---------------------------------------------------- |
| 切换分支后，文件为什么会变？ | Git 会更新工作区为该分支最后一次提交的快照。         |
| `-d` 和 `-D` 区别？          | `-d` 删除已合并分支，`-D` 强制删除未合并分支。       |
| 合并冲突和分支有关吗？       | 是的。两个分支修改了相同文件的相同部分，会产生冲突。 |

### HEAD

**`HEAD` 是 Git 中指向当前检出提交对象的引用。它通常指向一个分支（如 `main`），也可以直接指向一个具体的 commit（即“分离 HEAD”）**。

#### HEAD 的本质

- `HEAD` 本质上是一个**指针（引用）**。
- 它记录了当前 **正在查看 / 操作的那一份代码快照**。

它的作用就像 IDE 里「当前打开的是哪个分支」或「你现在的代码版本停留在哪儿」。

#### HEAD 的两种状态

##### HEAD 指向某个分支（**正常状态**）

```css
HEAD → refs/heads/main → commit abc123
```

表示当前在 `main` 分支上，Git 会根据这个分支的提交历史进行开发。

`.git/HEAD` 文件内容：

```css
ref: refs/heads/main
```

##### HEAD 直接指向某个提交（**分离 HEAD 状态**）

```bash
git checkout abc123
```

这时：

```css
HEAD → commit abc123（不再指向任何分支）
```

 `.git/HEAD` 文件内容：

```css
abc123...（提交哈希）
```

#### 通俗例子

假设在看一本书（commit 历史），`HEAD` 就是现在夹的书签。

- 如果把书签夹在“主线章节”（main 分支）上，每次翻书、写笔记都追加到这章末尾：**这就是 HEAD 指向分支的情况。**
- 如果突然夹在中间某页（某个旧版本的提交），写了点新东西：**这就是分离 HEAD**，你写的内容不一定会保存下来。

#### Git 操作中的 HEAD 行为

| 操作                      | HEAD 指向变化     | 说明                                   |
| ------------------------- | ----------------- | -------------------------------------- |
| `git switch main`         | `HEAD → main`     | HEAD 指向分支                          |
| `git checkout abc123`     | `HEAD → abc123`   | 分离 HEAD，指向具体 commit             |
| `git commit`              | HEAD 所在分支前进 | 如果 HEAD 指向分支，提交会追加到该分支 |
| `git reset --hard HEAD~1` | 回退 HEAD         | HEAD 随分支一起回退                    |

#### 图示理解

##### 正常开发状态

```css
HEAD
  ↓
main → c3 → c4
```

##### 分离 HEAD 状态

```css
main → c3 → c4
          ↑
        HEAD（Detached）
```

#### 分离 HEAD 常见用途和风险

| 用途                | 示例                      |
| ------------------- | ------------------------- |
| 查看旧版本          | `git checkout abc123`     |
| 临时测试某版本      | `git checkout tag/v1.0.0` |
| 变基、Rebase 操作中 | 自动进入 Detached HEAD    |

**注意：**如果在分离 HEAD 状态下提交更改，**必须手动创建分支保存**，否则一旦切换分支，这些提交可能被 Git 垃圾回收清除。

#### 总结

| 名词             | 含义                                     |
| ---------------- | ---------------------------------------- |
| `HEAD`           | 当前所在位置（书签）                     |
| `HEAD → 分支`    | 正常开发状态                             |
| `HEAD → commit`  | 分离 HEAD 状态                           |
| `.git/HEAD` 文件 | 保存当前 HEAD 的引用指向（分支名或哈希） |