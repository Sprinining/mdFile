---
title: CopyOnWriteArrayList
date: 2024-07-29 10:26:17 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, JUC, CopyOnWriteArrayList]
description: 
---
ArrayList 是一个线程不安全的容器，如果在多线程环境下使用，需要手动加锁，或者使用 `Collections.synchronizedList()` 方法将其转换为线程安全的容器。否则，将会出现 ConcurrentModificationException 异常。

CopyOnWriteArrayList 是线程安全的，可以在多线程环境下使用。CopyOnWriteArrayList 遵循写时复制的原则，每当对列表进行修改（例如添加、删除或更改元素）时，都会创建列表的一个新副本，这个新副本会替换旧的列表，而对旧列表的所有读取操作仍然可以继续。

由于在修改时创建了新的副本，所以读取操作不需要锁定。这使得在多读取者和少写入者的情况下读取操作非常高效。当然，由于每次写操作都会创建一个新的数组副本，所以会增加存储和时间的开销。如果写操作非常频繁，性能会受到影响。

CopyOnWriteArrayList 适用于读操作远远大于写操作的场景，比如说缓存。因为 CopyOnWriteArrayList 采用写时复制的思想，所以写操作的性能较低，因此不适合写操作频繁的场景。

## 什么是 CopyOnWrite

------

读写锁 ReentrantReadWriteLock 是通过读写分离的思想来实现的，即读写锁将读写操作分别加锁，从而实现读写操作的并发执行。

但是，读写锁也存在一些问题，比如说在写锁执行后，读线程会被阻塞，直到写锁被释放后读线程才有机会获取到锁从而读到最新的数据，站在**读线程的角度来看，读线程在任何时候都能获取到最新的数据，满足数据实时性**。

而 CopyOnWriteArrayList 是通过 Copy-On-Write(COW)，即写时复制的思想来通过延时更新的策略实现数据的最终一致性，并且能够保证读线程间不阻塞。当然，**这要牺牲数据的实时性**。

通俗的讲，CopyOnWrite 就是当我们往一个容器添加元素的时候，不直接往容器中添加，而是先复制出一个新的容器，然后在新的容器里添加元素，添加完之后，再将原容器的引用指向新的容器。多个线程在读的时候，不需要加锁，因为当前容器不会添加任何元素。

## CopyOnWriteArrayList 原理

------

CopyOnWriteArrayList 内部维护的就是一个数组，被 volatile 修饰，能够保证数据的内存可见性。：

```java
/** The array, accessed only via getArray/setArray. */
private transient volatile Object[] array;
```

### get 方法

```java
public E get(int index) {
    return get(getArray(), index);
}
/**
 * Gets the array.  Non-private so as to also be accessible
 * from CopyOnWriteArraySet class.
 */
final Object[] getArray() {
    return array;
}
private E get(Object[] a, int index) {
    return (E) a[index];
}
```

get 方法的实现非常简单，没有添加任何的线程安全控制，没有加锁也没有 CAS 操作，原因就是所有的读线程只会读取容器中的数据，并不会进行修改。

### add 方法

```java
public boolean add(E e) {
    final ReentrantLock lock = this.lock;
    // 使用Lock,保证写线程在同一时刻只有一个
    lock.lock();
    try {
        // 获取旧数组引用
        Object[] elements = getArray();
        int len = elements.length;
        // 创建新的数组，并将旧数组的数据复制到新数组中
        Object[] newElements = Arrays.copyOf(elements, len + 1);
        // 往新数组中添加新的数据
        newElements[len] = e;
        // 将旧数组引用指向新的数组
        setArray(newElements);
        return true;
    } finally {
        lock.unlock();
    }
}

// 根据 volatile 的 happens-before 规则，所以这个更改对所有线程是立即可见的
final void setArray(Object[] a) {
    array = a;
}
```

## CopyOnWriteArrayList 的缺点

------

CopyOnWrite 容器有很多优点，但是同时也存在两个问题，即内存占用问题和数据一致性问题。

- **内存占用问题**：因为 CopyOnWrite 的写时复制机制，在进行写操作的时候，内存里会同时有两个对象，旧的对象和新写入的对象。

- **数据一致性问题**：CopyOnWrite 容器只能保证数据的==最终一致性==，不能保证数据的==实时一致性==。所以如果你希望写入的的数据，马上能读到，请不要使用 CopyOnWrite 容器，最好通过 ReentrantReadWriteLock 自定义一个的列表。

对比 CopyOnWrite 和读写锁。

相同点：

- 两者都是通过读写分离的思想来实现的；

- 读线程间是互不阻塞的

不同点：

- 为了实现数据实时性，在写锁被获取后，读线程会阻塞；或者当读锁被获取后，写线程会阻塞，从而解决“脏读”的问题。而 CopyOnWrite 对数据的更新是写时复制的，因此读线程是延时感知的，但不会存在阻塞的情况。
