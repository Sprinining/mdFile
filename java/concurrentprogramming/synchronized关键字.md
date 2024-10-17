---
title: synchronized关键字
date: 2024-08-13 11:30:12 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, Synchronized]
description: 
---
在 Java 中，关键字 synchronized  可以保证在同一个时刻，只有一个线程可以执行某个方法或者某个代码块(主要是对方法或者代码块中存在共享数据的操作)，同时我们还应该注意到  synchronized 的另外一个重要的作用，synchronized  可保证一个线程的变化(主要是共享数据的变化)被其他线程所看到（保证可见性，完全可以替代 volatile 功能）。

synchronized 关键字最主要有以下 3 种应用方式：

- `同步方法`，为当前对象（`this`）加锁，进入同步代码前要获得当前对象的锁；
- `同步静态方法`，为当前类加锁（ `Class 对象`），进入同步代码前要获得当前类的锁；
- `同步代码块`，指定加锁对象，对给定对象加锁，进入同步代码库前要获得给定对象的锁。

## synchronized 同步方法

------

在方法声明中加入 synchronized 关键字，可以保证在任意时刻，只有一个线程能执行该方法。

```java
class AccountingSync implements Runnable {
    // 共享资源(临界资源)
    static int i = 0;

    // synchronized 同步方法
    public synchronized void increase() {
        i++;
    }

    @Override
    public void run() {
        for (int j = 0; j < 1000000; j++) {
            increase();
        }
    }

    public static void main(String args[]) throws InterruptedException {
        AccountingSync instance = new AccountingSync();
        Thread t1 = new Thread(instance);
        Thread t2 = new Thread(instance);
        t1.start();
        t2.start();
        t1.join();
        t2.join();
        // output:2000000
        // 如果在方法 increase() 前不加 synchronized，因为 i++ 不具备原子性，所以最终结果会小于 2000000
        System.out.println("output:" + i);
    }
}
```

- 一个对象只有一把锁，当一个线程获取了该对象的锁之后，其他线程无法获取该对象的锁，所以无法访问该对象的其他 synchronized 方法，但是其他线程还是可以访问该对象的其他非 synchronized 方法。

每个对象都有一个对象锁，不同的对象，他们的锁不会互相影响：

```java
public static void main(String args[]) throws InterruptedException {
    Thread t1 = new Thread(new AccountingSync());
    Thread t2 = new Thread(new AccountingSync());
    t1.start();
    t2.start();
    t1.join();
    t2.join();
    // output:1508873
    // 虽然使用了 synchronized 同步 increase 方法，但却 new 了两个不同的对象，这也就意味着存在着两个不同的对象锁
    // 因此 t1 和 t2 都会进入各自的对象锁，也就是说 t1 和 t2 线程使用的是不同的锁，因此线程安全是无法保证的。
    System.out.println("output:" + i);
}
```

解决这种问题的的方式是将 synchronized 作用于静态的 increase 方法，这样的话，对象锁就锁的是当前的类，由于无论创建多少个对象，类永远只有一个，所有在这样的情况下对象锁就是唯一的。

```java
// synchronized 同步方法
public static synchronized void increase() {
    i++;
}
```

## synchronized 同步静态方法

------

当 synchronized 同步静态方法时，锁的是当前类的 Class 对象，不属于某个对象。当前类的 Class 对象锁被获取，不影响实例对象锁的获取，两者互不影响，本质上是 this 和 Class 的不同。

由于静态成员变量不专属于任何一个对象，因此通过 Class 锁可以控制静态成员变量的并发操作。

需要注意的是如果线程 A 调用了一个对象的非静态 synchronized 方法，线程 B 需要调用这个对象所属类的静态 synchronized 方法，是==不会发生互斥==的，因为访问静态 synchronized 方法占用的锁是当前类的 Class 对象，而访问非静态 synchronized 方法占用的锁是当前对象（this）的锁，看如下代码：

