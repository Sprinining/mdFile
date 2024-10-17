---
title: Comparator和Comparable
date: 2024-07-13 11:16:06 +0800
categories: [java, collections framework]
tags: [Java, Collections Framework, Comparator, Comparable]
description: 
---
## Comparable

- 实现了 Comparable 接口，重写 `compareTo()` 方法，就可以按照自己制定的规则将由它创建的对象进行比较

```java
public interface Comparable<T> {
    // 返回值可能为负数，零或者正数，代表的意思是该对象按照排序的规则小于、等于或者大于要比较的对象
    int compareTo(T t);
}
```

```java
class CSer implements Comparable<CSer> {
    private int mvp;

    public CSer(int mvp) {
        this.mvp = mvp;
    }

    @Override
    public int compareTo(CSer o) {
        return this.mvp - o.mvp;
    }
}
```

## Comparator

```java
public interface Comparator<T> {
    int compare(T o1, T o2);
    // 判断该 Object 是否和 Comparator 保持一致
    boolean equals(Object obj);
    ...
}
```

```java
class CSer {
    private int mvp;

    public CSer(int mvp) {
        this.mvp = mvp;
    }

    public int getMvp() {
        return mvp;
    }
}

class CSerComparator implements Comparator<CSer> {

    @Override
    public int compare(CSer o1, CSer o2) {
        return o1.getMvp() - o2.getMvp();
    }
}

public class Test {
    public static void main(String[] args) {
        CSer niko = new CSer(3);
        CSer s1mple = new CSer(5);
        CSer dev1ce = new CSer(4);

        List<CSer> list = new ArrayList<>();
        list.add(niko);
        list.add(s1mple);
        list.add(dev1ce);

        list.sort(new CSerComparator());
        for (CSer cSer : list) {
            System.out.println(cSer.getMvp());
        }
    }
}
```

- ArrayList的sort源码

```java
public void sort(Comparator<? super E> c) {
    // 保存当前队列的 modCount 值，用于检测 sort 操作是否非法
    final int expectedModCount = modCount;
    // 调用 Arrays.sort 对 elementData 数组进行排序，使用传入的比较器 c
    Arrays.sort((E[]) elementData, 0, size, c);
    // 检查操作期间 modCount 是否被修改，如果被修改则抛出并发修改异常
    if (modCount != expectedModCount) {
        throw new ConcurrentModificationException();
    }
    // 增加 modCount 值，表示队列已经被修改过
    modCount++;
}
```

## 使用选择

- 一个类实现了 Comparable 接口，意味着该类的对象可以直接进行比较（排序），但比较（排序）的方式只有一种，很单一。
- 一个类如果想要保持原样，又需要进行不同方式的比较（排序），就可以定制比较器（实现 Comparator 接口）。

- 如果对象的排序需要基于自然顺序，选择 `Comparable`，如果需要按照对象的不同属性进行排序，选择 `Comparator`。
