---
title: Scanner
date: 2022-03-21 03:35:24 +0800
categories: [java, java basics]
tags: [Java, Scanner]
description: 
---
# Scanner

---

```java
public static void main(String[] args){
    Scanner scanner = new Scanner(System.in);

    if(scanner.hasNextLine()){//判断是否有输入
        String str = scanner.nextLine();//next()读到空格为止
        System.out.println(str);
    }

    scanner.close();
}
```

# 命令行传参

---

```java
public static void main(String[] args) {
    for(int i = 0; i < args.length; i++){
        System.out.println(args[i]);
    }
}
```

# 可变参数

---

```java
public static void main(String[] args) {
    fun(1,1,2,3,4);
}

//一个方法中只能有一个可变参数，必须是方法的最后一个参数
public static void fun(int x, int... i){
    System.out.println(x);
    System.out.println(i[2]);
}
```

# 数组

---

### 内存分析

- 堆
  1. 存放new的对象和数组
  2. 可以被所有的线程共享，不会存放别的对象引用

- 栈
  1. 存放基本类型（会包含这个基本类型的具体数值）
  2. 引用对象的变量（会存放这个引用在堆里面的具体地址）

- 方法区
  1. 可以被所有线程共享
  2. 包含了所有的class和static变量

### 遍历数组

```java
public static void main(String[] args) {
    int[] ary = {1,2,3,4,5};
    //无下标
    for(int i: ary){
        System.out.print(i + " ");
    }
    System.out.println(Arrays.toString(ary));
}
```

### 多维数组

```java
public static void main(String[] args) {
    int[] ary = {1, 2, 3, 2, 5, 9, 7, 4};
    for (int j = 0; j < ary.length - 1; j++) {
        for (int i = 0; i < ary.length - 1; i++) {
            if (ary[i] > ary[i + 1]) {
                int temp = ary[i];
                ary[i] = ary[i + 1];
                ary[i + 1] = temp;
            }
        }
    }
    System.out.println(Arrays.toString(ary));
}
```

