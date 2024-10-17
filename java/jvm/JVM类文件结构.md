---
title: JVM类文件结构
date: 2024-07-15 02:45:18 +0800
categories: [java, jvm]
tags: [Java, JVM, Class]
description: 
---
- .java源文件

```java
package test.JVM;

public class Test {
    public static void main(String[] args) {
        System.out.println("haha");
    }
}
```

- 十六进制查看.class文件

![image-20240714192257451](./JVM类文件结构.assets/image-20240714192257451.png)

## 魔数

------

第一行中有一串特殊的字符 `CAFEBABE`，它就是一个魔数，是 JVM 识别 class 文件的标志，JVM 会在验证阶段检查 class 文件是否以该魔数开头，如果不是则会抛出 `ClassFormatError`。

## 版本号

------

紧跟着魔数后面的四个字节 `0000 0034` 分别表示副版本号和主版本号。也就是说，主版本号为 52（0x34 的十进制），也就是 Java 8 对应的版本号，副版本号为 0。

## 常量池

------

紧跟在版本号之后的是常量池，它包含了类、接口、字段和方法的符号引用，以及字符串字面量和数值常量。这些信息在编译时被创建，并在运行时被Java虚拟机（JVM）使用。

在Java类文件中，是一个索引表，它从索引值1开始计数，每个条目都有一个唯一的索引。

- 常量池计数器：在常量池之前，类文件有一个16位的常量池计数器，表示常量池中有多少项。它的值比实际常量数大1（因为索引从1开始）。
- 常量池条目：每个常量池条目的开始是一个标签（1个字节），表明了常量的类型（如Class、Fieldref、Methodref等）。根据这个类型，后面跟着的数据结构也不同。

常量池相当于一个资源仓库，主要存放量大类型常量：

- 字面量（Literals）：字面量是不变的数据，主要包括数值（如整数、浮点数）和字符串字面量。例如，一个整数100或一个字符串"Hello World"，在源代码中直接赋值，编译后存储在常量池中。
- 符号引用（Symbolic References）：符号引用是对类、接口、字段、方法等的引用，它们不是由字面量值给出的，而是通过符号名称（如类名、方法名）和其他额外信息（如类型、签名）来表示。这些引用在类文件中以一种抽象的方式存在，它们在类加载时被虚拟机解析为具体的内存地址。

```java
public class ConstantTest {
    public final boolean bool = true;
    public final char aChar = 'a';
    public final byte b = 66;
    public final short s = 67;
    public final int i = 68;
    public final long ong = Long.MAX_VALUE;
    public final String str = "hello";
}
```

- Java 定义了 boolean、byte、short、char 和 int 等基本数据类型，它们在常量池中都会被当做 int 来处理。
1. 第一个字节 0x03 表示常量的类型为 CONSTANT_Integer_info

| 常量类型              | 标识符 | 描述符            |
| :-------------------- | :----- | :---------------- |
| CONSTANT_Integer_info | 0x03   | int 类型字面量    |
| CONSTANT_Float_info   | 0x04   | float 类型字面量  |
| CONSTANT_Long_info    | 0x05   | long 类型字面量   |
| CONSTANT_Double_info  | 0x06   | double 类型字面量 |

![image-20240715101944225](./JVM类文件结构.assets/image-20240715101944225.png)

| 常量类型                         | 标识符 | 描述符             |
| :------------------------------- | :----- | :----------------- |
| CONSTANT_MethodHandle_info       | 0x0f   | 方法句柄           |
| CONSTANT_MethodType_info         | 0x10   | 方法类型           |
| CONSTANT_InvokeDynamic_info      | 0x12   | 动态调用点         |
| CONSTANT_Fieldref_info           | 0x09   | 字段               |
| CONSTANT_Methodref_info          | 0x0a   | 普通方法           |
| CONSTANT_InterfaceMethodref_info | 0x0b   | 接口方法           |
| CONSTANT_Class_info              | 0x07   | 类或接口的全限定名 |
| CONSTANT_String_info             | 0x08   | 字符串字面量       |
| CONSTANT_Uft8_info               | 0x01   | 字符串             |

