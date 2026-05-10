## 初始化opengl项目

### 项目结构

```bash
opengl-learn/
├── CMakeLists.txt
├── src/
│   └── main.cpp
├── include/
│   ├── glad/
│   └── KHR/
├── glad/
│   └── glad.c
├── build/
└── compile_commands.json
```

###  安装系统依赖

```bash
sudo dnf install glfw-devel mesa-libGL-devel
```

- glfw-devel：GLFW 头文件 + 库
- mesa-libGL-devel：OpenGL 开发库

GLFW 本质是：

```css
窗口 + 输入 + OpenGL Context
```

它负责创建窗口、键盘鼠标、创建 OpenGL 上下文、处理事件。

真正画图的是 OpenGL，Mesa 是 Linux 下最常见的 OpenGL 实现，里面有 `libGL.so`、`OpenGL headers`、`OpenGL loader`。

整个关系：

```css
      程序
       ↓
   GLFW（窗口）
   	   ↓
OpenGL API（glXXX）
       ↓
Mesa / NVIDIA / AMD 驱动
       ↓
      GPU
```

### 准备 GLAD

GLAD 是 **OpenGL 函数加载器**，它的作用是在运行时从显卡驱动获取 OpenGL 函数地址。

进入 [GLAD 生成器](https://glad.dav1d.de/?utm_source=chatgpt.com)，设置：

- Language: C/C++
- Specification: OpenGL
- Version: 3.3
- Profile: Core
- Generate loader ✔

下载后放入：

```bash
glad/src/glad.c
include/glad/*
include/KHR/*
```

### CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.10)
project(OpenGLDemo)

set(CMAKE_CXX_STANDARD 17)

add_executable(app
    src/main.cpp
    glad/src/glad.c
)

target_include_directories(app PRIVATE include)

target_link_libraries(app
    glfw
    GL
    dl
)
```

### main.cpp

```cpp
#include <glad/glad.h>   // OpenGL 函数加载器
#include <GLFW/glfw3.h>  // GLFW：窗口、输入、OpenGL Context

int main() {
    // 初始化 GLFW
    // GLFW 是一个窗口库：
    //   - 创建窗口
    //   - 处理键盘鼠标
    //   - 创建 OpenGL Context
    // 不调用 glfwInit()，后面 GLFW API 都不能用
    glfwInit();

    // 指定 OpenGL 主版本号 = 3
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    // 指定 OpenGL 次版本号 = 3
    // OpenGL 3.3
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);

    // 指定使用 Core Profile
    // Core: 现代 OpenGL
    // Compatibility: 兼容旧版 OpenGL
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // 创建窗口
    // 800, 600: 窗口宽高
    // "OpenGL": 窗口标题
    // nullptr: 不使用全屏显示器
    // nullptr: 不共享其他窗口的 OpenGL Context
    GLFWwindow* window = glfwCreateWindow(800, 600, "OpenGL", nullptr, nullptr);

    // 创建失败
    // 常见原因：
    //   - OpenGL版本不支持
    //   - GLFW初始化失败
    //   - 显卡驱动问题
    if (!window) return -1;

    // 将当前窗口的 OpenGL Context 设置为当前线程使用
    // 后面所有 glXXX 调用：
    //   glClear
    //   glViewport
    //   glDrawArrays
    // 都会作用于这个 Context
    glfwMakeContextCurrent(window);

    // 初始化 GLAD
    // OpenGL 函数不是直接可用的，
    // 必须运行时从显卡驱动获取函数地址
    //
    // glfwGetProcAddress: GLFW 提供的“获取 OpenGL函数地址”的函数
    // gladLoadGLLoader: GLAD 自动加载所有 OpenGL 函数指针
    //
    // 如果失败 glClear / glCreateShader 等函数都会是 NULL
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) return -1;

    // 设置 OpenGL 视口（viewport）
    // 左下角x = 0
    // 左下角y = 0
    // 宽 = 800
    // 高 = 600
    //
    // 含义：OpenGL 渲染结果映射到窗口哪个区域
    glViewport(0, 0, 800, 600);

    // 主循环
    // 只要窗口没被关闭，就一直渲染
    while (!glfwWindowShouldClose(window)) {
        // 检测 ESC 键是否按下
        // GLFW_PRESS: 当前帧按下
        if (glfwGetKey(window, GLFW_KEY_ESCAPE)) glfwSetWindowShouldClose(window, true);

        // 设置清屏颜色
        // 参数：R G B A
        // 范围：0.0 ~ 1.0
        glClearColor(0.1f, 0.2f, 0.3f, 1.0f);

        // 清空颜色缓冲区
        // 可以理解成用上面的颜色填满整个窗口
        // GL_COLOR_BUFFER_BIT: 表示清空颜色缓冲
        glClear(GL_COLOR_BUFFER_BIT);

        // 交换前后缓冲区
        // OpenGL 默认双缓冲：
        // front buffer: 正在显示
        // back buffer: 正在绘制
        // 绘制完成后交换：back -> front
        // 这样避免画面闪烁
        glfwSwapBuffers(window);

        // 处理窗口事件
        // 包括：
        //   - 键盘
        //   - 鼠标
        //   - 窗口移动
        //   - 窗口关闭
        //
        // 不调用的话窗口会“假死”
        glfwPollEvents();
    }

    // 清理 GLFW 资源
    glfwTerminate();
}
```

### 编译

```bash
# 进入项目目录，CMakeLists.txt 就在这里
cd opengl-learn

# 使用 CMake 生成构建目录
#
# -S .
#   指定“源码目录(source)”
#   . 表示当前目录
#
# -B build
#   指定“构建目录(build)”
#   所有中间文件、Makefile、缓存都会放进去
#   不会污染源码目录
#
# -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
#   生成 compile_commands.json
#   这个文件记录：
#     - include 路径
#     - 编译参数
#     - 宏定义
#     - 编译器选项
#   clangd / Neovim / LSP 会读取它
#   否则编辑器会出现红色波浪线
#
# 执行后会生成：
# build/
# ├── Makefile
# ├── CMakeCache.txt
# ├── compile_commands.json
# └── ...
#
cmake -S . -B build \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON


# 开始真正编译项目
# 等价于：
#   cd build
#   make
# CMake 会自动调用对应构建工具
cmake --build build
```

### 解决 Neovim 红线

```bash
ln -sf build/compile_commands.json .
```

在当前目录创建一个名为 `compile_commands.json` 的软链接（快捷方式），它实际指向 `build/compile_commands.json`，并且如果同名文件已存在则强制覆盖，这样 clangd/Neovim 就能在项目根目录自动读取最新的编译配置。

项目会变成：

```bash
opengl-learn/
├── build/
│   └── compile_commands.json
│
├── compile_commands.json -> build/compile_commands.json
```

### 运行

```bash
./build/app
```

### 整个流程逻辑

```css
系统安装 GLFW（dnf）
        ↓
CMake 负责链接 GLFW
        ↓
GLAD 负责 OpenGL函数加载
        ↓
GLFW 负责窗口 + context
        ↓
GPU 开始工作
```

