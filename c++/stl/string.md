---
title: string
date: 2024-08-28 04:57:05 +0800
categories: [c++]
tags: [C++]
description: 
---
 ## string

string 作为类出现，其集成的操作函数足以完成多数情况下的需要。可以使用 "=" 进行赋值，使用 "==" 进行等值比较，使用 "+" 做串联。

要使用 string 类，必须包含头文件 `<string>`。在 STL 库中，basic_string 有两个预定义类型：包含 char 的 string 类型和包含 wchar 的 wstring 类型。

```c++
int main() {
    string stuff;
    // 从屏幕读入输入的字符串
    cin >> stuff;
    // 或者 getline(cin, stuff);
}
```

### 成员函数

在定义 string 类对象时，string 类自身可以管理内存，程序员不必关注内存的分配细节。

string 类提供的各种操作函数大致分为八类：构造器和析构器、大小和容量、元素存取、字 符串比较、字符串修改、字符串接合、I/O 操作以及搜索和查找。

|              函数名称               |             功能             |
| :---------------------------------: | :--------------------------: |
|              构造函数               |       产生或复制字符串       |
|              析构函数               |          销毁字符串          |
|              =，assign              |           赋以新值           |
|              `swap()`               |     交换两个字符串的内容     |
|   + =，`append()`，`push_back()`    |           添加字符           |
|             `insert ()`             |           插入字符           |
|              `erase()`              |           删除字符           |
|              `clear()`              |         移除全部字符         |
|             `resize()`              |         改变字符数量         |
|             `replace()`             |           替换字符           |
|                  +                  |          串联字符串          |
| ==，！ =，<，<=，>，>=，`compare()` |        比较字符串内容        |
|        `size()`，`length()`         |         返回字符数量         |
|            `max_size()`             |    返回字符的最大可能个数    |
|              `empty()`              |      判断字符串是否为空      |
|            `capacity()`             |  返回重新分配之前的字符容量  |
|             `reserve()`             | 保留内存以存储一定数量的字符 |
|              [],`at()`              |         存取单一字符         |
|           >>，`getline()`           |     从 stream 中读取某值     |
|                 <<                  |       将值写入 stream        |
|              `copy()`               | 将内容复制为一个 C - string  |
|              `c_str()`              | 将内容以 C - string 形式返回 |
|              `data()`               |   将内容以字符数组形式返回   |
|             `substr()`              |         返回子字符串         |
|              `find()`               |     搜寻某子字符串或字符     |
|         `begin()`，`end()`          |      提供正向迭代器支持      |
|        `rbegin()`，`rend()`         |      提供逆向迭代器支持      |
|          `get_allocator()`          |          返回配置器          |

### 构造函数

```c++
int main() {
    // 生成空字符串
    string str;
    str = "hello";
    // 生成字符串str的复制品
    string s1(str);
    // 将字符串 str 中始于下标 2 的部分作为构造函数的初值
    string s2(str, 2);
    // 将字符串 str 中始于下标 1、长度为 2 的部分作为字符串初值
    string s3(str, 1, 2);
    // 以 C_string 类型作为字符串s的初值
    string s4("C_string");
    // 以 C_string 类型的前 2 个字符串作为字符串s的初值
    string s5("C_string", 2);
    // 生成一个字符串，包含 6 个 c 字符
    string s6(6, 'c');
    //以区间 [1, 2] 内的字符作为字符串s的初值
    string s7("hello", 1, 2);
    
    // 只包含一个字符
    string s8(1, 'x');
    string s9("x");
    // 错误：string s10('x');
}
```

C_string 一般被认为是常规的 C++字符串。目前，在 C++ 中确实存在一个从 const char * 到 string 的隐式型别转换，却不存在从 string 对象到 C_string 的自动型别转换。对于 string 类型的字符串，可以通过 c_str() 函数返回该 string 类对象对应的 C_string。

程序员在整个程序中应坚持使用 string 类对象，直到必须将内容转化为 char* 时才将其转换为 C_string。

### compare()

类 basic_string 的成员函数 compare() 的原型如下：