2. 以 0x05 开头表示常量的类型为 CONSTANT_Long_info，Long.MAX_VALUE十六进制就是0x7FFFFFFF

![image-20240715101830357](./JVM类文件结构.assets/image-20240715101830357.png)

3. 以 0x01 开头表示 CONSTANT_Utf8_info，后两个字节0x0005表示数组长度为5，==存储了字符串真正的值==

![image-20240715102322663](./JVM类文件结构.assets/image-20240715102322663.png)

<img src="./JVM类文件结构.assets/class-file-jiegou-ae4f38c9-68fe-40ad-91c6-3e7fd360de05.png" alt="class-file-jiegou-ae4f38c9-68fe-40ad-91c6-3e7fd360de05" style="zoom: 50%;" />

4. 以 0x08 开头表示 CONSTANT_String_info，表示字符串对象的引用，==仅仅包含了一个指向常量池中 CONSTANT_Uft8_info 的索引==，0x0034为索引，十进制是52， 通过索引 52 来找到 CONSTANT_Uft8_info。

![image-20240715110208718](./JVM类文件结构.assets/image-20240715110208718.png)

![image-20240715110537785](./JVM类文件结构.assets/image-20240715110537785.png)

4. CONSTANT_Class_info，用来表示类和接口，和 CONSTANT_String_info 类似，第一个字节是标识，值为 0x07，后面两个字节是常量池索引，指向 CONSTANT_Utf8_info——字符串存储的是类或者接口的全路径限定名。索引为 13 的 CONSTANT_Class_info 指向的是是索引为 54 的 CONSTANT_Uft8_info，值为`test/JVM/ConstantTest`，十六进制是746573742f4a564d2f436f6e7374616e7454657374

![image-20240715110915048](./JVM类文件结构.assets/image-20240715110915048.png)

![image-20240715110926932](./JVM类文件结构.assets/image-20240715110926932.png)

- 52的十六进制为0x36，CONSTANT_Class_info标识为0x07，就可以查找0x070036找到 CONSTANT_Class_info 在 class 文件中的位置了。

![image-20240715112124031](./JVM类文件结构.assets/image-20240715112124031.png)

5. CONSTANT_NameAndType_info，用来标识字段或方法，标识符为 12，对应的十六进制是 0x0c。后面还有 4 个字节，前两个是字段或者方法的索引，后两个是字段或方法的描述符，也就是字段或者方法的类型

```java
class Dog {
    public void bark(int times, String name) {
    }
}
```

- 用 jclasslib 可以看到 CONSTANT_NameAndType_info 包含的索引有两个

![image-20240715112723577](./JVM类文件结构.assets/image-20240715112723577.png)

<img src="./JVM类文件结构.assets/class-file-jiegou-ae4f38c9-68fe-40ad-91c6-3e7fd360de05-1721014104764-22.png" alt="class-file-jiegou-ae4f38c9-68fe-40ad-91c6-3e7fd360de05" style="zoom:50%;" />

- 在class文件中位置如下

![image-20240715112948241](./JVM类文件结构.assets/image-20240715112948241.png)

6. CONSTANT_MethodType_info，用来标识字段或方法，标识符为 0x0a。后面还有 4 个字节，前两个是CONSTANT_Class_info 的常量池索引，后两个是CONSTANT_NameAndType_info 的常量池索引

![image-20240715114228284](./JVM类文件结构.assets/image-20240715114228284.png)

![image-20240715114248411](./JVM类文件结构.assets/image-20240715114248411.png)

![image-20240715114305476](./JVM类文件结构.assets/image-20240715114305476.png)

## 访问标记

------

