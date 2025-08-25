## C++ 拷贝控制双向关系维护

- << C++ Primer>> 13.4 拷贝控制示例

### 背景

假设有：

- 多个消息（`Message`）
- 多个文件夹（`Folder`）

**目标：**

- `Folder` 需要知道它有哪些 `Message`
- `Message` 需要知道它属于哪些 `Folder`

这是为了让两个对象的关系保持一致，方便操作和维护。

#### 单向关系的问题

假设只有 `Folder` 维护 `messages` 集合，`Message` 不知道自己在哪些文件夹。

- 当删除一个 `Message`，要从所有文件夹中把它删掉，但 `Message` 不知道自己在哪些文件夹里，没法找到所有关联的 `Folder` 进行清理，容易出现悬挂指针或者内存泄漏。
- 同理，`Folder` 被销毁或修改时，也可能需要更新 `Message` 的状态，单向关系无法同步。

#### 双向关系

双向维护意味着：

- `Folder` 里有一个 `messages` 集合，存放指向它包含的 `Message` 指针。
- `Message` 里有一个 `folders` 集合，存放指向它所在的 `Folder` 指针。

这样两个对象都能方便地访问对方，彼此同步状态。

### 源码

#### Message.h

```cpp
#pragma once
#include <string>
#include <set>

class Folder;

// Message 类，表示一条消息，可能属于多个 Folder（文件夹）
class Message {
    // Folder 类可以访问 Message 的私有成员
    friend class Folder;
    // 以下两个函数是辅助调试打印函数，作为友元访问私有成员
    friend void printFolderMessages(const Folder&, const std::string&);
    friend void printMessageFolders(const Message&, const std::string&);

public:
    // 构造函数，允许用字符串初始化消息内容，默认为空字符串
    explicit Message(const std::string& str = "") : contents(str) {}

    // 拷贝构造函数
    // 复制消息内容及其所属文件夹，同时将新消息添加到这些文件夹中
    Message(const Message& msg);

    // 拷贝赋值运算符
    // 先断开旧关系，再复制新内容和文件夹，再重新建立关系
    Message& operator=(const Message& msg);

    // 析构函数
    // 删除消息时自动将其从所有关联的文件夹中移除，断开双向关联
    ~Message();

    // 保存消息到指定 Folder 中
    // 会把自己添加到 folder 的 messages 集合，并把 folder 添加到自己的 folders 集合
    void save(Folder&);

    // 从指定 Folder 中移除消息
    // 会断开自己与 folder 的双向关联
    void remove(Folder&);

private:
    std::string contents;          // 消息的内容
    std::set<Folder*> folders;     // 指向包含该消息的所有 Folder 的指针集合

    // 辅助函数，将自己添加到所有 folders 指向的 Folder 中的 messages 集合
    void addToFolders();

    // 辅助函数，将自己从所有 folders 指向的 Folder 中的 messages 集合中移除，并清空 folders 集合
    void removeFromFolders();
};
```

#### Folder.h

```cpp
#pragma once
#include <set>
#include <string>

class Message;

// Folder 类，表示一个文件夹，保存多个 Message（消息）的指针
class Folder {
	// Message 类可以访问 Folder 的私有成员
	friend class Message;
	// 友元函数，方便打印 Folder 内消息和 Message 内文件夹，用于调试
	friend void printFolderMessages(const Folder&, const std::string&);
	friend void printMessageFolders(const Message&, const std::string&);

public:
	// 默认构造函数，创建一个空的文件夹
	explicit Folder() {}

	// 拷贝构造函数
	// 复制 messages 集合，同时将自己添加到所有消息的 folders 中
	Folder(const Folder&);

	// 拷贝赋值运算符
	// 先从原消息中移除自己，再复制 messages 集合，最后将自己添加到新消息中
	Folder& operator=(const Folder&);

	// 析构函数
	// 析构时将自己从所有消息的 folders 集合中移除，断开双向关联
	~Folder();

	// 保存自己到指定的 Message 的 folders 集合中
	// 同时将指定的消息添加到自己的 messages 集合中，建立双向关联
	void save(Message&);

	// 从指定的 Message 的 folders 集合中移除自己
	// 同时将指定消息从自己的 messages 集合中移除，断开双向关联
	void remove(Message&);

private:
	std::set<Message*> messages;  // 保存指向所有属于该文件夹的消息的指针集合
	// 辅助函数，将自己添加到 messages 集合中所有消息的 folders 集合中
	void addToMessages();

	// 辅助函数，从 messages 集合中所有消息的 folders 集合中移除自己
	// 并清空 messages 集合
	void removeFromMessages();
};
```

#### Message.cpp

