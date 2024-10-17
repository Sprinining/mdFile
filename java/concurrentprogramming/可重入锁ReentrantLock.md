---
title: 可重入锁ReentrantLock
date: 2024-07-23 02:17:47 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, Lock, JUC]
description: 
---
ReentrantLock 重入锁，是实现Lock 接口 的一个类，也是在实际编程中使用频率很高的一个锁，**支持重入性，表示能够对共享资源重复加锁，即当前线程获取该锁后再次获取不会被阻塞**。

要想支持重入性，就要解决两个问题：

1. 在线程获取锁的时候，如果已经获取锁的线程是当前线程的话则直接再次获取成功；
2. 由于锁会被获取 n 次，那么只有锁在被释放同样的 n 次之后，该锁才算是完全释放成功。

## ReentrantLock 源码分析

```java
// 内部类 Sync 的 nonfairTryAcquire 方法
// 每次重新获取都会对同步状态进行加一的操作
final boolean nonfairTryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    // 1. 如果该锁未被任何线程占有，该锁能被当前线程获取
	if (c == 0) {
        if (compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }
	// 2.若被占有，检查占有线程是否是当前线程
    else if (current == getExclusiveOwnerThread()) {
		// 3. 再次获取，计数加一
        int nextc = c + acquires;
        if (nextc < 0) // overflow
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}
```

```java
// 内部类 Sync 的 tryRelease 方法
// 重入锁的释放必须得等到同步状态为 0 时锁才算成功释放
protected final boolean tryRelease(int releases) {
	//1. 同步状态减1
    int c = getState() - releases;
    if (Thread.currentThread() != getExclusiveOwnerThread())
        throw new IllegalMonitorStateException();
    boolean free = false;
    if (c == 0) {
		//2. 只有当同步状态为0时，锁成功被释放，返回true
        free = true;
        setExclusiveOwnerThread(null);
    }
	// 3. 锁未被完全释放，返回false
    setState(c);
    return free;
}
```

ReentrantLock 支持两种锁：**公平锁**和**非公平锁**。**何谓公平性，是针对获取锁而言的，如果一个锁是公平的，那么锁的获取顺序就应该符合请求上的绝对时间顺序，满足 FIFO**。

```java
// ReentrantLock 的构造方法无参时是构造非公平锁
public ReentrantLock() {
    sync = new NonfairSync();
}
// 可传入一个 boolean 值，true 时为公平锁，false 时为非公平锁
public ReentrantLock(boolean fair) {
    sync = fair ? new FairSync() : new NonfairSync();
}
```

在非公平锁获取时（nonfairTryAcquire 方法），只是简单的获取了一下当前状态然后做了一些逻辑处理，并没有考虑到当前同步队列中线程等待的情况。

公平锁的处理逻辑:

```java
protected final boolean tryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    if (c == 0) {
        // 增加了 hasQueuedPredecessors
        if (!hasQueuedPredecessors() &&
            compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {
        int nextc = c + acquires;
        if (nextc < 0)
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}
```

代码的逻辑与 nonfairTryAcquire 基本上一致，唯一的不同在于增加了 hasQueuedPredecessors 的逻辑判断，从方法名就可以知道该方法用来判断当前节点在同步队列中是否有前驱节点的，如果有前驱节点，说明有线程比当前线程更早的请求资源，根据公平性，当前线程请求资源失败。如果当前节点没有前驱节点，才有做后面逻辑判断的必要性。

**公平锁每次都是让同步队列中的第一个节点获取到锁，而非公平性锁则不一定，有可能刚释放锁的线程能再次获取到锁**。

## ReentrantLock 使用

```java
public class ReentrantLockTest {
    private static final ReentrantLock lock = new ReentrantLock();
    private static int count = 0;

    public static void main(String[] args) throws InterruptedException {
        Thread thread1 = new Thread(() -> {
            for (int i = 0; i < 10000; i++) {
                // 当前线程获取该锁后再次获取不会被阻塞
                lock.lock();
                try {
                    count++;
                } finally {
                    lock.unlock();
                }
            }
        });
        Thread thread2 = new Thread(() -> {
            for (int i = 0; i < 10000; i++) {
                // 锁必须在 try 代码块开始之前获取，并且加锁之前不能有异常抛出，否则在 finally 块中就无法释放锁（ReentrantLock 的锁必须在 finally 中手动释放）。
                lock.lock();
                try {
                    count++;
                } finally {
                    lock.unlock();
                }
            }
        });
        thread1.start();
        thread2.start();
        thread1.join();
        thread2.join();
        System.out.println(count);
    }
}
```

## ReentrantLock 与 synchronized

- ReentrantLock 是一个类，而 synchronized 是 Java 中的关键字；

- ReentrantLock 可以实现多路选择通知（可以绑定多个 Condition)），而 synchronized 只能通过 wait 和 notify/notifyAll 方法唤醒一个线程或者唤醒全部线程（单路通知）；

- ReentrantLock 必须手动释放锁。通常需要在 finally 块中调用 unlock 方法以确保锁被正确释放。

- synchronized 会自动释放锁，当同步块执行完毕时，由 JVM 自动释放，不需要手动操作。

- ReentrantLock: 通常提供更好的性能，特别是在高竞争环境下。

- synchronized: 在某些情况下，性能可能稍差一些，但随着 JDK 版本的升级，性能差距已经不大了。
