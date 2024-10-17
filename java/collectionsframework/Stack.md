---
title: Stack
date: 2024-07-12 05:44:37 +0800
categories: [java, collections framework]
tags: [Java, Collections Framework, Stack]
description: 
---
- 继承自 `Vector`，是线程安全的
- 在 Java 中，推荐使用 ArrayDeque 来代替 Stack，因为 ArrayDeque 是非线程安全的，性能更好

## push

```java
public E push(E item) {
    addElement(item);

    return item;
}
```

- 调用了 `Vector` 类的 `addElement` 方法，该方法上添加了 `synchronized` 关键字

```java
public synchronized void addElement(E obj) {
    modCount++;
    ensureCapacityHelper(elementCount + 1);
    elementData[elementCount++] = obj;
}
```

## pop

```java
public synchronized E pop() {
    E obj;
    int len = size();

    // 调用 peek 方法获取到栈顶元素
    obj = peek();
    removeElementAt(len - 1);

    return obj;
}
```

- 调用 Vector 类的 removeElementAt 方法移除栈顶元素

```java
public synchronized void removeElementAt(int index) {
    modCount++;
    if (index >= elementCount) {
        throw new ArrayIndexOutOfBoundsException(index + " >= " +
                                                 elementCount);
    }
    else if (index < 0) {
        throw new ArrayIndexOutOfBoundsException(index);
    }
    int j = elementCount - index - 1;
    if (j > 0) {
        // 如果移除的不是栈顶元素，还会调用 System.arraycopy 进行数组的拷贝，因为栈的底层是由数组实现的
        System.arraycopy(elementData, index + 1, elementData, index, j);
    }
    elementCount--;
    elementData[elementCount] = null; /* to let gc do its work */
}
```

```java
public synchronized E peek() {
    int len = size();

    if (len == 0)
        throw new EmptyStackException();
    return elementAt(len - 1);
}
```