```cpp
#include "Message.h"
#include "Folder.h"

// 拷贝构造函数
// 复制内容和 folders 集合，然后把自己添加到所有这些文件夹的 messages 集合中
Message::Message(const Message& msg) 
    : contents(msg.contents), folders(msg.folders) {
    addToFolders();
}

// 拷贝赋值运算符
// 先断开旧的文件夹关系，复制内容和文件夹集合，再建立新的关系
Message& Message::operator=(const Message& msg) {
    if (&msg != this) {
        removeFromFolders(); // 断开旧的文件夹-消息关系
        contents = msg.contents;
        folders = msg.folders;
        addToFolders();      // 建立新的文件夹-消息关系
    }
    return *this;
}

// 析构函数
// 销毁消息前，先从所有文件夹的消息集合中移除自己，断开关联
Message::~Message() {
    removeFromFolders();
}

// 保存消息到指定的 folder
// 把自己添加到 folder 的 messages 集合中
// 同时把 folder 添加到自己的 folders 集合中，建立双向关系
void Message::save(Folder& folder) {
    folder.messages.insert(this);
    folders.insert(&folder);
}

// 从指定的 folder 中移除自己
// 同时从自己的 folders 集合中移除该 folder，断开双向关系
void Message::remove(Folder& folder) {
    folders.erase(&folder);
    folder.messages.erase(this);
}

// 辅助函数，将自己添加到所有 folders 集合中 folder 的 messages 集合中
void Message::addToFolders() {
    for (auto f : folders)
        save(*f);
}

// 辅助函数，从所有 folders 集合中 folder 移除自己，并清空 folders 集合
void Message::removeFromFolders() {
    // 用临时变量存储，避免在遍历时修改容器导致迭代器失效
    std::set<Folder*> tempFolders = folders;
    for (auto f : tempFolders)
        remove(*f);
    folders.clear();
}
```

##### 为啥用临时变量存储迭代器正在遍历的容器?

如果不用临时变量存储：

```cpp
void Message::removeFromFolders() {
    for (auto f : folders)
        remove(*f);  // 这里remove会调用 folders.erase(&folder);
    folders.clear();
}
```

- `remove(*f)` 调用里，`folders.erase(&folder);` **会真的从 `folders` 容器中删除元素**，

- 这时用范围for遍历 `folders`，一边遍历一边删除元素，

- 容器结构被修改，迭代器失效，程序出错。

##### 为啥 `addToFolders` 中不用临时变量存储？

```cpp
void Message::addToFolders() {
    for (auto f : folders)
        save(*f);  // 这会调用 folders.insert(&folder);
}
```

- 这里**插入的元素是 `folders` 已经有的元素**，即插入一个已经存在的元素指针（因为 `f` 本来就来自 `folders`），

- 这样对 `folders` 其实没新增新元素（`set` 插入相同元素不改变容器），

- 所以容器结构不会变化，迭代器没失效，循环安全。

##### 能不能删除 `folders.insert(&folder);`？

- `addToFolders()` 是遍历已有的 `folders`，调用 `save(*f)`，插入的元素是已经在 `folders` 里的，不会真正新增新元素。

- **但调用 `save` 时在别处调用，确实会往 `folders` 加新元素，比如外部调用 `message.save(folder)`。**

- 这时 `folders.insert(&folder)` 是更新这个双向关联的必要步骤。

##### 解决 removeFromFolders 遍历时删除元素的两种方案

方案A：拷贝遍历

```cpp
void Message::removeFromFolders() {
    auto tmp = folders; // 复制一份
    for (auto f : tmp)
        remove(*f);
    folders.clear();
}
```

方案B：用迭代器手动遍历

```cpp
void Message::removeFromFolders() {
    for (auto it = folders.begin(); it != folders.end(); ) {
        auto f = *it;
        ++it;  // 先移动迭代器，避免失效
        remove(*f);
    }
    folders.clear();
}
```

#### Folder.cpp

```cpp
#include "Folder.h"
#include "Message.h"

// 拷贝构造函数
// 复制 messages 集合，然后把自己添加到所有这些消息的 folders 集合中，建立双向关系
Folder::Folder(const Folder& folder) : messages(folder.messages) {
    addToMessages();
}

// 拷贝赋值运算符
// 先断开旧的消息关系，复制 messages 集合，再建立新的关系
Folder& Folder::operator=(const Folder& folder) {
    if (&folder != this) {
        removeFromMessages();     // 断开旧的文件夹-消息关系
        messages = folder.messages;
        addToMessages();          // 建立新的文件夹-消息关系
    }
    return *this;
}

// 析构函数
// 在销毁 Folder 之前，先把自己从所有消息的 folders 集合中移除，断开关联
Folder::~Folder() {
    removeFromMessages();
}

// 保存指定的 Message 到自己（Folder）的 messages 集合中
// 同时把自己插入到该 Message 的 folders 集合中，实现双向关联
void Folder::save(Message& msg) {
    msg.folders.insert(this);    // 消息中加入当前文件夹指针
    messages.insert(&msg);       // 文件夹中加入消息指针
}

// 从自己（Folder）中移除指定的 Message
// 同时把自己从该消息的 folders 集合中移除，断开双向关联
void Folder::remove(Message& msg) {
    msg.folders.erase(this);
    messages.erase(&msg);
}

// 辅助函数：将自己添加到所有 messages 集合中消息的 folders 集合中
// 主要用于拷贝构造和赋值操作后，确保双向关系同步
void Folder::addToMessages() {
    for (auto msg : messages)
        save(*msg);
}

// 辅助函数：从所有 messages 集合中的消息移除自己
// 使用临时集合防止遍历时修改容器导致迭代器失效
void Folder::removeFromMessages() {
    std::set<Message*> tempMessages = messages;  // 备份指针集合，防止迭代器失效
    for (auto msg : tempMessages)
        remove(*msg);
    messages.clear();
}
```

