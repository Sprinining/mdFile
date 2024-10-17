---
title: volatile关键字
date: 2024-07-19 12:39:45 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, Volatile]
description: 
---
`volatile` 可以保证可见性，但不保证原子性：

- 当写一个 volatile 变量时，JMM 会把该线程在本地内存中的变量强制刷新到主内存中去；
- 这个写操作会导致其他线程中的 volatile 变量缓存无效。

## volatile 会禁止指令重排

重排序需要遵守的规则：

- 重排序不会对存在数据依赖关系的操作进行重排序。比如：`a=1;b=a;` 这个指令序列，因为第二个操作依赖于第一个操作，所以在编译时和处理器运行时这两个操作不会被重排序。
- 重排序是为了优化性能，但是不管怎么重排序，单线程下程序的执行结果不能被改变。比如：`a=1;b=2;c=a+b` 这三个操作，第一步 (a=1) 和第二步 (b=2) 由于不存在数据依赖关系，所以可能会发生重排序，但是 c=a+b 这个操作是不会被重排序的，因为需要保证最终的结果一定是 c=a+b=3。

当使用 volatile 关键字来修饰一个变量时，Java 内存模型会插入`内存屏障`（一个处理器指令，可以对 CPU 或编译器重排序做出约束）来确保以下两点：

- `写屏障（Write Barrier）`：当一个 volatile 变量被写入时，写屏障确保在该屏障之前的所有变量的写入操作都提交到主内存。
- `读屏障（Read Barrier）`：当读取一个 volatile 变量时，读屏障确保在该屏障之后的所有读操作都从主内存中读取。

换句话说：

- 当程序执行到 volatile 变量的读操作或者写操作时，在其前面操作的更改肯定已经全部进行，且结果对后面的操作可见；在其后面的操作肯定还没有进行；
- 在进行指令优化时，不能将 volatile 变量的语句放在其后面执行，也不能把 volatile 变量后面的语句放到其前面执行。

也就是说，执行到 volatile 变量时，其前面的所有语句都必须执行完，后面所有得语句都未执行。且前面语句的结果对 volatile 变量及其后面语句可见。

## volatile 不适用的场景

```java
public class Test {
    public volatile int inc = 0;

    public void increase() {
        inc++;
    }

    public static void main(String[] args) {
        Test test = new Test();
        for (int i = 0; i < 10; i++) {
            new Thread(new Runnable() {
                @Override
                public void run() {
                    for (int j = 0; j < 1000; j++){
                        test.increase();
                    }
                }
            }).start();
        }
        // 保证前面的线程都执行完
        while (Thread.activeCount() > 1) {
            Thread.yield();
        }
        // inc output:9889
        System.out.println("inc output:" + test.inc);
    }
}
```

- IDEA用不加断点的 debug 模式运行。（直接运行，IDEA 还会开启一个 Monitor Ctrl-Break 线程）

- inc++不是一个原子性操作，由读取、加、赋值 3 步组成，所以结果并不能达到 10000

解决办法：

1. 方法前加上 `synchronized`

```java
public synchronized void increase() {
    inc++;
}
```

2. 采用 `Lock`，通过重入锁 `ReentrantLock `对 `inc++` 加锁

```java
Lock lock = new ReentrantLock();

public void increase() {
    lock.lock();
    inc++;
    lock.unlock();
}
```

3. 采用原子类 `AtomicInteger`

```java
public AtomicInteger inc = new AtomicInteger();

public void increase() {
    inc.getAndIncrement();
}
```

## volatile 实现双重检测锁的单例模式

```java
public class SingleInstanceTest {
    private SingleInstanceTest() {
    }

    // 使用 volatile 关键字是为了防止 INSTANCE = new SingleInstanceTest(); 这一步被指令重排序
    private volatile static SingleInstanceTest INSTANCE;

    public static SingleInstanceTest GetInstance() {
        if (INSTANCE == null) {
            synchronized (SingleInstanceTest.class) {
                if (INSTANCE == null) {
                    // new SingleInstanceTest()有三个子步骤
                    // 步骤 1：为 SingleInstanceTest 对象分配足够的内存空间，伪代码 memory = allocate()。
                    // 步骤 2：调用 SingleInstanceTest 的构造方法，初始化对象的成员变量，伪代码 ctorInstanc(memory)。
                    // 步骤 3：将内存地址赋值给 INSTANCE 变量，使其指向新创建的对象，伪代码 INSTANCE = memory。
                    INSTANCE = new SingleInstanceTest();
                }
            }
        }
        return INSTANCE;
    }
}
```
