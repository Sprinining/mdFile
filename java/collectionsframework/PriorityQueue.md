---
title: PriorityQueue
date: 2024-07-13 09:48:58 +0800
categories: [java, collections framework]
tags: [Java, Collections Framework, PriorityQueue]
description: 
---
- PriorityQueue 是 Java 中的一个基于优先级堆的优先队列实现，它能够在 O(log n) 的时间复杂度内实现元素的插入和删除操作，并且能够自动维护队列中元素的优先级顺序。

```java
// 传入比较器
PriorityQueue<String> priorityQueue = new PriorityQueue<>(Comparator.reverseOrder());
```

## add()和 offer()

- 前者在插入失败时抛出异常，后则则会返回`false`

```java
public boolean add(E e) {
    return offer(e);
}
```

```java
public boolean offer(E e) {
    // 不允许放入null元素
    if (e == null)
        throw new NullPointerException();
    modCount++;
    int i = size;
    if (i >= queue.length)
        // 扩容
        grow(i + 1);
    size = i + 1;
    if (i == 0)
        // 插入的是第一个元素
        queue[0] = e;
    else
        // 调整
        siftUp(i, e);
    return true;
}
```

```java
// 向上调整
private void siftUp(int k, E x) {
    if (comparator != null)
        siftUpUsingComparator(k, x);
    else
        siftUpComparable(k, x);
}

private void siftUpUsingComparator(int k, E x) {
    while (k > 0) {
        int parent = (k - 1) >>> 1;
        Object e = queue[parent];
        if (comparator.compare(x, (E) e) >= 0)
            break;
        queue[k] = e;
        k = parent;
    }
    queue[k] = x;
}

private void siftUpComparable(int k, E x) {
    Comparable<? super E> key = (Comparable<? super E>) x;
    while (k > 0) {
        int parent = (k - 1) >>> 1;
        Object e = queue[parent];
        if (key.compareTo((E) e) >= 0)
            break;
        queue[k] = e;
        k = parent;
    }
    queue[k] = key;
}
```

- 新加入的元素都是先插入到堆的末尾，也就是堆的最右下角，然后开始向上调整到合适的位置

##  element()和 peek()

- 都是获取但不删除队首元素，前者当方法失败时前者抛出异常，后者返回`null`

```java
public E peek() {
    return (size == 0) ? null : (E) queue[0];
}
```

```java
// PriorityQueue调用的是父类AbstractQueue中的element()
public E element() {
    E x = peek();
    if (x != null)
        return x;
    else
        throw new NoSuchElementException();
}
```

## remove()和 poll()

- 获取并删除队首元素，区别是当方法失败时前者抛出异常，后者返回`null`

```java
public E poll() {
    if (size == 0)
        return null;
    int s = --size;
    modCount++;
    E result = (E) queue[0];
    E x = (E) queue[s];
    queue[s] = null;
    if (s != 0)
        siftDown(0, x);
    return result;
}
```

```java
private void siftDown(int k, E x) {
    if (comparator != null)
        siftDownUsingComparator(k, x);
    else
        siftDownComparable(k, x);
}

@SuppressWarnings("unchecked")
private void siftDownComparable(int k, E x) {
    Comparable<? super E> key = (Comparable<? super E>)x;
    int half = size >>> 1;        // loop while a non-leaf
    while (k < half) {
        int child = (k << 1) + 1; // assume left child is least
        Object c = queue[child];
        int right = child + 1;
        if (right < size &&
            ((Comparable<? super E>) c).compareTo((E) queue[right]) > 0)
            c = queue[child = right];
        if (key.compareTo((E) c) <= 0)
            break;
        queue[k] = c;
        k = child;
    }
    queue[k] = key;
}

@SuppressWarnings("unchecked")
private void siftDownUsingComparator(int k, E x) {
    int half = size >>> 1;
    while (k < half) {
        // 左孩子下标
        int child = (k << 1) + 1;
        Object c = queue[child];
        // 右孩子下标
        int right = child + 1;
        if (right < size &&
            comparator.compare((E) c, (E) queue[right]) > 0)
            c = queue[child = right];
        if (comparator.compare(x, (E) c) <= 0)
            break;
        queue[k] = c;
        k = child;
    }
    queue[k] = x;
}
```

- 删除堆顶元素，用堆中最后一个元素顶替堆顶，然后把新的堆顶与左右孩子比较，向下调整

## remove(Object o)

```java
public boolean remove(Object o) {
    int i = indexOf(o);
    if (i == -1)
        return false;
    else {
        removeAt(i);
        return true;
    }
}

private int indexOf(Object o) {
    if (o != null) {
        for (int i = 0; i < size; i++)
            if (o.equals(queue[i]))
                return i;
    }
    return -1;
}

private E removeAt(int i) {
    // assert i >= 0 && i < size;
    modCount++;
    int s = --size;
    if (s == i) // removed last element
        queue[i] = null;
    else {
        E moved = (E) queue[s];
        queue[s] = null;
        siftDown(i, moved);
        if (queue[i] == moved) {
            siftUp(i, moved);
            if (queue[i] != moved)
                return moved;
        }
    }
    return null;
}
```

