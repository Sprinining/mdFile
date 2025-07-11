## 仓库用途

------

记录学习内容

## 历史变更

------

### 2024.10.17

- 迁移自原来的仓库（已修改为 private），修改了文件目录结构

## 提交规范

------

采用 [Angular 提交信息规范](https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#-commit-message-guidelines)，提交格式如下：

```txt
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

每次提交可以包含页眉(`header`)、正文(`body`)和页脚(`footer`)，每次提交**必须包含页眉内容**

每次提交的信息不超过`100`个字符

详细文档：[AngularJS Git Commit Message Conventions](https://docs.google.com/document/d/1QrDFcIiPjSLDn3EL15IJygNPiHORgU1_OOAqWjiDU5Y/edit#)

### 1.页眉设置

页眉的格式指定为提交类型(`type`)、作用域(`scope`，可选)和主题(`subject`)

#### 1.1提交类型

提交类型指定为下面其中一个：

| 类型（Type）     | 描述                                        | 是否发布版本变更（默认）   |
| ------------ | ----------------------------------------- | -------------- |
| **feat**     | ✨ 新功能、新特性（Features）                       | ✅ Minor 版本（默认） |
| **fix**      | 🐛 修复 bug（Bug Fixes）                      | ✅ Patch 版本（默认） |
| **docs**     | 📝 仅文档变更，如 README、注释等                     | ❌              |
| **style**    | 💅 不影响功能的代码风格修改，如空格、格式、缺失的分号等             | ❌              |
| **refactor** | 🔨 重构代码（不含功能修改或 bug 修复）                   | ❌              |
| **perf**     | ⚡ 性能优化（Performance）                       | ✅ Patch        |
| **test**     | ✅ 添加、修改或删除测试代码（不影响生产代码）                   | ❌              |
| **build**    | 📦 构建系统变更，如 webpack、vite、rollup 配置变更      | ❌              |
| **ci**       | 🤖 持续集成配置，如 GitHub Actions、Jenkins、Travis | ❌              |
| **chore**    | 🔧 杂项事务，如修改脚本、更新依赖、项目配置（非功能或 bug）         | ❌              |
| **revert**   | ⏪ 回滚某个提交，需包含 `revert:` 前缀                 | ✅ 视情况而定        |
| **deps**     | 📦 升级依赖包（常作为 chore 的子类）                   | ❌              |
| **merge**    | 🔀 合并分支（用于手动合并等情况）                        | ❌              |
| **release**  | 🚀 发布版本相关提交                               | ✅（用于手动发版时）     |


#### 1.2作用域

范围可以是任何指定提交更改位置的内容

#### 1.3主题

主题包括了对本次修改的简洁描述，有以下准则

1. 使用命令式，现在时态：“改变”不是“已改变”也不是“改变了”
2. 不要大写首字母
3. 不在末尾添加句号

### 2.正文设置

和主题设置类似，使用命令式、现在时态

应该包含修改的动机以及和之前行为的对比

### 3.页脚设置

#### 3.1 Breaking changes

不兼容修改指的是本次提交修改了不兼容之前版本的`API`或者环境变量

所有不兼容修改都必须在页脚中作为中断更改块提到，以`BREAKING CHANGE`:开头，后跟一个空格或者两个换行符，其余的信息就是对此次修改的描述，修改的理由和修改注释

```txt
BREAKING CHANGE: isolate scope bindings definition has changed and
    the inject option for the directive controller injection was removed.

    To migrate the code follow the example below:

    Before:

    。。。
    。。。

    After:

    。。。
    。。。

    The removed `inject` wasn't generaly useful for directives so there should be no code using it.
```

#### 3.2 引用提交的问题

如果本次提交目的是修改`issue`的话，需要在页脚引用该`issue`

以关键字`Closes`开头，比如

```txt
Closes #234
```

如果修改了多个`bug`，以逗号隔开

```txt
Closes #123, #245, #992
```

### 4.回滚设置

当此次提交包含回滚(`revert`)操作，那么页眉以`"revert:"`开头，同时在正文中添加`"This reverts commit hash"`，其中`hash`值表示被回滚前的提交

```txt
revert:<type>(<scope>): <subject>
<BLANK LINE>
This reverts commit hash
<other-body>
<BLANK LINE>
<footer>
```