```java
class AccountingSyncClass implements Runnable {
    static int i = 0;

    // 同步静态方法，锁是当前AccountingSyncClass.Class对象
    public static synchronized void increase() {
        i++;
    }

    // 非静态，锁的是当前对象（this）
    public synchronized void increase4Obj() {
        i++;
    }

    @Override
    public void run() {
        for (int j = 0; j < 1000000; j++) {
            increase();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        //new新实例
        Thread t1 = new Thread(new AccountingSyncClass());
        //new新实例
        Thread t2 = new Thread(new AccountingSyncClass());
        //启动线程
        t1.start();
        t2.start();
        t1.join();
        t2.join();
        // 2000000，访问时锁不一样，不会发生互斥
        System.out.println(i);
    }
}
```

## synchronized 同步代码块

------

某些情况下，我们编写的方法代码量比较多，存在一些比较耗时的操作，而需要同步的代码块只有一小部分，如果直接对整个方法进行同步，可能会得不偿失，此时我们可以使用同步代码块的方式对需要同步的代码进行包裹。

```java
class AccountingSync implements Runnable {
    static AccountingSync instance = new AccountingSync();
    // 共享资源(临界资源)
    static int i = 0;

    @Override
    public void run() {
        synchronized (instance) {
            for (int j = 0; j < 1000000; j++) {
                i++;
            }
        }
    }

    public static void main(String args[]) throws InterruptedException {
        AccountingSync instance = new AccountingSync();
        Thread t1 = new Thread(instance);
        Thread t2 = new Thread(instance);
        t1.start();
        t2.start();
        t1.join();
        t2.join();
        // output:2000000
        System.out.println("output:" + i);
    }
}
```

将 synchronized 作用于一个给定的实例对象 instance，即当前实例对象就是锁的对象，当线程进入 synchronized  包裹的代码块时就会要求当前线程持有 instance  实例对象的锁，如果当前有其他线程正持有该对象锁，那么新的线程就必须等待，这样就保证了每次只有一个线程执行 `i++` 操作。

```java
// this,当前实例对象锁
synchronized(this){
    for(int j=0;j<1000000;j++){
        i++;
    }
}
// Class对象锁
synchronized(AccountingSync.class){
    for(int j=0;j<1000000;j++){
        i++;
    }
}
```

## synchronized 与 happens before

------

```java
class MonitorExample {
    int a = 0;
    public synchronized void writer() {  //1
        a++;                             //2
    }                                    //3
    public synchronized void reader() {  //4
        int i = a;                       //5
        //……
    }                                    //6
}
```

假设线程 A 执行 `writer()` 方法，随后线程 B 执行 `reader()` 方法。根据 happens before 规则，这个过程包含的 happens before 关系可以分为：

- 根据程序次序规则，1 happens before 2, 2 happens before 3; 4 happens before 5, 5 happens before 6。
- 根据监视器锁规则，3 happens before 4。
- 根据 happens before 的传递性，2 happens before 5。

> 在 Java 内存模型中，监视器锁规则是一种 happens-before 规则，它规定了对一个监视器锁（monitor  lock）或者叫做互斥锁的解锁操作 happens-before  于随后对这个锁的加锁操作。简单来说，这意味着在一个线程释放某个锁之后，另一个线程获得同一把锁的时候，前一个线程在释放锁时所做的所有修改对后一个线程都是可见的。

synchronized 会==防止临界区内的代码与外部代码发生重排序==

## synchronized 属于可重入锁

------

从互斥锁的设计上来说，当一个线程试图操作一个由其他线程持有的对象锁的临界资源时，将会处于阻塞状态，但当一个线程再次请求自己持有对象锁的临界资源时，这种情况属于重入锁，请求将会成功。

synchronized 就是可重入锁，因此一个线程调用 synchronized 方法的同时，在其方法体内部调用该对象另一个 synchronized 方法是允许的，如下：

