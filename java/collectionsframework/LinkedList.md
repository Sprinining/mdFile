---
title: LinkedList
date: 2024-07-12 05:33:30 +0800
categories: [java, collections framework]
tags: [Java, Collections Framework, LinkedList]
description: 
---
![list-war-2-02](./LinkedList.assets/list-war-2-02.png)

- 静态内部类Node

```java
private static class Node<E> {
    E item;
    // 双向链表
    Node<E> next;
    Node<E> prev;

    Node(Node<E> prev, E element, Node<E> next) {
        this.item = element;
        this.next = next;
        this.prev = prev;
    }
}
```

## 添加元素

```java
public boolean add(E e) {
    linkLast(e);
    return true;
}
```

```java
public void addLast(E e) {
    linkLast(e);
}
```

```java
// 加到末尾
void linkLast(E e) {
    // 获取链表最后的一个节点
    final Node<E> l = last;
    // 创建一个新节点，并把前驱指针指向尾节点，后继指针置空
    final Node<E> newNode = new Node<>(l, e, null);
    // 新节点作为新的尾节点
    last = newNode;
    if (l == null)
        // 如果链表是空的，就把新节点设置为头节点
        first = newNode;
    else
        // 把原来的尾节点的后继指针指向新的尾节点
        l.next = newNode;
    // 链表长加一
    size++;
    modCount++;
}
```

```java
public void addFirst(E e) {
    linkFirst(e);
}
```

```java
// 加到开头
private void linkFirst(E e) {
    final Node<E> f = first;
    final Node<E> newNode = new Node<>(null, e, f);
    first = newNode;
    if (f == null)
        last = newNode;
    else
        f.prev = newNode;
    size++;
    modCount++;
}
```

## 删除元素

- `remove()`：删除第一个节点
- `removeFirst()`：删除第一个节点
- `removeLast()`：删除最后一个节点

```java
public E remove() {
    return removeFirst();
}
```

```java
public E removeFirst() {
    final Node<E> f = first;
    if (f == null)
        throw new NoSuchElementException();
    return unlinkFirst(f);
}
```

```java
// 删除链表的第一个节点，并返回该节点的值
private E unlinkFirst(Node<E> f) {
    // assert f == first && f != null;
    // 获取被删除元素的节点值
    final E element = f.item;
    // 获取被删除元素的后继
    final Node<E> next = f.next;
    // 清空要删除的节点
    f.item = null;
    f.next = null; // help GC
    // 后继节点作为新的头节点
    first = next;
    if (next == null)
        // 没有后继节点，表示链表只有一个元素，把last也置空
        last = null;
    else
        // 后继节点的前驱指针原来是指向被删除的节点，现在置空
        next.prev = null;
    // 表长减一
    size--;
    modCount++;
    // 返回删除节点的值
    return element;
}
```

- `remove(int)`：删除指定位置的节点

```java
public E remove(int index) {
    // 检查越界
    checkElementIndex(index);
    return unlink(node(index));
}

private void checkElementIndex(int index) {
    if (!isElementIndex(index))
        throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
}

private boolean isElementIndex(int index) {
    return index >= 0 && index < size;
}
```

```java
E unlink(Node<E> x) {
    // assert x != null;
    final E element = x.item;
    final Node<E> next = x.next;
    final Node<E> prev = x.prev;

    // 删除的刚好是头节点
    if (prev == null) {
        first = next;
    } else {
        prev.next = next;
        x.prev = null;
    }

    // 删除的刚好是尾节点
    if (next == null) {
        last = prev;
    } else {
        next.prev = prev;
        x.next = null;
    }

    x.item = null;
    size--;
    modCount++;
    return element;
}
```

- `remove(Object)`：删除指定元素的节点

```java
// 先找到节点再调用unlink()
public boolean remove(Object o) {
    if (o == null) {
        for (Node<E> x = first; x != null; x = x.next) {
            // 元素为 null 的时候，必须使用 == 来判断
            if (x.item == null) {
                unlink(x);
                return true;
            }
        }
    } else {
        for (Node<E> x = first; x != null; x = x.next) {
            // 元素为非 null 的时候，要使用 equals 来判断
            if (o.equals(x.item)) {
                unlink(x);
                return true;
            }
        }
    }
    return false;
}
```

## 修改元素

```java
public E set(int index, E element) {
    checkElementIndex(index);
    Node<E> x = node(index);
    E oldVal = x.item;
    // 替换值
    x.item = element;
    // 返回替换前的元素
    return oldVal;
}
```

```java
// 获取链表中指定位置的节点
Node<E> node(int index) {
    // assert isElementIndex(index);

    if (index < (size >> 1)) {
        // 在链表的前半段，就从前往后找
        Node<E> x = first;
        for (int i = 0; i < index; i++)
            x = x.next;
        return x;
    } else {
        // 在链表的后半段，就从后往前找
        Node<E> x = last;
        for (int i = size - 1; i > index; i--)
            x = x.prev;
        return x;
    }
}
```

## 查找元素

- `indexOf(Object)`：查找某个元素所在的位置

```java
// 返回链表中首次出现指定元素的位置，如果不存在该元素则返回 -1
public int indexOf(Object o) {
    int index = 0;
    if (o == null) {
        for (Node<E> x = first; x != null; x = x.next) {
            if (x.item == null)
                return index;
            index++;
        }
    } else {     
        
        for (Node<E> x = first; x != null; x = x.next) {
            if (o.equals(x.item))
                return index;
            index++;
        }
    }
    return -1;
}
```

- `get(int)`：查找某个位置上的元素

```java
public E get(int index) {
    checkElementIndex(index);
    return node(index).item;
}
```

## 序列化

```java
private void writeObject(java.io.ObjectOutputStream s)
    throws java.io.IOException {
    // Write out any hidden serialization magic
    // 写入默认的序列化标记
    s.defaultWriteObject();

    // Write out size
    // 写入链表的节点个数
    s.writeInt(size);

    // Write out all elements in the proper order.
    // 按正确的顺序写入所有元素
    for (Node<E> x = first; x != null; x = x.next)
        s.writeObject(x.item);
}
```

```java
private void readObject(java.io.ObjectInputStream s)
    throws java.io.IOException, ClassNotFoundException {
    // Read in any hidden serialization magic
    // 读取默认的序列化标记
    s.defaultReadObject();

    // Read in size
    // 读取链表的节点个数
    int size = s.readInt();

    // Read in all elements in the proper order.
    for (int i = 0; i < size; i++)
        // 读取元素并将其添加到链表末尾
        linkLast((E)s.readObject());
}
```

- **遍历 LinkedList 的时候，千万不要使用 for 循环，要使用迭代器。**

## 对比ArrayList

- 当需要频繁随机访问元素的时候，例如读取大量数据并进行处理或者需要对数据进行排序或查找的场景，可以使用 ArrayList。

- 当需要频繁插入和删除元素的时候，例如实现队列或栈，或者需要在中间插入或删除元素的场景，可以使用 LinkedList。