### 测试程序

#### Test.cpp

```cpp
#include <iostream>
#include "Message.h"
#include "Folder.h"

void printFolderMessages(const Folder& folder, const std::string& folderName) {
    std::cout << folderName << " 包含的 Message 地址:\n";
    for (auto msgPtr : folder.messages) {
        std::cout << "  Message 内容: " << msgPtr->contents << " 地址: " << msgPtr << "\n";
    }
}

void printMessageFolders(const Message& msg, const std::string& msgName) {
    std::cout << msgName << " 保存的 Folder 地址:\n";
    for (auto folderPtr : msg.folders) {
        std::cout << "  Folder 地址: " << folderPtr << "\n";
    }
}

int main() {
    Message m1("haha");
    Message m2("xixi");
    Message m3("heihei");

    Folder f1;
    f1.save(m1);
    f1.save(m2);

    Folder f2;
    f2.save(m2);
    f2.save(m3);

    std::cout << "--- 初始状态 ---\n";
    std::cout << "m1 地址: " << &m1 << "\n";
    std::cout << "m2 地址: " << &m2 << "\n";
    std::cout << "m3 地址: " << &m3 << "\n";
    std::cout << "f1 地址: " << &f1 << "\n";
    std::cout << "f2 地址: " << &f2 << "\n";

    printFolderMessages(f1, "f1");
    printFolderMessages(f2, "f2");
    printMessageFolders(m1, "m1");
    printMessageFolders(m2, "m2");
    printMessageFolders(m3, "m3");

    std::cout << "\n--- 拷贝 Folder f1 到 f3 ---\n";
    Folder f3 = f1;
    std::cout << "f3 地址: " << &f3 << "\n";

    printFolderMessages(f3, "f3");
    printMessageFolders(m1, "m1");
    printMessageFolders(m2, "m2");

    std::cout << "\n--- 从 f3 移除 m1 ---\n";
    f3.remove(m1);
    printFolderMessages(f3, "f3");
    printMessageFolders(m1, "m1");

    std::cout << "\n--- 赋值 Folder f3 = f2 ---\n";
    f3 = f2;
    printFolderMessages(f3, "f3");
    printMessageFolders(m2, "m2");

    std::cout << "\n--- 结束程序，触发析构 ---\n";

    return 0;
}
```

#### 输出

```css
--- 初始状态 ---
m1 地址: 0000008DB392F2C0
m2 地址: 0000008DB392F320
m3 地址: 0000008DB392F380
f1 地址: 0000008DB392F3D8
f2 地址: 0000008DB392F408
f1 包含的 Message 地址:
  Message 内容: haha 地址: 0000008DB392F2C0
  Message 内容: xixi 地址: 0000008DB392F320
f2 包含的 Message 地址:
  Message 内容: xixi 地址: 0000008DB392F320
  Message 内容: heihei 地址: 0000008DB392F380
m1 保存的 Folder 地址:
  Folder 地址: 0000008DB392F3D8
m2 保存的 Folder 地址:
  Folder 地址: 0000008DB392F3D8
  Folder 地址: 0000008DB392F408
m3 保存的 Folder 地址:
  Folder 地址: 0000008DB392F408

--- 拷贝 Folder f1 到 f3 ---
f3 地址: 0000008DB392F438
f3 包含的 Message 地址:
  Message 内容: haha 地址: 0000008DB392F2C0
  Message 内容: xixi 地址: 0000008DB392F320
m1 保存的 Folder 地址:
  Folder 地址: 0000008DB392F3D8
  Folder 地址: 0000008DB392F438
m2 保存的 Folder 地址:
  Folder 地址: 0000008DB392F3D8
  Folder 地址: 0000008DB392F408
  Folder 地址: 0000008DB392F438

--- 从 f3 移除 m1 ---
f3 包含的 Message 地址:
  Message 内容: xixi 地址: 0000008DB392F320
m1 保存的 Folder 地址:
  Folder 地址: 0000008DB392F3D8

--- 赋值 Folder f3 = f2 ---
f3 包含的 Message 地址:
  Message 内容: xixi 地址: 0000008DB392F320
  Message 内容: heihei 地址: 0000008DB392F380
m2 保存的 Folder 地址:
  Folder 地址: 0000008DB392F3D8
  Folder 地址: 0000008DB392F408
  Folder 地址: 0000008DB392F438

--- 结束程序，触发析构 ---
```