```java
class AccountingSync implements Runnable {
    static AccountingSync instance = new AccountingSync();
    static int i = 0;
    static int j = 0;

    @Override
    public void run() {
        for (int j = 0; j < 1000000; j++) {
            // this,当前实例对象锁
            synchronized (this) {
                i++;
                // synchronized的可重入性
                increase();
            }
        }
    }

    public synchronized void increase() {
        j++;
    }

    public static void main(String[] args) throws InterruptedException {
        Thread t1 = new Thread(instance);
        Thread t2 = new Thread(instance);
        t1.start();
        t2.start();
        t1.join();
        t2.join();
        System.out.println(i);
    }
}
```

`synchronized`的不足之处

- 如果临界区是只读操作，其实可以多线程一起执行，但使用 synchronized 的话，**同一时间只能有一个线程执行**。
- synchronized 无法知道线程有没有成功获取到锁。
- 使用 synchronized，如果临界区因为 IO 或者 sleep 方法等原因阻塞了，而当前线程又没有释放锁，就会导致**所有线程等待**。

> 临界区（Critical Section）是多线程中一个  非常重要的概念，指的是在代码中访问共享资源的那部分，且同一时刻只能有一个线程能访问的代码。多个线程同时访问临界区的资源如果没有任何同步（加锁）操作，会导致资源的状态不可预测和不一致，从而产生所谓的“竞态条件”(Race Condition)。在许多并发控制策略中，例如互斥锁 synchronized，目标就是确保任何时候只有一个线程进入临界区。

## 例子

```java
import java.util.concurrent.TimeUnit;

class Test1 {

    public static void main(String[] args) {
        Phone phone = new Phone();

        new Thread(() -> {
            phone.sendMsg();
        }, "A").start();

        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> {
            phone.call();
        }, "B").start();

    }
}


class Phone {

    // 锁的是方法的调用者
    // 用的是同一个锁，谁先拿到谁执行
    public synchronized void sendMsg() {
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("发短信");
    }

    public synchronized void call() {
        System.out.println("打电话");
    }
}
```

```java
import java.util.concurrent.TimeUnit;

class Test2 {
    public static void main(String[] args) {
        // 一个对象只有一把锁
        Phone2 phone = new Phone2();

        new Thread(() -> {
            phone.sendMsg();
        }, "A").start();

        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> {
            phone.hello();
        }, "B").start();

        // 先hello后发短信
    }
}


class Phone2 {
    // 锁的是方法的调用者
    // 用的是同一个锁，谁先拿到谁执行
    public synchronized void sendMsg() {
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("发短信");
    }

    public synchronized void call() {
        System.out.println("打电话");
    }

    // 没有锁，不是同步方法，不受锁的影响
    public void hello() {
        System.out.println("hello");
    }
}
```

```java
import java.util.concurrent.TimeUnit;

class Test3 {
    public static void main(String[] args) {
        // 一个对象只有一把锁
        // 两个对象的Class类模板只有一个，static锁的是class
        Phone3 phone1 = new Phone3();
        Phone3 phone2 = new Phone3();

        new Thread(() -> {
            phone1.sendMsg();
        }, "A").start();

        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> {
            phone2.call();
        }, "B").start();

        // 先短信后打电话
    }
}

// 两个静态的锁
// 类一加载就有了，锁的是Class
class Phone3 {
    public static synchronized void sendMsg() {
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("发短信");
    }

    public static synchronized void call() {
        System.out.println("打电话");
    }

}
```

```java
import java.util.concurrent.TimeUnit;

class Test4 {
    public static void main(String[] args) {
        // 一个对象只有一把锁
        // 两个对象的Class类模板只有一个，static锁的是class
        Phone4 phone1 = new Phone4();
        Phone4 phone2 = new Phone4();

        new Thread(() -> {
            phone1.sendMsg();
        }, "A").start();

        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        new Thread(() -> {
            phone2.call();
        }, "B").start();

        // 先打电话后发短信
    }
}

class Phone4 {

    // 锁的是Class
    public static synchronized void sendMsg() {
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("发短信");
    }

    // 普通同步方法 锁的是调用者
    public synchronized void call() {
        System.out.println("打电话");
    }

}
```
