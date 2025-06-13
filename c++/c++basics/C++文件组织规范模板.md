## C++ 文件组织规范模板

### 文件结构示例

```css
math/
├── math.h         // 对外暴露的接口
├── math.cpp       // 接口的实现
├── math_internal.h // 私有辅助函数声明（可选）
```

### `.h` 文件（对外接口）

#### 作用

- 声明对外可见的函数、类、常量
- 不包含实现细节（除模板或 `inline` 函数）

#### 格式模板

```cpp
#ifndef MATH_H
#define MATH_H

#include <vector>
#include <string>

namespace math {

// 常量定义
constexpr double PI = 3.141592653589793;

// 普通函数声明
int add(int a, int b);
double average(const std::vector<int>& nums);

// 类声明示范
class Calculator {
public:
    Calculator();
    explicit Calculator(const std::string& owner);

    ~Calculator();

    int add(int a, int b) const;
    double average(const std::vector<int>& nums) const;

    void setOwner(const std::string& owner);
    std::string getOwner() const;

    static int getInstanceCount();

private:
    std::string owner_;
    static int instanceCount_;

    // 私有辅助函数（只在类内部使用）
    void updateState();
};

} // namespace math

#endif // MATH_H
```

### `.cpp` 文件（接口实现）

#### 格式模板

```cpp
#include "math.h"

namespace math {

// 静态成员变量初始化
int Calculator::instanceCount_ = 0;

// 普通函数实现
int add(int a, int b) {
    return a + b;
}

double average(const std::vector<int>& nums) {
    if (nums.empty()) return 0.0;
    int sum = 0;
    for (int n : nums) sum += n;
    return static_cast<double>(sum) / nums.size();
}

// 类成员函数实现

Calculator::Calculator() : owner_("Unknown") {
    ++instanceCount_;
}

Calculator::Calculator(const std::string& owner) : owner_(owner) {
    ++instanceCount_;
}

Calculator::~Calculator() {
    --instanceCount_;
}

int Calculator::add(int a, int b) const {
    return a + b;
}

double Calculator::average(const std::vector<int>& nums) const {
    if (nums.empty()) return 0.0;
    int sum = 0;
    for (int n : nums) sum += n;
    return static_cast<double>(sum) / nums.size();
}

void Calculator::setOwner(const std::string& owner) {
    owner_ = owner;
    updateState();
}

std::string Calculator::getOwner() const {
    return owner_;
}

int Calculator::getInstanceCount() {
    return instanceCount_;
}

void Calculator::updateState() {
    // 私有函数具体实现
}

} // namespace math
```

### `.h` 内部头文件（可选）

#### 场景：模块内部共用、外部不暴露的函数或工具

```cpp
// math_internal.h
#ifndef MATH_INTERNAL_H
#define MATH_INTERNAL_H

namespace math {
    static int clamp(int x, int low, int high) {
        return (x < low) ? low : (x > high ? high : x);
    }
}

#endif
```

注意：这种 `static` 函数若出现在头文件中，每个包含它的 `.cpp` 文件都会生成一份副本。若为工具函数，可考虑 `inline` 替代。

### 命名和修饰符规范

| 元素类型  | 推荐修饰符              | 写在 `.h` 还是 `.cpp`      |
| --------- | ----------------------- | -------------------------- |
| 普通函数  | 无（或 `extern`）       | `.h` 中声明，`.cpp` 中定义 |
| 内部函数  | `static` 或匿名命名空间 | `.cpp` 中定义              |
| 内联函数  | `inline`                | `.h` 中定义                |
| 模板函数  | 无（只能写 `.h`）       | `.h` 中定义                |
| 类 / 枚举 | 推荐放 `.h`             | `.h` 中定义                |

### 小建议

- `.h` 文件总是要写 include guard 或 `#pragma once`
- 尽量用命名空间包裹函数 / 类，防止污染全局空间
- 拆分职责清晰的模块，函数不宜太长
- `.cpp` 文件中优先包含对应 `.h`，可防止头文件漏包含依赖
- 使用 `clang-format` 等工具保持风格一致