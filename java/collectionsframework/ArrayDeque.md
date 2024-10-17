---
title: ArrayDeque
date: 2024-07-13 09:27:36 +0800
categories: [java, collections framework]
tags: [Java, Collections Framework, ArrayDeque]
description: 
---
- ArrayDeque 又实现了 Deque 接口（Deque 又实现了 Queue 接口）

```java
public class ArrayDeque<E> extends AbstractCollection<E>
                           implements Deque<E>, Cloneable, Serializable
{}
```

- *Deque*与*Queue*相对应的接口

| Queue Method | Equivalent Deque Method | 说明                                   |
| ------------ | ----------------------- | -------------------------------------- |
| add(e)       | addLast(e)              | 向队尾插入元素，失败则抛出异常         |
| offer(e)     | offerLast(e)            | 向队尾插入元素，失败则返回`false`      |
| remove()     | removeFirst()           | 获取并删除队首元素，失败则抛出异常     |
| poll()       | pollFirst()             | 获取并删除队首元素，失败则返回`null`   |
| element()    | getFirst()              | 获取但不删除队首元素，失败则抛出异常   |
| peek()       | peekFirst()             | 获取但不删除队首元素，失败则返回`null` |

- *Deque*与*Stack*对应的接口

| Stack Method | Equivalent Deque Method | 说明                                   |
| ------------ | ----------------------- | -------------------------------------- |
| push(e)      | addFirst(e)             | 向栈顶插入元素，失败则抛出异常         |
| 无           | offerFirst(e)           | 向栈顶插入元素，失败则返回`false`      |
| pop()        | removeFirst()           | 获取并删除栈顶元素，失败则抛出异常     |
| 无           | pollFirst()             | 获取并删除栈顶元素，失败则返回`null`   |
| peek()       | getFirst()              | 获取但不删除栈顶元素，失败则抛出异常   |
| 无           | peekFirst()             | 获取但不删除栈顶元素，失败则返回`null` |

- 添加，删除，取值都有两套接口，它们功能相同，区别是对失败情况的处理不同。一套接口遇到失败就会抛出异常，另一套遇到失败会返回特殊值（`false`或`null`）。

- *ArrayDeque*是非线程安全的（not thread-safe），当多个线程同时使用的时候，需要手动同步；另外，该容器不允许放入`null`元素。

## addFirst()

```java
// elements.length必需是2的指数倍
public void addFirst(E e) {
    // 不允许放入null
    if (e == null)
        throw new NullPointerException();
    // elements - 1就是二进制低位全1，跟head - 1相与之后就起到了取模的作用
    elements[head = (head - 1) & (elements.length - 1)] = e;
    // 判断循环数组是否已经满
    if (head == tail)
        // 扩容
        doubleCapacity();
}

private void doubleCapacity() {
    // 检查 head 和 tail 是否相等，如果不相等则抛出异常
    assert head == tail;
    int p = head;
    int n = elements.length;
    // head右边元素的个数
    int r = n - p; // number of elements to the right of p
    // 原空间的2倍
    int newCapacity = n << 1;
    if (newCapacity < 0)
        throw new IllegalStateException("Sorry, deque too big");
    Object[] a = new Object[newCapacity];
    // 复制右半部分
    System.arraycopy(elements, p, a, 0, r);
    // 复制左半部分
    System.arraycopy(elements, 0, a, r, p);
    // 由于 elements 数组被替换为 a 数组，因此在方法调用结束后，原有的 elements 数组将不再被引用，会被垃圾回收器回收
    elements = a;
    head = 0;
    tail = n;
}
```

- 当b是2的n次方时，`a & (b - 1) = a % b`，`head & (elements.length - 1)` 等价于 `head % elements.length`

## addLast()

```java
public void addLast(E e) {
    if (e == null)
        throw new NullPointerException();
    elements[tail] = e;
    if ((tail = (tail + 1) & (elements.length - 1)) == head)
        doubleCapacity();
}
```

## pollFirst()

- `pollFirst()`的作用是删除并返回*Deque*首端元素，也即是`head`位置处的元素。如果容器不空，只需要直接返回`elements[head]`即可，当然还需要处理下标的问题。由于`ArrayDeque`中不允许放入`null`，当`elements[head] == null`时，意味着容器为空。

```java
public E pollFirst() {
    int h = head;
    @SuppressWarnings("unchecked")
    E result = (E) elements[h];
    // Element is null if deque empty
    // null值意味着deque为空
    if (result == null)
        return null;
    elements[h] = null;     // Must null out slot
    head = (h + 1) & (elements.length - 1);
    return result;
}
```

## pollLast()

```java
// 删除并返回*Deque*尾端元素，也即是`tail`位置前面的那个元素。
public E pollLast() {
    int t = (tail - 1) & (elements.length - 1);
    @SuppressWarnings("unchecked")
    E result = (E) elements[t];
    if (result == null)
        return null;
    elements[t] = null;
    tail = t;
    return result;
}
```

## peekFirst()

```java
// 返回但不删除Deque首端元素，也即是head位置处的元素，直接返回elements[head]即可。
public E peekFirst() {
    // elements[head] is null if deque empty
    return (E) elements[head];
}
```

## peekLast()

```java
// 返回但不删除Deque尾端元素，也即是tail位置前面的那个元素。
public E peekLast() {
    return (E) elements[(tail - 1) & (elements.length - 1)];
}
```
