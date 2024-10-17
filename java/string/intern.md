---
title: intern
date: 2024-07-14 11:08:48 +0800
categories: [java, string]
tags: [Java, String]
description: 
---
- 当调用 intern() 方法时，如果字符串池中已经存在相同内容的字符串，则返回字符串池中的引用；否则，将该字符串添加到字符串池中，并返回对字符串池中的新引用。可以确保所有具有相同内容的字符串共享相同的内存空间
- 对于任意两个字符串 s 和 t，当且仅当 s.equals(t) 为 true 时，s.intern() == t.intern() 才为 true。

```java
public static void main(String[] args) {
    // 字符串常量池和堆中各创建一个对象，返回堆中对象的引用
    String s1 = new String("hh");
    // 返回的是字符串常量池中的引用
    String s2 = s1.intern();
    // false
    System.out.println(s1 == s2);
}
```

```java
public static void main(String[] args) {
    // 字符串常量池中创建两个对象hh和xixi；堆中创建两个匿名对象hh和xixi，外加一个hhxixi的对象，返回的就是这个堆中的hhxixi对象
    String s1 = new String("hh") + new String("xixi");
    // 先从字符串常量池中查找hhxixi是否存在
    // 此时不存在的，但堆中已经存在了，所以字符串常量池中保存的是堆中这个hhxixi对象的引用
    String s2 = s1.intern();
    // true
    System.out.println(s1 == s2);
}
```

- 当编译器遇到 `+` 号这个操作符的时候，会将 `new String("hh") + new String("xixi")` 这行代码编译为以下代码：

```java
new StringBuilder().append("hh").append("xixi").toString();
```

