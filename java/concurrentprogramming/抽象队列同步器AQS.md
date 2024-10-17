---
title: 抽象队列同步器AQS
date: 2024-08-13 11:40:40 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, AQS]
description: 
---
**AQS**是`AbstractQueuedSynchronizer`的简称，即`抽象队列同步器`，从字面上可以这样理解:

- 抽象：抽象类，只实现一些主要逻辑，有些方法由子类实现；
- 队列：使用先进先出（FIFO）的队列存储数据；
- 同步：实现了同步的功能。

AQS 是一个用来构建锁和同步器的框架，使用 AQS 能简单且高效地构造出应用广泛的同步器，ReentrantLock，Semaphore，ReentrantReadWriteLock，SynchronousQueue，FutureTask 等等，都是基于 AQS 的。

## AQS 的数据结构

AQS 内部使用了一个 volatile 的变量 state 来作为资源的标识。

```java
private volatile int state;
```

同时定义了几个获取和改变 state 的 protected 方法，子类可以覆盖这些方法来实现自己的逻辑：

```java
getState()
setState()
compareAndSetState()
```

这三种操作均是原子操作，其中 compareAndSetState 的实现依赖于 Unsafe 的 `compareAndSwapInt()` 方法。

AQS 内部使用了一个先进先出（FIFO）的双端队列，并使用了两个引用 head 和 tail 用于标识队列的头部和尾部。其数据结构如下图所示：

![aqs-c294b5e3-69ef-49bb-ac56-f825894746ab](./抽象队列同步器AQS.assets/aqs-c294b5e3-69ef-49bb-ac56-f825894746ab.png)

但它并不直接储存线程，而是储存拥有线程的 Node 节点。

![aqs-20230805211157](./抽象队列同步器AQS.assets/aqs-20230805211157.png)

## AQS 的 Node节点

资源有两种共享模式，或者说两种同步方式：

- `独占模式（Exclusive）`：资源是独占的，一次只能有一个线程获取。如 ReentrantLock。

- `共享模式（Share）`：同时可以被多个线程获取，具体的资源个数可以通过参数指定。如 Semaphore/CountDownLatch。

一般情况下，子类只需要根据需求实现其中一种模式就可以，当然也有同时实现两种模式的同步类，如 ReadWriteLock。

AQS 中关于这两种资源共享模式的定义源码均在内部类 Node 中:

```java
static final class Node {
    // 标记一个结点（对应的线程）在共享模式下等待
    static final Node SHARED = new Node();
    // 标记一个结点（对应的线程）在独占模式下等待
    static final Node EXCLUSIVE = null;

    // waitStatus的值，表示该结点（对应的线程）已被取消。当等待超时或被中断，会触发进入为此状态，进入该状态后节点状态不再变化
    static final int CANCELLED = 1;
    // waitStatus的值，表示后继结点（对应的线程）需要被唤醒
    static final int SIGNAL = -1;
    // waitStatus的值，表示该结点（对应的线程）在等待某一条件。当前线程阻塞在Condition，如果其他线程调用了Condition的signal方法，这个节点将从等待队列转移到同步队列队尾，等待获取同步锁
    static final int CONDITION = -2;
    /*waitStatus的值，表示有资源可用，新head结点需要继续唤醒后继结点（共享模式下，多线程并发释放资源，而head唤醒其后继结点后，需要把多出来的资源留给后面的结点；设置新的head结点时，会继续唤醒其后继结点）*/
    static final int PROPAGATE = -3;

    // 等待状态，取值范围，-3，-2，-1，0，1
    volatile int waitStatus;
    volatile Node prev; // 前驱结点
    volatile Node next; // 后继结点
    volatile Thread thread; // 结点对应的线程
    Node nextWaiter; // 等待队列里下一个等待条件的结点


    // 判断共享模式的方法
    final boolean isShared() {
        return nextWaiter == SHARED;
    }

    Node(Thread thread, Node mode) {     // Used by addWaiter
        this.nextWaiter = mode;
        this.thread = thread;
    }

    // 其它方法忽略，可以参考具体的源码
}

// AQS里面的addWaiter私有方法
private Node addWaiter(Node mode) {
    // 使用了Node的这个构造函数
    Node node = new Node(Thread.currentThread(), mode);
    // 其它代码省略
}
```

通过 Node 我们可以实现两种队列：

1）一是通过 prev 和 next 实现 CLH（Craig, Landin, and Hagersten）队列（线程同步队列、双向队列）。

在 CLH 锁中，每个等待的线程都会有一个关联的 Node，每个 Node 有一个 prev 和 next 指针。当一个线程尝试获取锁并失败时，它会将自己添加到队列的尾部并自旋，等待前一个节点的线程释放锁。类似下面这样。

```java
public class CLHLock {
    private volatile Node tail;
    private ThreadLocal<Node> myNode = ThreadLocal.withInitial(Node::new);
    private ThreadLocal<Node> myPred = new ThreadLocal<>();

    public void lock() {
        Node node = myNode.get();
        node.locked = true;
        // 把自己放到队尾，并取出前面的节点
        Node pred = tail;
        myPred.set(pred);
        while (pred.locked) {
            // 自旋等待
        }
    }

    public void unlock() {
        Node node = myNode.get();
        node.locked = false;
        myNode.set(myPred.get());
    }

    private static class Node {
        private volatile boolean locked;
    }
}
```

