## git restore

`git restore` 用于恢复工作区（和暂存区）中一个或多个文件的内容，撤销未提交的修改，恢复到某个提交或分支对应的版本。

### 主要用途

- 放弃对某个文件或目录在工作区的改动，恢复到指定提交版本。
- 放弃暂存区中的某个文件改动，恢复暂存区内容。
- 结合选项可以恢复到 HEAD、某个 commit、或者远程分支的版本。

### 基本命令格式

```bash
git restore [<options>] [--source=<commit>] <pathspec>...
```

### 常见用法

#### 恢复工作区文件到最新提交（HEAD）

```bash
git restore file.txt
```

等同于旧版：

```bash
git checkout -- file.txt
```

恢复当前分支最新提交版本，放弃对 `file.txt` 的未提交改动。

#### 恢复暂存区文件改动（撤销已 `git add` 的修改）

```bash
git restore --staged file.txt
```

把 `file.txt` 从暂存区恢复到 HEAD 版本，但工作区不变，相当于撤销 `git add`。

#### 同时恢复暂存区和工作区

```bash
git restore --staged --worktree file.txt
```

相当于把暂存区和工作区都恢复到 HEAD，完全撤销改动。

#### 恢复到指定版本（比如某个 commit 或远程分支）

```bash
git restore --source=commit-hash file.txt
```

或

```bash
git restore --source=origin/main file.txt
```

将 `file.txt` 恢复到指定版本的内容。

### 重要选项

| 选项                | 说明                          |
| ------------------- | ----------------------------- |
| `--source=<commit>` | 指定恢复的版本（默认是 HEAD） |
| `--staged`          | 仅恢复暂存区，不影响工作区    |
| `--worktree`        | 仅恢复工作区（工作目录）      |
| `--patch`           | 交互式恢复，逐个修改块确认    |

### 对比 `git checkout`

| 功能         | `git checkout`           | `git restore`              |
| ------------ | ------------------------ | -------------------------- |
| 恢复文件内容 | 也可以，但功能多且易混淆 | 专门用于恢复文件，语义明确 |
| 切换分支     | 支持                     | 不支持                     |
| 恢复暂存区   | 通过特殊用法，但不直观   | 直接支持                   |
| 交互式恢复   | 通过 `git checkout -p`   | 通过 `git restore --patch` |

### 总结

| 场景                       | 命令示例                               | 说明                           |
| -------------------------- | -------------------------------------- | ------------------------------ |
| 放弃工作区修改             | `git restore file`                     | 还原到最近一次提交状态         |
| 撤销暂存区修改             | `git restore --staged file`            | 把文件从暂存区撤销，工作区保留 |
| 同时撤销工作区和暂存区修改 | `git restore --staged --worktree file` | 彻底撤销改动                   |
| 恢复指定提交版本           | `git restore --source=<commit> file`   | 恢复到指定版本                 |