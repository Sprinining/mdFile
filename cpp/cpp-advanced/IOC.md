## IOC

IOC（Inversion of Control，**控制反转**）是软件设计中的一种思想，不是某种具体语法，它的核心理念是：

> **“谁控制谁？谁依赖谁？”的主客关系被反转了。**

### 通俗理解

以前你写代码时是你主动调用库：

```cpp
// 你控制流程
DBConnection conn;
conn.open();
conn.query("SELECT * FROM user");
```

在 IOC 中，**你不再控制流程**，而是：

- 框架调用你的代码（你提供回调 / 注册函数）
- 你只是把“我想干的事”告诉框架，由框架在需要的时候调用你

简单的例子：事件回调

```cpp
// 你写的回调函数
void onButtonClick() {
    std::cout << "Button clicked!" << std::endl;
}

// 框架帮你注册
button.setOnClickListener(onButtonClick);
```

你不负责监听、处理点击等流程，**控制权交给了框架（或库）**，你只负责把“要干的事”交给它，这就是控制反转。

### 应用场景

| 场景             | 控制反转表现                                  |
| ---------------- | --------------------------------------------- |
| 回调函数         | 程序调用库 → 变成 库调用程序                  |
| GUI 框架         | 用户事件监听逻辑由框架控制                    |
| 依赖注入（DI）   | 类的依赖不自己创建，而由框架注入（如 Spring） |
| Web 框架控制路由 | 你只提供处理器，框架决定什么时候、如何调用    |

IOC 和回调函数的关系：

- 回调函数是控制反转的**一种具体实现手段**
- 控制反转更偏向**设计思想**
- 回调是控制权转移的**执行方式**

### IOC的实现方式

#### 1. 依赖注入（DI, Dependency Injection）

**依赖注入（Dependency Injection，简称 DI）** 是一种实现“控制反转（IoC）”的方式，它的核心思想是：

> **一个对象所依赖的其它对象，不由它自己创建，而是从外部“注入”进去。**

##### 1.1 构造函数注入（Constructor Injection）✅ 常用

依赖通过构造函数传入。

```cpp
class Engine {
public:
    void start() {}
};

class Car {
    Engine* engine;
public:
    Car(Engine* e) : engine(e) {}  // 注入依赖
    void drive() {
        engine->start();
    }
};
```

**优点：**

- 依赖明确
- 易于测试和替换
- 适合必须有依赖才能工作的组件（强依赖）

##### 1.2 Setter 注入（Setter Injection）

通过 `setXXX()` 方法注入依赖。

```cpp
class Car {
    Engine* engine;
public:
    void setEngine(Engine* e) { engine = e; }
    void drive() {
        if (engine) engine->start();
    }
};
```

**优点：**

- 适合“可选”依赖（弱依赖）
- 灵活（可以延迟注入、替换）

**缺点：**

- 有依赖未设置的风险
- 不强制依赖完整性

##### 1.3 接口注入（Interface Injection）

组件必须实现一个“注入依赖”的接口，容器调用该接口来传入依赖。

```cpp
class IEngineAware {
public:
    virtual void setEngine(Engine* e) = 0;
};

class Car : public IEngineAware {
    Engine* engine;
public:
    void setEngine(Engine* e) override {
        engine = e;
    }
};
```

**特点：**

- 明确暴露依赖接口
- 解耦注入过程和对象创建过程
- 主要见于 Java/.NET（C++ 中较少）

##### 1.4 框架容器注入（由容器自动管理）

比如 Java 的 Spring、C++ 的 Boost.DI：

```cpp
auto injector = boost::di::make_injector(
    boost::di::bind<Engine>.to<SportsEngine>()
);
auto car = injector.create<Car>();
```

- 容器统一负责所有类的构建与依赖注入
- 强大、可扩展，但需要框架支持

总结一句话：

> 依赖注入是一种**把依赖交给外部管理和传递**的方式，实现了**控制反转**，让类之间的**耦合度更低、扩展性更好**。

#### 2. 服务定位器模式（Service Locator Pattern）

```cpp
#include <iostream>
#include <unordered_map>
#include <string>
#include <memory>
#include <functional>

// 服务接口
class IService {
public:
    virtual void execute() = 0;
    virtual ~IService() = default;
};

// 具体服务实现
class LoggerService : public IService {
public:
    void execute() override {
        std::cout << "Logging something important..." << std::endl;
    }
};

// 服务定位器容器
class ServiceLocator {
private:
    static std::unordered_map<std::string, std::shared_ptr<IService>> services;

public:
    static void registerService(const std::string& name, std::shared_ptr<IService> service) {
        services[name] = service;
    }

    static std::shared_ptr<IService> getService(const std::string& name) {
        if (services.find(name) != services.end()) {
            return services[name];
        }
        return nullptr;
    }
};

// 静态成员定义
std::unordered_map<std::string, std::shared_ptr<IService>> ServiceLocator::services;

// 客户端代码，主动从服务定位器获取依赖
void clientFunction() {
    auto logger = ServiceLocator::getService("Logger");
    if (logger) {
        logger->execute();
    } else {
        std::cout << "Logger service not found!" << std::endl;
    }
}

int main() {
    // 注册服务
    ServiceLocator::registerService("Logger", std::make_shared<LoggerService>());

    // 调用客户端函数
    clientFunction();

    return 0;
}
```

解析：

- `ServiceLocator` 充当一个 **全局服务注册和查找中心**。
- 组件（这里是 `clientFunction`）主动调用 `ServiceLocator::getService` 拿到依赖。
- 依赖关系对组件来说是“隐藏的”，它需要知道服务名称并调用服务定位器获取。

优点：

- 服务管理集中，动态灵活。
- 容易扩展和替换服务实现。

缺点：

- 依赖不明确，增加测试复杂度。
- 组件耦合到服务定位器（全局访问），可能不易维护。

