---
title: LinkedHashMap
date: 2024-07-13 09:53:55 +0800
categories: [java, collections framework]
tags: [Java, Collections Framework, LinkedHashMap]
description: 
---
- HashMap 是无序的，LinkedHashMap 是可以维持插入顺序的
- LinkedHashMap 继承了 HashMap，内部追加了双向链表，来维护元素的插入顺序

```java
// LinkedHashMap.Entry 继承了 HashMap.Node
static class Entry<K,V> extends HashMap.Node<K,V> {
    // 并追加了连个字段 before 和 after，用来维持键值对的关系。
    Entry<K,V> before, after;
    Entry(int hash, K key, V value, Node<K,V> next) {
        super(hash, key, value, next);
    }
}
```

## 插入顺序

- LinkedHashMap 并未重写 HashMap 的 `put()` 方法，而是重写了 `put()` 方法需要调用的内部方法 `newNode()`。

```java
Node<K,V> newNode(int hash, K key, V value, Node<K,V> e) {
    LinkedHashMap.Entry<K,V> p =
        new LinkedHashMap.Entry<K,V>(hash, key, value, e);
    linkNodeLast(p);
    return p;
}
```

- 在 LinkedHashMap 中，链表中的节点顺序是按照插入顺序维护的。当使用 put() 方法向 LinkedHashMap 中添加键值对时，会将新节点插入到链表的尾部，并更新 before 和 after 属性，以保证链表的顺序关系

```java
private void linkNodeLast(LinkedHashMap.Entry<K,V> p) {
    LinkedHashMap.Entry<K,V> last = tail;
    tail = p;
    if (last == null)
        head = p;
    else {
        p.before = last;
        last.after = p;
    }
}
```

## 访问顺序

- 要维护访问顺序，需要我们在声明 LinkedHashMap 的时候指定三个参数

```java
// 第三个参数如果为 true 的话，就表示 LinkedHashMap 要维护访问顺序
LinkedHashMap<String, String> map = new LinkedHashMap<>(16, .75f, true);
```

- get()后会调用afterNodeAcess()

```java
public V get(Object key) {
    Node<K,V> e;
    if ((e = getNode(hash(key), key)) == null)
        return null;
    if (accessOrder)
        afterNodeAccess(e);
    return e.value;
}
```

```java
// true 表示访问顺序，false 表示插入顺序
final boolean accessOrder;

// 把刚访问的节点移动到链表的尾部
void afterNodeAccess(Node<K,V> e) { // move node to last
    LinkedHashMap.Entry<K,V> last;
    // 按访问顺序排序，并且访问的节点不是尾节点
    if (accessOrder && (last = tail) != e) {
        LinkedHashMap.Entry<K,V> p =
            (LinkedHashMap.Entry<K,V>)e, b = p.before, a = p.after;
        p.after = null;
        if (b == null)
            head = a;
        else
            b.after = a;
        if (a != null)
            a.before = b;
        else
            last = b;
        if (last == null)
            head = p;
        else {
            p.before = last;
            last.after = p;
        }
        tail = p;
        ++modCount;
    }
}
```

- LinkedHashMap的put调用的是父类HashMap的put方法，HashMap的put方法会调用putVal方法，其中会调用afterNodeAccess和afterNodeInsertion

```java
// 在插入节点后，如果需要，可能会删除最早加入的元素
// evict 是否需要删除最早加入的元素
void afterNodeInsertion(boolean evict) { // possibly remove eldest
    LinkedHashMap.Entry<K,V> first;
    // removeEldestEntry() 方法会判断第一个元素是否超出了可容纳的最大范围，如果超出，那就会调用 removeNode() 方法对最不经常访问的那个元素进行删除。
    if (evict && (first = head) != null && removeEldestEntry(first)) {
        K key = first.key;
        removeNode(hash(key), key, null, false, true);
    }
}
```

```java
void afterNodeRemoval(Node<K,V> e) { // unlink
    LinkedHashMap.Entry<K,V> p =
        (LinkedHashMap.Entry<K,V>)e, b = p.before, a = p.after;
    p.before = p.after = null;
    if (b == null)
        head = a;
    else
        b.after = a;
    if (a == null)
        tail = b;
    else
        a.before = b;
}
```

- LinkedHashMap 继承自 HashMap，它在 HashMap 的基础上，增加了一个双向链表来维护键值对的顺序。这个链表可以按照插入顺序或访问顺序排序，它的头节点表示最早插入或访问的元素，尾节点表示最晚插入或访问的元素。这个链表的作用就是让 LinkedHashMap 可以保持键值对的顺序，并且可以按照顺序遍历键值对。

- LinkedHashMap 还提供了两个构造方法来指定排序方式，分别是按照插入顺序排序和按照访问顺序排序。在按照访问顺序排序的情况下，每次访问一个键值对，都会将该键值对移到链表的尾部，以保证最近访问的元素在最后面。如果需要删除最早加入的元素，可以通过重写 removeEldestEntry() 方法来实现。
