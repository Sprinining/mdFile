---
title: StringBuffer和StringBuilder
date: 2024-07-14 12:04:06 +0800
categories: [java, string]
tags: [Java, String, StringBuffer, StringBuilder]
description: 
---
```java
public final class StringBuffer extends AbstractStringBuilder implements Serializable, CharSequence {

    public StringBuffer() {
        super(16);
    }
    
    public synchronized StringBuffer append(String str) {
        super.append(str);
        return this;
    }

    public synchronized String toString() {
        return new String(value, 0, count);
    }

    // 其他方法
}
```

```java
public final class StringBuilder extends AbstractStringBuilder
    implements java.io.Serializable, CharSequence
{
    // ...

    public StringBuilder append(String str) {
        super.append(str);
        return this;
    }

    public String toString() {
        // Create a copy, don't share the array
        return new String(value, 0, count);
    }

    // ...
}
```

- StringBuffer 操作字符串的方法加了 `synchronized` 关键字进行了同步，主要是考虑到多线程环境下的安全问题，所以如果在非多线程环境下，执行效率就会比较低

- StringBuilder 除了类名不同，方法没有加 synchronized，基本上完全一样
- StringBuilder的toString()

```java
// 使用 value 数组中从 0 开始的前 count 个元素创建一个新的字符串对象，并将其返回
public String toString() {
    return new String(value, 0, count);
}
```

- StringBuilder的append()

```java
public StringBuilder append(String str) {
    // 调用 AbstractStringBuilder 中的 append(String str) 方法
    super.append(str);
    return this;
}
```

```java
public AbstractStringBuilder append(String str) {
    if (str == null)
        // 当做字符串“null”来处理
        return appendNull();
    int len = str.length();
    // 判断扩容
    ensureCapacityInternal(count + len);
    str.getChars(0, len, value, count);
    count += len;
    return this;
}

private AbstractStringBuilder appendNull() {
    int c = count;
    ensureCapacityInternal(c + 4);
    final char[] value = this.value;
    value[c++] = 'n';
    value[c++] = 'u';
    value[c++] = 'l';
    value[c++] = 'l';
    count = c;
    return this;
}

private void ensureCapacityInternal(int minimumCapacity) {
    if (minimumCapacity - value.length > 0)
        // 扩容
        expandCapacity(minimumCapacity);
}

void expandCapacity(int minimumCapacity) {
    // 新容量为旧容量的两倍加上 2
    int newCapacity = value.length * 2 + 2;
    // 如果新容量小于指定的最小容量，则新容量为指定的最小容量
    if (newCapacity - minimumCapacity < 0)
        newCapacity = minimumCapacity;
    // 如果新容量小于 0，则新容量为 Integer.MAX_VALUE
    if (newCapacity < 0) {
        if (minimumCapacity < 0) // overflow
            throw new OutOfMemoryError();
        newCapacity = Integer.MAX_VALUE;
    }
    // 将字符序列的容量扩容到新容量的大小
    value = Arrays.copyOf(value, newCapacity);
}
```

- StringBuilder的reverse()

```java
public StringBuilder reverse() {
    // 调用了父类 AbstractStringBuilder 中的 reverse() 方法
    super.reverse();
    return this;
}
```

```java
public AbstractStringBuilder reverse() {
    boolean hasSurrogates = false;
    // 字符序列的最后一个字符的索引
    int n = count - 1;
    // 遍历字符串的前半部分
    for (int j = (n-1) >> 1; j >= 0; j--) {
        // 计算相对于 j 对称的字符的索引
        int k = n - j;
        // 获取当前位置的字符
        char cj = value[j];
        // 获取对称位置的字符
        char ck = value[k];
        // 交换字符
        value[j] = ck;
        value[k] = cj;
        if (Character.isSurrogate(cj) ||
            Character.isSurrogate(ck)) {
            hasSurrogates = true;
        }
    }
    if (hasSurrogates) {
        reverseAllValidSurrogatePairs();
    }
    return this;
}
```