```c++
int compare(const basic_string &s) const;
int compare(const Ch *p) const;
int compare(size_type pos, size_type n, const basic_string &s) const;
int compare(size_type pos, size_type n, const basic_string &s, size_type pos2, size_type n2) const;
int compare(size_type pos, size_type n, const Ch *p, size_type = npos) const;
```

如果在使用 compare() 函数时，参数中出现了位置和大小，比较时只能用指定的子串。例如：

```c++
s.compare {pos,n, s2);
```

若参与比较的两个串值相同，则函数返回 0；若字符串 S 按字典顺序要先于 S2，则返回负值；反之，则返回正值。

在使用时比较运算符时，包括 >、<、==、>=、<=、!=，对于参加比较的两个字符串，任一个字符串均不能为 `NULL`，否则程序会异常退出。

### 修改

可以通过使用多个函数修改字符串的值。例如 `assign()`，operator=，`erase()`，交换（swap），插入（insert）等。另外，还可通过 `append()` 函数添加字符。

```c++
int main() {
    string str1("123456");
    string str2("abcdefghijklmn");
    string str;

    // 赋值全部
    str.assign(str1);
    // 赋值子串
    str.assign(str1, 3, 3);
    // 赋值从位置 2 至末尾的子串
    str.assign(str1, 2, string::npos);
    // 重复 5 个'X'字符
    str.assign(5, 'X');
    //从第 1 个至倒数第 2 个元素，赋值给字符串 str
    auto itB = begin(str1);
    auto itE = end(str1);
    str.assign(itB, (--itE));


    str = str1;
    // 抹除下标 2 到结尾的字符
    str.erase(2);
    // 抹除开头到结尾
    str.erase(str.begin(), str.end());
    // 交换
    str.swap(str2);

    string A("ello");
    string B("H");
    // 字符串插入到下标 1 的位置，B: Hello
    B.insert(1, A);

    B = 'H';
    // 字符串前 3 个插入到下标 1 的位置，B: Habc
    B.insert(1, "abcde ", 3);

    A = "ello";
    B = "H";
    // 字符串A从下标 2 开始的 2 个字符插入到B下标 1 的位置，B: Hlo
    B.insert(1, A, 2, 2);

    B = "H";
    // 下标 1 处插入 5 个 C，Ｂ：HCCCCC
    B.insert(1, 5, 'C');

    A = "ello";
    B = "H";
    auto it = B.begin() + 1;
    auto itF = begin(A);
    auto itG = end(A);
    // B: Hello
    B.insert(it, itF, itG);

    A = "ello";
    B = "H";
    // 追加，B: Hello
    B.append(A);

    B = "H";
    // 追加前两个字符，B: H12
    B.append("12345", 2);

    B = "H";
    // 追加下标 2 开始的 3 个字符，B: H345
    B.append("12345", 2, 3);

    B = "H";
    // 追加下标 5 个 a，B: Haaaaa
    B.append(5, 'a');

    A = "ello";
    B = "H";
    // 追加范围，B: Hello
    B.append(A.begin(), A.end());
    cout << "append: " << B << endl;
    return 0;
}
```

### 替换

```c++
int main() {
    string var("abcdefghijklmn");
    const string dest("1234");
    string dest2("567891234");

    // var: abc1234ghijklmn
    var.replace(3, 3, dest);

    var = "abcdefghijklmn";
    // var: abc234efghijklmn
    var.replace(3, 1, dest.c_str(), 1, 3);

    var = "abcdefghijklmn";
    // var: abcxxxxxefghijklmn
    var.replace(3, 1, 5, 'x');

    string::iterator itA, itB;
    string::iterator itC, itD;
    itA = var.begin();
    itB = var.end();
    var = "abcdefghijklmn";
    // var: 1234
    var.replace(itA, itB, dest);

    itA = var.begin();
    itB = var.end();
    itC = dest2.begin() + 1;
    itD = dest2.end();
    var = "abodefghijklmn";
    // var: 67891234efghijklmn
    var.replace(itA, itB, itC, itD);

    var = "abcdefghijklmn";

    // var: abc1234efghijklmn
    // 这种方式会限定字符串替换的最大长度
    var.replace(3, 1, dest.c_str(), 4);
    return 0;
}
```