2）二是通过 nextWaiter 实现 Condition 上的等待线程队列（单向队列），这个 Condition 主要用在 ReentrantLock 类中。

## AQS 的源码解析

AQS 的设计是基于**模板方法模式**的，它有一些方法必须要子类去实现的，它们主要有：

- `isHeldExclusively()`：该线程是否正在独占资源。只有用到 condition 才需要去实现它。
- `tryAcquire(int)`：独占方式。尝试获取资源，成功则返回 true，失败则返回 false。
- `tryRelease(int)`：独占方式。尝试释放资源，成功则返回 true，失败则返回 false。
- `tryAcquireShared(int)`：共享方式。尝试获取资源。负数表示失败；0 表示成功，但没有剩余可用资源；正数表示成功，且有剩余资源。
- `tryReleaseShared(int)`：共享方式。尝试释放资源，如果释放后允许唤醒后续等待结点返回 true，否则返回 false。

这些方法虽然都是`protected`的，但是它们并没有在 AQS 具体实现，而是直接抛出异常：

```java
protected boolean tryAcquire(int arg) {
    throw new UnsupportedOperationException();
}
```

这里不使用抽象方法的目的是：避免强迫子类中把所有的抽象方法都实现一遍，减少无用功，这样子类只需要实现自己关心的抽象方法即可，比如 信号 Semaphore 只需要实现 tryAcquire 方法而不用实现其余不需要用到的模版方法。

### 获取资源

获取资源的入口是 `acquire(int arg)`方法。arg 是要获取的资源个数，在独占模式下始终为 1。我们先来看看这个方法的逻辑：

```java
public final void accquire(int arg) {
    // tryAcquire 再次尝试获取锁资源，如果尝试成功，返回true，尝试失败返回false
    if (!tryAcquire(arg) &&
        // 走到这，代表获取锁资源失败，需要将当前线程封装成一个Node，追加到AQS的队列中
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        // 线程中断
        selfInterrupt();
}

private Node addWaiter(Node mode) {
 // 创建 Node 类，并且设置 thread 为当前线程，设置为排它锁
 Node node = new Node(Thread.currentThread(), mode);
 // 获取 AQS 中队列的尾部节点
 Node pred = tail;
 // 如果 tail == null，说明是空队列，
 // 不为 null，说明现在队列中有数据，
 if (pred != null) {
  // 将当前节点的 prev 指向刚才的尾部节点，那么当前节点应该设置为尾部节点
  node.prev = pred;
  // CAS 将 tail 节点设置为当前节点
  if (compareAndSetTail(pred, node)) {
   // 将之前尾节点的 next 设置为当前节点
   pred.next = node;
   // 返回当前节点
   return node;
  }
 }
 enq(node);
 return node;
}

// 自旋CAS插入等待队列
private Node enq(final Node node) {
    for (;;) {
        Node t = tail;
        if (t == null) { // Must initialize
            if (compareAndSetHead(new Node()))
                tail = head;
        } else {
            node.prev = t;
            if (compareAndSetTail(t, node)) {
                t.next = node;
                return t;
            }
        }
    }
}

final boolean acquireQueued(final Node node, int arg) {
    boolean failed = true;
    try {
        // interrupted用于记录线程是否被中断过
        boolean interrupted = false;
        for (;;) { // 自旋操作
            // 获取当前节点的前驱节点
            final Node p = node.predecessor();
            // 如果前驱节点是head节点，并且尝试获取同步状态成功
            if (p == head && tryAcquire(arg)) {
                // 设置当前节点为head节点
                setHead(node);
                // 前驱节点的next引用设为null，帮助垃圾回收器回收该节点
                p.next = null; 
                // 获取同步状态成功，将failed设为false
                failed = false;
                // 返回线程是否被中断过
                return interrupted;
            }
            // 如果应该让当前线程阻塞并且线程在阻塞时被中断，则将interrupted设为true
            if (shouldParkAfterFailedAcquire(p, node) && parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        // 如果获取同步状态失败，取消尝试获取同步状态
        if (failed)
            cancelAcquire(node);
    }
}

```

这里 parkAndCheckInterrupt 方法内部使用到了 `LockSupport.park(this)`，顺便简单介绍一下 park 方法。

LockSupport 类是 Java 6 引入的一个类，提供了基本的线程同步原语。LockSupport 实际上是调用了 Unsafe 类里的方法，归结到 Unsafe 里，只有两个：

- `park(boolean isAbsolute, long time)`：阻塞当前线程
- `unpark(Thread jthread)`：使给定的线程停止阻塞

所以**结点进入等待队列后，是调用 park 使它进入阻塞状态的。只有头结点的线程是处于活跃状态的**。

当然，获取资源的方法除了 acquire 外，还有以下三个：

- acquireInterruptibly：申请可中断的资源（独占模式）
- acquireShared：申请共享模式的资源
- acquireSharedInterruptibly：申请可中断的资源（共享模式）

