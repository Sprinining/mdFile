## 使用 Qt + Inno Setup 打包桌面应用

### 添加 Qt 应用图标（`.ico`）

Windows 桌面应用默认是没有图标的，为了提升可识别性和专业性，我们通常会给应用添加一个 `.ico` 图标文件。

#### 制作 `.ico` 图标

如果已经有 `.png`、`.jpg` 或 `.webp` 格式图像，可以使用以下方式生成 `.ico` 文件：

- **推荐工具**：https://www.icoconverter.com/
- 或使用命令行工具 `ImageMagick`（需安装）：

```bash
magick input.png -define icon:auto-resize=64,48,32,16 output.ico
```

#### 在 CMake 中给 Windows Qt 程序添加图标

##### **准备 `.ico` 文件**
将图标文件（例如 `app_icon.ico`）放在项目目录的某个子目录，比如 `icons/`。

##### **创建资源脚本 `.rc` 文件**
在项目根目录创建一个名为 `app_icon.rc` 的文件，内容如下：

```rc
IDI_ICON1 ICON "icons/app_icon.ico"
```

这里路径 `"icons/app_icon.ico"` 是相对于 `.rc` 文件的位置。表示告诉编译器从 `app_icon.rc` 同级目录的 `icons` 子目录去找 `app_icon.ico`。

##### **修改 `CMakeLists.txt`**

在 `CMakeLists.txt` 中，找到 `add_executable()` 或 `qt_add_executable()` 语句，将 `.rc` 文件加进去：

```cmake
if(WIN32)
    set(WINDOWS_ICON_RC "${CMAKE_CURRENT_SOURCE_DIR}/app_icon.rc")
endif()

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(rust-gene-calc
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
        ${WINDOWS_ICON_RC}      # 添加资源文件
    )
else()
    add_executable(rust-gene-calc
        ${PROJECT_SOURCES}
        ${WINDOWS_ICON_RC}      # 添加资源文件
    )
endif()
```

##### **重新构建项目**

完成以上步骤后，重新运行 CMake 和构建，生成的 `rust-gene-calc.exe` 就会带有指定的图标。

### 生成 Release 程序

在 Qt Creator 中进行以下操作：

1. 切换到 **Release 模式**
2. 点击 **Build（构建）**
3. 构建完成后，在 `build-xxx-Release` 文件夹中找到 `.exe` 程序

#### 复制必要文件

为了能独立运行，需要将 Qt 的依赖库和资源一并打包。推荐使用官方工具：

```bash
windeployqt path\to\your_app.exe
```

这会把 Qt 依赖的 `.dll`、插件等拷贝到可执行文件所在目录中。

### 使用 Inno Setup 打包安装程序

#### 安装 Inno Setup

官网下载并安装：https://jrsoftware.org/isinfo.php

安装后启动 Inno Script Studio 或 Inno Setup Compiler 即可编写 `.iss` 安装脚本。

#### 编写 `.iss` 安装脚本

拷贝 `build-xxx-Release` 整个目录，重命名为 `MyApp_Deploy`，拷贝一份 `app_icon.ico` 到这个目录下，用作安装程序使用的图标文件。

创建一个名为 `install.iss` 的文件（`MyApp_Deploy` 同级目录），示例内容如下：

```ini
[Setup]
AppName=Rust Gene Calculator
AppVersion=1.0.0
DefaultDirName={pf}\RustGeneCalc
OutputDir=.
OutputBaseFilename=RustGeneCalcInstaller
SetupIconFile="MyApp_Deploy\app_icon.ico"

[Files]
Source: "MyApp_Deploy\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Rust Gene Calculator"; Filename: "{app}\rust-gene-calc.exe"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\卸载 Rust Gene Calculator"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\rust-gene-calc.exe"; Description: "运行 Rust Gene Calculator"; Flags: nowait postinstall skipifsilent
```

| **部分**  | **内容**                                    | **说明**                                             |
| --------- | ------------------------------------------- | ---------------------------------------------------- |
| `[Setup]` | `AppName=Rust Gene Calculator`              | 安装程序名称，显示在安装界面和开始菜单中             |
|           | `AppVersion=1.0.0`                          | 应用程序版本号                                       |
|           | `DefaultDirName={pf}\RustGeneCalc`          | 默认安装目录，`{pf}` 是系统“Program Files”文件夹路径 |
|           | `OutputDir=.`                               | 编译输出目录，这里表示输出在当前目录                 |
|           | `OutputBaseFilename=RustGeneCalcInstaller`  | 生成的安装程序文件名，不包含扩展名                   |
|           | `SetupIconFile="MyApp_Deploy\app_icon.ico"` | 安装程序使用的图标文件路径（相对于 `.iss` 文件）     |

| **部分**  | **内容**                                                     | **说明**                                                     |
| --------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `[Files]` | `Source: "MyApp_Deploy\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs` | 指定要包含进安装包的文件及目录 - `Source`：打包源目录及文件 - `DestDir`：安装后文件的目标目录，`{app}` 代表安装目录 - `Flags`：`ignoreversion` 忽略版本检测，`recursesubdirs` 递归包含子文件夹，`createallsubdirs` 安装时创建所有子目录 |

| **部分**  | **内容**                                                     | **说明**                                                     |
| --------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `[Icons]` | `Name: "{group}\Rust Gene Calculator"; Filename: "{app}\rust-gene-calc.exe"; IconFilename: "{app}\app_icon.ico"` | 创建开始菜单快捷方式 - `Name`：快捷方式名称，`{group}` 代表开始菜单程序组目录 - `Filename`：快捷方式指向的可执行文件路径 - `IconFilename`：快捷方式使用的图标路径 |
|           | `Name: "{group}\卸载 Rust Gene Calculator"; Filename: "{uninstallexe}"` | 创建“卸载程序”快捷方式，`{uninstallexe}` 是卸载程序的路径    |

| **部分** | **内容**                                                     | **说明**                                                     |
| -------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `[Run]`  | `Filename: "{app}\rust-gene-calc.exe"; Description: "运行 Rust Gene Calculator"; Flags: nowait postinstall skipifsilent` | 安装完成后自动运行程序 - `Filename`：运行的程序路径 - `Description`：安装完成时显示的操作描述 - `Flags`：  - `nowait`：不等待程序退出  - `postinstall`：表示安装完成后执行  - `skipifsilent`：静默安装时跳过运行 |

#### 编译安装包

1. 用 Inno Setup 打开 `install.iss`
2. 点击菜单栏 **Build → Compile（或 F9）**
3. 编译成功后，将生成 `RustGeneCalcInstaller.exe` 安装包

### 给版本打 Tag 并发布 Release 到 Github

1. 创建带说明的 Tag：

```bash
git tag -a v1.0.0 -m "发布 Rust Gene Calculator 1.0.0 正式版本"
```

2. 推送 Tag 到远程：

```bash
git push origin v1.0.0
```

3. 在 GitHub 项目页面点击 **Releases → Draft a new release**

4. 选择刚推送的 Tag（如 `v1.0.0`）

5. 填写 Release 标题，例如：

```txt
v1.0.0 - 初始正式版
```

6. 在描述框写版本更新说明

7. 上传 Inno Setup 生成的安装包 `.exe` 文件

8. 点击 **Publish release** 发布