- 紧跟着常量池之后的区域就是访问标记（Access flags），这个标记用于识别类或接口的访问信息。总共有 16 个标记位可供使用，但常用的只有其中 7 个。==左边是低位，右边是高位==

![class-file-jiegou-1f5d3154-9a28-4cfa-935e-43d7e023036e](./JVM类文件结构.assets/class-file-jiegou-1f5d3154-9a28-4cfa-935e-43d7e023036e.png)

- 枚举，访问标记的信息为 `0x4031 [public final enum]`。`0x4031`的二进制为`0100 0000 0011 0001B`

```java
public enum Color {
    RED,GREEN,BLUE;
}
```

![image-20240715114733657](./JVM类文件结构.assets/image-20240715114733657.png)

![image-20240715115542281](./JVM类文件结构.assets/image-20240715115542281.png)

## 类索引、父类索引和接口索引

------

- 这三部分用来确定类的继承关系

```java
class Animal{}

interface Fly{}

class Bird extends Animal implements Fly{}
```

![image-20240715115953035](./JVM类文件结构.assets/image-20240715115953035.png)

- this_class 指向常量池中索引为 2 的 CONSTANT_Class_info。
- super_class 指向常量池中索引为 3 的 CONSTANT_Class_info。
- 有一个接口，所以 interfaces 的信息为1。

![image-20240715120220289](./JVM类文件结构.assets/image-20240715120220289.png)

## 字段表

------

- 一个类中定义的字段会被存储在字段表（fields）中，包括静态的和非静态的

```java
public class Test {
    private String name;
}
```

![image-20240715123508225](./JVM类文件结构.assets/image-20240715123508225.png)

![image-20240715123620847](./JVM类文件结构.assets/image-20240715123620847.png)

- field由三部分组成，按顺序分别是：
  - 1. 字段的访问标记：比如说是不是 public | private | protected，是不是 static，是不是 final 等。此例中为`0x0002`
  - 2. 字段名的索引：指向常量池中的 CONSTANT_Utf8_info。此例中为`0x0004`
  - 3. 字段的描述类型索引：指向常量池中的 CONSTANT_Utf8_info。此例中为`0x0005`

- ==表示方式==
  - 对于基本数据类型来说，使用一个字符来表示，比如说 I 对应的是 int，B 对应的是 byte。
  - 对于引用数据类型来说，使用 `L***;` 的方式来表示，`L` 开头，`;` 结束，比如字符串类型为 `Ljava/lang/String;`。
  - 对于数组来说，会用一个前置的 `[` 来表示，比如说字符串数组为 `[Ljava/lang/String;`。

## 方法表

------

- 方法表和字段表类似，区别是用来存储方法的信息，包括方法名，方法的参数，方法的签名

```java
public class Test {
    public static void main(String[] args) {
    }
}
```

![image-20240715124037253](./JVM类文件结构.assets/image-20240715124037253.png)

- 访问标记是 public static 的。此例中为`0x0009`
- 方法名为 main。指向常量池中的 CONSTANT_Utf8_info。此例中为`0x000B`
- 方法的参数为字符串数组；返回类型为 Void。指向常量池中的 CONSTANT_Utf8_info。此例中为`0x000C`

![image-20240715124336894](./JVM类文件结构.assets/image-20240715124336894.png)

## 属性表

------

- 属性表是 class 文件中的最后一部分，通常出现在字段和方法中。

```java
public class Test {
    public static final int DEFAULT_SIZE = 128;
}
```

- ConstantValue，用来表示静态变量的初始值

![image-20240715124902313](./JVM类文件结构.assets/image-20240715124902313.png)

![image-20240715124911596](./JVM类文件结构.assets/image-20240715124911596.png)

- 属性名索引指向常量池中值为“ConstantValue”的常量。
- 属性长度的值为固定的 2，因为索引只占两个字节的大小。
- 常量值索引指向常量池中具体的常量，如果常量类型为 int，指向的就是 CONSTANT_Integer_info。