### 输入输出

"<<" 和 ">>" 提供了 C++ 语言的字符串输入和字符串输出功能。"<<" 可以将字符读入一个流中（例如 ostream）；">>" 可以实现将以==空格或回车==为 "结束符" 的字符序列读入到对应的字符串中，并且开头和结尾的空白字符==不包括==进字符串中。

```c++
int main() {
    string s1, s2;
    // 该函数可将整行的所有字符读到字符串中。
    // 在读取字符时，遇到文件结束符、分界符、回车符时，将终止读入操作，且文件结束符、分界符、回车符在字符串中不会保存；
    // 当已读入的字符数目超过字符串所能容纳的最大字符数时，将会终止读入操作。
    // 第 1 个参数是输入流；第 2 个参数是保存输入内容的字符串
    getline(cin, s1);
    // 第 1 个参数是输入流，第 2 个参数保存输入的字符串，第 3 个参数指定分界符。
    getline(cin, s2, '$');
}
```

### 字符串查找

若查找 `find()` 函数和其他函数没有搜索到期望的字符（或子串），则返回 `npos`；若搜索成功，则返回搜索到的第 1  个字符或子串的位置。其中，`npos` 是一个无符号整数值，初始值为 -1。当搜索失败时， `npos` 表示“没有找到（not  found）”或“所有剩佘字符”。

所有查找 `find()` 函数的返回值均是 `size_type` 类型，即无符号整数类型。该返回值用于表明字符串中元素的个数或者字符在字符串中的位置。

#### find()函数和 rfind()

`find()` 函数的原型主要有以下 4 种：

```c++
// find()函数的第1个参数是被搜索的字符、第2个参数是在源串中开始搜索的下标位置
size_type find(value_type _Chr, size_type _Off = 0) const;
// find()函数的第1个参数是被搜索的字符串，第2个参数是在源串中开始搜索的下标位置
size_type find(const value_type *_Ptr, size_type _Off = 0) const;
// 第1个参数是被搜索的字符串，第2个参数是源串中开始搜索的下标，第3个参数是关于第1个参数的字符个数，可能是 _Ptr 的所有字符数，也可能是 _Ptr 的子串宇符个数
size_type find(const value_type *_Ptr, size_type _Off = 0, size_type _Count) const;
// 第1个参数是被搜索的字符串，第2参数是在源串中开始搜索的下标位置
size_type find(const basic_string &_Str, size_type _Off = 0) const;
```

`rfind()` 函数的原型和 `find()` 函数的原型类似，参数情况也类似。只不过 `rfind()` 函数适用于实现逆向查找。

```c++
int main() {
    string str("0123for789abcfor");
    int len = str.length();
    cout << endl << str.find('2', 0);// 2
    cout << endl << str.rfind('c', len - 1);// 12
    cout << endl << str.find("for", 0);// 4
    cout << endl << str.rfind("for", len - 1);// 13
}
```

#### find_first_of()函数和 find_last_of()函数

`find_first_of()` 函数可实现在源串中搜索某字符串的功能，该函数的返回值是==被搜索字符串==的==第 1 个字符第 1 次出现的下标==（位置）。若查找失败，则返回 `npos`。

`find_last_of()` 函数同样可实现在源串中搜索某字符串的功能。与 `find_first_of()` 函数所不同的是，该函数的返回值是被搜索字符串的最后 1 个字符的下标（位置）。若查找失败，则返回 `npos`。

#### find_first_not_of()函数和 find_last_not_of()函数

`find_first_not_of()` 函数可实现在源字符串中搜索与指定字符（串）不相等的第 1 个字符；`find_last_not_of()`  函数可实现在源字符串中搜索与指定字符（串）不相等的最后 1 个字符。这两个函数的参数意义和前面几个函数相同，它们的使用方法和前面几个函数也基本相同。