可中断的意思是，在线程中断时可能会抛出`InterruptedException`

总结起来的一个流程图：

![aqs-a0689bb2-9b18-419d-9617-6d292fbd439d](./抽象队列同步器AQS.assets/aqs-a0689bb2-9b18-419d-9617-6d292fbd439d.png)

### 释放资源

```java
public final boolean release(int arg) {
    if (tryRelease(arg)) {
        Node h = head;
        if (h != null && h.waitStatus != 0)
            unparkSuccessor(h);
        return true;
    }
    return false;
}

private void unparkSuccessor(Node node) {
    // 如果状态是负数，尝试把它设置为0
    int ws = node.waitStatus;
    if (ws < 0)
        compareAndSetWaitStatus(node, ws, 0);
    // 得到头结点的后继结点head.next
    Node s = node.next;
    // 如果这个后继结点为空或者状态大于0
    // 通过前面的定义我们知道，大于0只有一种可能，就是这个结点已被取消（只有 Node.CANCELLED(=1) 这一种状态大于0）
    if (s == null || s.waitStatus > 0) {
        s = null;
        // 从尾部开始倒着寻找第一个还未取消的节点（真正的后继者）
        for (Node t = tail; t != null && t != node; t = t.prev)
            if (t.waitStatus <= 0)
                s = t;
    }
    // 如果后继结点不为空，
    if (s != null)
        LockSupport.unpark(s.thread);
}
```

在`java.util.concurrent.locks.ReentrantLock`的实现中，`tryRelease(arg)`会减少持有锁的数量，如果持有锁的数量变为0，释放锁并返回true。

如果`tryRelease(arg)`成功释放了锁，那么接下来会检查队列的头结点。如果头结点存在并且waitStatus不为0（这意味着有线程在等待），那么会调用`unparkSuccessor(Node h)`方法来唤醒等待的线程。

## 自定义同步组件

```java
package org.example;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.AbstractQueuedSynchronizer;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;

// 同一时刻，只允许最多两个线程同时访问，超过两个线程的访问会被阻塞
public class TwinsLock implements Lock {
    private final Sync sync = new Sync(2);

    // 静态内部类，继承同步器并重写指定方法，然后将同步器组合在自定义同步组件的实现中
    private static final class Sync extends AbstractQueuedSynchronizer {
        // count 为临界资源数量
        Sync(int count) {
            if (count <= 0) {
                throw new IllegalArgumentException("临界资源数量必须大于0");
            }
            // 设置同步状态，此处同步状态的值就是临界资源数量
            setState(count);
        }

        // 共享方式获取同步状态，返回值大于等于 0 时，表示线程成功获取同步状态，对于上层的TwinsLock来说表示当前线程获取了锁
        @Override
        protected int tryAcquireShared(int reduceCount) {
            // 先查询当前同步状态并判断是否符合预期，再用CAS设置同步状态
            while (true) {
                // 获取同步状态
                int current = getState();
                int newCount = current - reduceCount;
                // CAS 方式设置同步状态
                if (newCount < 0 || compareAndSetState(current, newCount)) {
                    return newCount;
                }
            }
        }

        // 共享方式释放同步状态
        @Override
        protected boolean tryReleaseShared(int returnCount) {
            while (true) {
                int current = getState();
                int newCount = current + returnCount;
                if (compareAndSetState(current, newCount)) {
                    return true;
                }
            }
        }

    }

    // 以下为 Lock 接口需要重写的方法
    @Override
    public void lock() {
        // 调用同步器提供的模板方法，这些模板方法会调用到上面重写的方法，如 tryAcquireShared、tryReleaseShared
        // 共享方式获取同步状态，获取失败会进入同步队列等待。与独占式获取区别在于同一时刻可以有多个线程获取到同步状态
        sync.acquireShared(1);
    }

    @Override
    public void unlock() {
        // 共享方式释放同步状态
        sync.releaseShared(1);
    }

    @Override
    public void lockInterruptibly() throws InterruptedException {
    }

    @Override
    public boolean tryLock() {
        return false;
    }

    @Override
    public boolean tryLock(long time, TimeUnit unit) throws InterruptedException {
        return false;
    }

    @Override
    public Condition newCondition() {
        return null;
    }
}

class TwinsLockTest {
    public static void main(String[] args) {
        final Lock lock = new TwinsLock();
        class Worker extends Thread {
            @Override
            public void run() {
                while (true) {
                    lock.lock();
                    try {
                        TimeUnit.SECONDS.sleep(1);
                        System.out.println(Thread.currentThread().getName());
                        TimeUnit.SECONDS.sleep(1);
                    } catch (InterruptedException e) {
                        throw new RuntimeException(e);
                    } finally {
                        lock.unlock();
                    }
                }
            }
        }

        for (int i = 0; i < 10; i++) {
            Worker w = new Worker();
            w.setDaemon(true);
            w.start();
        }

        for (int i = 0; i < 10; i++) {
            try {
                TimeUnit.SECONDS.sleep(1);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
            System.out.println();
        }
    }
}
```
