---
title: lock锁
date: 2022-03-21 03:35:24 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, JUC, Lock]
description: 
---
# Lock锁

### 源码

- Lock

```java
public interface Lock {
    void lock();
    void lockInterruptibly() throws InterruptedException;
    boolean tryLock();
    boolean tryLock(long time, TimeUnit unit) throws InterruptedException;
    void unlock();
    Condition newCondition(); // 对象监视器
}
```

- ReentrantLock

```java
ReentrantLock() //创建一个 ReentrantLock 的实例
ReentrantLock(boolean fair) //创建一个具有给定公平策略的 ReentrantLock 

int getHoldCount() //查询当前线程保持此锁的次数
protected Thread getOwner() //返回目前拥有此锁的线程，如果此锁不被任何线程拥有，则返回 null 
protected Collection<Thread> getQueuedThreads() //返回一个collection，它包含可能正等待获取此锁的线程 
int getQueueLength() //返回正等待获取此锁的线程估计数 
protected Collection<Thread> getWaitingThreads(Condition condition) //返回一个 collection，它包含可能正在等待与此锁相关给定条件的那些线程 
int getWaitQueueLength(Condition condition) //返回等待与此锁相关的给定条件的线程估计数
boolean hasQueuedThread(Thread thread) //查询给定线程是否正在等待获取此锁
boolean hasQueuedThreads() //查询是否有些线程正在等待获取此锁
boolean hasWaiters(Condition condition) //查询是否有些线程正在等待与此锁有关的给定条件
boolean isFair() //如果此锁的公平设置为 true，则返回true 
boolean isHeldByCurrentThread() //查询当前线程是否保持此锁
boolean isLocked() //查询此锁是否由任意线程保持
void lock() //获取锁
void lockInterruptibly() //如果当前线程未被中断，则获取锁。
Condition newCondition() //返回用来与此 Lock 实例一起使用的 Condition 实例 
boolean tryLock() //仅在调用时锁未被另一个线程保持的情况下，才获取该锁
boolean tryLock(long timeout, TimeUnit unit) //如果锁在给定等待时间内没有被另一个线程保持，且当前线程未被中断，则获取该锁 
void unlock() //试图释放此锁
```

- Condition

```java
void await() //造成当前线程在接到信号或被中断之前一直处于等待状态。 
 boolean await(long time, TimeUnit unit) //造成当前线程在接到信号、被中断或到达指定等待时间之前一直处于等待状态。 
 long awaitNanos(long nanosTimeout) //造成当前线程在接到信号、被中断或到达指定等待时间之前一直处于等待状态。 
 void awaitUninterruptibly() //造成当前线程在接到信号之前一直处于等待状态。 
 boolean awaitUntil(Date deadline) //造成当前线程在接到信号、被中断或到达指定最后期限之前一直处于等待状态。 
 void signal() //唤醒一个等待线程。 
 void signalAll() //唤醒所有等待线程。 
```

### 获取锁

- lock()

```java
// 采用Lock，必须主动去释放锁，并且在发生异常时，不会自动释放锁
Lock lock=new ReentrantLock();
lock.lock();
try{
    
}catch(Exception ex){
     
}finally{
    lock.unlock();
}
```

- tryLock()

```java
Lock lock=new ReentrantLock();
if(lock.tryLock()) {
     try{

     }catch(Exception ex){
         
     }finally{
         lock.unlock();   
     } 
}else {

}
```

- lockInterruptibly()

```java
// 当两个线程同时通过lock.lockInterruptibly()想获取某个锁时，假若此时线程A获取到了锁，而线程B只有在等待，那么对线程B调用threadB.interrupt()方法能够中断线程B的等待过程。
public void method() throws InterruptedException {
    Lock lock=new ReentrantLock();
    lock.lockInterruptibly();
    try {  

    }
    finally {
        lock.unlock();
    }  
}
```





- 公平锁：先来后到
- 非公平锁：可以插队（默认）

```java
public ReentrantLock() {
    sync = new NonfairSync();
}
public ReentrantLock(boolean fair) {
    sync = fair ? new FairSync() : new NonfairSync();
}
```

### ==与synchronized区别==

- Synchronized 内置的**java关键字**，lock是一个**java类**
- Synchronized **无法判断获取锁的状态 **，lock **可以判断是否获取了锁 **
- Synchronized 会 **自动释放锁 **，lock **必须手动释放锁，否则死锁 **
- Synchronized 线程1（获得锁，阻塞），线程2（等待，继续等待）；lock不一定会等待下去
- Synchronized  **可重入锁，不可以中断，非公平 **；lock，可重入锁，可以判断锁，非公平（可以自己设置）
- Synchronized 适合锁少量代码同步问题，lock锁大量同步代码



### lock版的

- 随机执行的

```java

import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

class B {

    public static void main(String[] args) {
        Data2 data2 = new Data2();

        new Thread(() -> {
            for (int i = 0; i < 10; i++) {
                try {
                    data2.increment();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }, "A").start();
        new Thread(() -> {
            for (int i = 0; i < 10; i++) {
                try {
                    data2.decrement();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }, "B").start();
        new Thread(() -> {
            for (int i = 0; i < 10; i++) {
                try {
                    data2.increment();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }, "C").start();
        new Thread(() -> {
            for (int i = 0; i < 10; i++) {
                try {
                    data2.decrement();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }, "D").start();
    }
}

class Data2 {
    private int num = 0;
    private Lock lock = new ReentrantLock();
    private Condition condition = lock.newCondition();

    // +1
    public void increment() throws InterruptedException {
        lock.lock();
        try {
            while (num != 0) {
                condition.await();
            }
            num++;
            System.out.println(Thread.currentThread().getName() + "->" + num);
            condition.signalAll();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }


    // -1
    public void decrement() throws InterruptedException {
        lock.lock();
        try {
            while (num == 0) {
                condition.await();
            }
            num--;
            System.out.println(Thread.currentThread().getName() + "->" + num);
            condition.signalAll();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }
}
```

  - 精准唤醒

```java

import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

class C {
    public static void main(String[] args) {
        Data3 data3 = new Data3();

        new Thread(() -> {
            for (int i = 0; i < 10; i++) {
                data3.printA();
            }
        }, "A").start();
        new Thread(() -> {
            for (int i = 0; i < 10; i++) {
                data3.printB();
            }
        }, "B").start();
        new Thread(() -> {
            for (int i = 0; i < 10; i++) {
                data3.printC();
            }
        }, "C").start();
    }
}


class Data3 {
    private int num = 1;
    private Lock lock = new ReentrantLock();
    private Condition condition1 = lock.newCondition();
    private Condition condition2 = lock.newCondition();
    private Condition condition3 = lock.newCondition();

    public void printA() {
        lock.lock();
        try {
            while (num != 1) {
                // 释放锁然后阻塞自己
                condition1.await();
            }
            num = 2;
            System.out.println(Thread.currentThread().getName() + "AAA");
            condition2.signalAll();// 唤醒B
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }

    public void printB() {
        lock.lock();
        try {
            while (num != 2) {
                condition2.await();
            }
            num = 3;
            System.out.println(Thread.currentThread().getName() + "BBB");
            condition3.signalAll();// 唤醒C
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }

    public void printC() {
        lock.lock();
        try {
            while (num != 3) {
                condition3.await();
            }
            num = 1;
            System.out.println(Thread.currentThread().getName() + "CCC");
            condition1.signalAll();// 唤醒A
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }
}
```
