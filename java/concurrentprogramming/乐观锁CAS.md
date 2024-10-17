---
title: 乐观锁CAS
date: 2024-07-19 07:05:40 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, CAS]
description: 
---
在 Java 中，我们可以使用 [synchronized](https://javabetter.cn/thread/synchronized-1.html)

关键字和 `CAS` 来实现加锁效果。

悲观锁：

- 对于悲观锁来说，它总是认为每次访问共享资源时会发生冲突，所以必须对每次数据操作加上锁，以保证临界区的程序同一时间只能有一个线程在执行。

- `synchronized` 是悲观锁，尽管随着 JDK 版本的升级，synchronized 关键字已经“轻量级”了很多，但依然是悲观锁，线程开始执行第一步就要获取锁，一旦获得锁，其他的线程进入后就会阻塞并等待锁。
- 悲观锁多用于`写多读少`的环境，避免频繁失败和重试影响性能。

乐观锁：

- 乐观锁总是假设对共享资源的访问没有冲突，线程可以不停地执行，无需加锁也无需等待。一旦多个线程发生冲突，乐观锁通常使用一种称为 CAS 的技术来保证线程执行的安全性。
- `CAS` 是乐观锁，线程执行的时候不会加锁，它会假设此时没有冲突，然后完成某项操作；如果因为冲突失败了就重试，直到成功为止。
- 由于乐观锁假想操作中没有锁的存在，因此不太可能出现死锁的情况，换句话说，**乐观锁天生免疫死锁**。
- 乐观锁多用于`读多写少`的环境，避免频繁加锁影响性能。

## 什么是 CAS

------

在 CAS 中，有这样三个值：

- V：要更新的变量(var)
- E：预期值(expected)，本质上指的是“旧值”
- N：新值(new)

比较并交换的过程如下：

判断 V 是否等于 E，如果等于，将 V 的值设置为 N；如果不等，说明已经有其它线程更新了 V，于是当前线程放弃更新，什么都不做。

CAS 是一种原子操作，它是一种系统原语，是一条 CPU 的原子指令，从 CPU 层面已经保证它的原子性。

**当多个线程同时使用 CAS 操作一个变量时，只有一个会胜出，并成功更新，其余均会失败，但失败的线程并不会被挂起，仅是被告知失败，并且允许再次尝试，当然也允许失败的线程放弃操作。**

## CAS 的原理

------

在 Java 中，有一个`Unsafe`类，它在`sun.misc`包中。它里面都是一些`native`方法，其中就有几个是关于 CAS 的：

```java
boolean compareAndSwapObject(Object o, long offset,Object expected, Object x);
boolean compareAndSwapInt(Object o, long offset,int expected,int x);
boolean compareAndSwapLong(Object o, long offset,long expected,long x);
```

Unsafe 对 CAS 的实现是通过 C++ 实现的，它的具体实现和操作系统、CPU 都有关系。

Linux 的 X86 下主要是通过`cmpxchgl`这个指令在 CPU 上完成 CAS 操作的，但在多处理器情况下，必须使用`lock`指令加锁来完成。当然，不同的操作系统和处理器在实现方式上肯定会有所不同。

> CMPXCHG是“Compare and  Exchange”的缩写，它是一种原子指令，用于在多核/多线程环境中安全地修改共享数据。CMPXCHG在很多现代微处理器体系结构中都有，例如Intel x86/x64体系。对于32位操作数，这个指令通常写作CMPXCHG，而在64位操作数中，它被称为CMPXCHG8B或CMPXCHG16B。

除了上面提到的方法，Unsafe 里面还有其它的方法。比如支持线程挂起和恢复的`park`和`unpark` 方法，LockSupport底层就调用了这两个方法。还有支持[反射](https://javabetter.cn/basic-extra-meal/fanshe.html)操作的`allocateInstance()`方法。

## CAS 如何实现原子操作

------

JDK 提供了一些用于原子操作的类，在`java.util.concurrent.atomic`包下面。

以`AtomicInteger`类的`getAndAdd(int delta)`方法为例：

```java
private static final Unsafe unsafe = Unsafe.getUnsafe();

public final int getAndAdd(int delta) {
    // 调用的 Unsafe 类的方法
    return unsafe.getAndAddInt(this, valueOffset, delta);
}
```

```java
// var1：想要进行操作的对象。
// var2：要操作的 var1 对象中的某个字段的偏移量。这个偏移量可以通过 Unsafe 类的 objectFieldOffset 方法获得。
// var4：要增加的值。
public final int getAndAddInt(Object var1, long var2, int var4) {
    int var5;
    do {
        // 获取当前对象指定字段的值
        // getIntVolatile 方法能保证读操作的可见性，即读取的结果是最新的写入结果，不会因为 JVM 的优化策略（如指令重排序）或者 CPU 的缓存导致读取到过期的数据
        var5 = this.getIntVolatile(var1, var2);
        // 如果对象 var1 在内存地址 var2 处的值等于预期值 var5，则将该位置的值更新为 var5 + var4，并返回 true；否则，不做任何操作并返回 false。
    } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));

    return var5;
}
```

- Object var1：想要进行操作的对象。
- long var2：要操作的 var1 对象中的某个字段的偏移量。这个偏移量可以通过 Unsafe 类的 objectFieldOffset 方法获得。
- int var4：要增加的值。

JDK 9 及其以后版本中，getAndAddInt 方法和 JDK 8 中的实现有所不同，我们就拿 JDK 11 的源码来做一个对比吧：

```java
@HotSpotIntrinsicCandidate
public final int getAndAddInt(Object o, long offset, int delta) {
    int v;
    do {
        v = getIntVolatile(o, offset);
    } while (!weakCompareAndSetInt(o, offset, v, v + delta));
    return v;
}
```

这个方法上面增加了 `@HotSpotIntrinsicCandidate` 注解。这个注解允许 HotSpot VM 自己来写汇编或 IR 编译器来实现该方法以提供更加的性能。

> IR（Intermediate Representation）是一种用于帮助优化编译器的中间代码表示方法。编译器通常将源代码首先转化为 IR，然后对 IR  进行各种优化，最后将优化后的 IR 转化为目标代码。在 JVM（Java Virtual  Machine）中，JIT（Just-In-Time）编译器将 Java 字节码（即.class 文件的内容）转化为 IR，然后对 IR  进行优化，最后将 IR 编译为机器码。这个过程在 Java 程序运行时进行，因此被称为“即时编译”。JVM 中的 C1 和 C2 编译器就是  IR 编译器。C1 编译器在编译时进行一些简单的优化，然后快速地将 IR 编译为机器码。C2  编译器在编译时进行更深入的优化，以获得更高的执行效率，但编译的时间也相对更长。

也就是说，虽然表面上看到的是 weakCompareAndSet 和 compareAndSet，但是不排除 HotSpot VM 会手动来实现 weakCompareAndSet 真正功能的可能性。

简单来说，`weakCompareAndSet` 操作仅保留了`volatile` 自身变量的特性，而除去了 happens-before 规则带来的内存语义。换句话说，`weakCompareAndSet`**无法保证处理操作目标的 volatile 变量外的其他变量的执行顺序（编译器和处理器为了优化程序性能而对指令序列进行重新排序），同时也无法保证这些变量的可见性。** 但这在一定程度上可以提高性能。

## CAS 的三大问题

------

### ABA 问题

所谓的 ABA 问题，就是一个值原来是 A，变成了 B，又变回了 A。这个时候使用 CAS 是检查不出变化的，但实际上却被更新了两次。

ABA 问题的解决思路是在变量前面追加上**版本号或者时间戳**。从 JDK 1.5 开始，JDK 的 atomic 包里提供了一个类`AtomicStampedReference`类来解决 ABA 问题。

```java
// 这个类的compareAndSet方法的作用是首先检查当前引用是否等于预期引用，并且检查当前标志是否等于预期标志，如果二者都相等，才使用 CAS 设置为新的值和标志。
public boolean compareAndSet(V   expectedReference,// 预期引用，也就是认为原本应该在那个位置的引用
                              V   newReference,// 新引用，如果预期引用正确，将被设置到该位置的新引用。
                              int expectedStamp,// 预期标记
                              int newStamp) {// 新标记
    Pair<V> current = pair;
    return
        expectedReference == current.reference &&
        expectedStamp == current.stamp &&
        ((newReference == current.reference &&
          newStamp == current.stamp) ||
          casPair(current, Pair.of(newReference, newStamp)));
}
```

执行流程：

①、`Pair<V> current = pair;` 这行代码获取当前的 pair 对象，其中包含了引用和标记。

②、接下来的 return 语句做了几个检查：

- `expectedReference == current.reference && expectedStamp == current.stamp`：首先检查当前的引用和标记是否和预期的引用和标记相同。如果二者中有任何一个不同，这个方法就会返回 false。
- 如果上述检查通过，也就是说当前的引用和标记与预期的相同，那么接下来就会检查新的引用和标记是否也与当前的相同。如果相同，那么实际上没有必要做任何改变，这个方法就会返回 true。
- 如果新的引用或者标记与当前的不同，那么就会调用 casPair 方法来尝试更新 pair 对象。casPair 方法会尝试用 newReference 和 newStamp 创建的新的  Pair 对象替换当前的 pair 对象。如果替换成功，casPair 方法会返回 true；如果替换失败（也就是说在尝试替换的过程中，pair 对象已经被其他线程改变了），casPair 方法会返回 false。

### 长时间自旋

CAS 多与自旋结合。如果自旋 CAS 长时间不成功，会占用大量的 CPU 资源。

解决思路是让 JVM 支持处理器提供的 `pause` 指令。

pause 指令能让自旋失败时 cpu 睡眠一小段时间再继续自旋，从而使得读操作的频率降低很多，为解决内存顺序冲突而导致的 CPU 流水线重排的代价也会小很多。

### 多个共享变量的原子操作

当对一个共享变量执行操作时，CAS 能够保证该变量的原子性。但是对于多个共享变量，CAS 就无法保证操作的原子性，这时通常有两种做法：

1. 使用`AtomicReference`类保证对象之间的原子性，把多个变量放到一个对象里面进行 CAS 操作；
2. 使用锁。锁内的临界区代码可以保证只有当前线程能操作。

