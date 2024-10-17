---
title: juc简介
date: 2022-03-21 03:35:24 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, JUC]
description: 
---
# JUC

---

- cpu多核

```java
public class Test1 {
    public static void main(String[] args) {
        // 获取cpu核数
        // cpu密集型  io密集型
        System.out.println(Runtime.getRuntime().availableProcessors());
    }
}
```

- ==wait会释放锁，sleep不会释放==
- wait必须在同步代码块中，sleep任意位置
- wait不要捕获异常，sleep必须捕获

## 锁的分类

### 可重入锁

如果锁具备可重入性，则称作为可重入锁。像synchronized和ReentrantLock都是可重入锁。举个简单的例子，当一个线程执行到某个synchronized方法时，比如说method1，而在method1中会调用另外一个synchronized方法method2，此时线程不必重新去申请锁，而是可以直接执行方法method2。

### 可中断锁

synchronized就不是可中断锁，而Lock是可中断锁。如果某一线程A正在执行锁中的代码，另一线程B正在等待获取该锁，可能由于等待时间过长，线程B不想等待了，可以让它中断自己或者在别的线程中中断它。

### 公平锁

公平锁即尽量以请求锁的顺序来获取锁。多个线程在等待一个锁，当这个锁被释放时，等待时间最久的线程（最先请求的线程）会获得锁，这种就是公平锁。非公平锁即无法保证锁的获取是按照请求锁的顺序进行的。这样就可能导致某个或者一些线程永远获取不到锁。
synchronized就是非公平锁，它无法保证等待的线程获取锁的顺序。而对于ReentrantLock和ReentrantReadWriteLock，它默认情况下是非公平锁，但是可以设置为公平锁。


## 集合类不安全

- ConcurrentModificationException并发修改异常
- 解决办法
  - 写入时复制
  - 使用工具类Collections
- List不安全

```java
import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

class ListTest {

    public static void main(String[] args) {
        /**
         * 并发编程下ArrayList不安全
         * 1.List<String> list = new Vector<>();
         * 2.List<String> list = Collections.synchronizedList(new ArrayList<>());
         * 3.List<String> list = new CopyOnWriteArrayList<>();
         */

        // CopyOnWrite 写入时复制
        List<String> list = new CopyOnWriteArrayList<>();

        for (int i = 1; i <= 10; i++) {
            new Thread(() -> {
                list.add(UUID.randomUUID().toString().substring(0, 5));
                System.out.println(list);
            }, String.valueOf(i)).start();
        }
    }
}
```

- Set不安全

```java
import java.util.*;
import java.util.concurrent.CopyOnWriteArraySet;

class SetTest {
    public static void main(String[] args) {
        /**
         * 1.Set<String> set = Collections.synchronizedSet(new HashSet<>());
         * 2.Set<String> set = new CopyOnWriteArraySet<>();
         */
        Set<String> set = new CopyOnWriteArraySet<>();
        for (int i = 0; i < 10; i++) {
            new Thread(()->{
                set.add(UUID.randomUUID().toString().substring(0, 5));
                System.out.println(set);
            }, String.valueOf(i)).start();
        }
    }
}
```

- HashSet底层是HashMap


```java
public HashSet() {
    map = new HashMap<>();
}

public boolean add(E e) {
    return map.put(e, PRESENT)==null;
}
```

- HashMap不安全

```java
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

class MapTest {
    public static void main(String[] args) {
        // 默认等价与new HashMap<>(16， 0.75); 初始化容量和加载因子
        Map<String, String> map = new ConcurrentHashMap<>();

        for (int i = 1; i <= 10; i++) {
            new Thread(() -> {
                map.put(Thread.currentThread().getName(), UUID.randomUUID().toString().substring(0, 5));
                System.out.println(map);
            }, String.valueOf(i)).start();
        }
    }
}
```

## Callable

- Runnable没有返回值：public abstract void run();，Callable可以有返回值：V call() throws Exception;
- 可以抛出异常
- 方法不同，run()/call()
- 源码

```java
public interface Callable<V> {
    /**
     * Computes a result, or throws an exception if unable to do so.
     *
     * @return computed result
     * @throws Exception if unable to compute a result
     */
    V call() throws Exception;
}
```

## Future

- Future只是一个接口
- 能判断任务是否完成；能够中断任务；能够获取任务执行结果。
- 源码

```java
public interface Future<V> {
	// 如果取消已经完成的任务会返回false；如果任务正在执行，若mayInterruptIfRunning设置为true，则返回true，若mayInterruptIfRunning设置为false，则返回false；如果任务还没有执行，则无论mayInterruptIfRunning为true还是false，肯定返回true。
    boolean cancel(boolean mayInterruptIfRunning);
	// 是否被取消成功
    boolean isCancelled();
    // 是否已经完成
    boolean isDone();
	// 获取执行结果，这个方法会产生阻塞，会一直等到任务执行完毕才返回
    V get() throws InterruptedException, ExecutionException;
	// 如果在指定时间内，还没获取到结果，就直接返回null
    V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException;
}
```

## FutureTask

- FutureTask是Future接口的一个唯一实现类

- 继承关系

```java
public interface RunnableFuture<V> extends Runnable, Future<V> {
    void run();
}
```

```java
public class FutureTask<V> implements RunnableFuture<V> 
```

RunnableFuture继承了Runnable接口和Future接口，而FutureTask实现了RunnableFuture接口。所以它既可以作为Runnable被线程执行，又可以作为Future得到Callable的返回值。

- 构造方法

```java
public FutureTask(Callable<V> callable) {
    if (callable == null)
        throw new NullPointerException();
    this.callable = callable;
    this.state = NEW;      
}

public FutureTask(Runnable runnable, V result) {
    this.callable = Executors.callable(runnable, result);
    this.state = NEW;    
}
```

- Callable+Future

```java
import java.util.concurrent.*;

class MyCallable {
    public static void main(String[] args) throws InterruptedException {
        ExecutorService executor = Executors.newCachedThreadPool();
        Task task = new Task();
        Future<Integer> result = executor.submit(task);
        executor.shutdown();

        TimeUnit.SECONDS.sleep(1);

        System.out.println("主线程在执行任务");

        try {
            System.out.println("task运行结果" + result.get());
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }

        System.out.println("所有任务执行完毕");
    }
}

class Task implements Callable<Integer> {
    @Override
    public Integer call() throws Exception {
        System.out.println("子线程在进行计算");
        TimeUnit.SECONDS.sleep(2);
        int sum = 0;
        for (int i = 0; i < 100; i++)
            sum += i;
        return sum;
    }
}
```

- Callable+FutureTask

```java
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.FutureTask;

class MyCallable {
    public static void main(String[] args) throws ExecutionException, InterruptedException {
        // new Thread(new Runnable()).start();
        // new Thread(new FutureTask<V>()).start();
        // new Thread(new FutureTask<V>( Callable )).start();

        MyThread myThread = new MyThread();
        FutureTask<Integer> integerFutureTask = new FutureTask<>(myThread); // 适配类

        new Thread(integerFutureTask, "A").start();
        new Thread(integerFutureTask, "B").start(); // 结果会被缓存，只会打印一个call

        Integer o = integerFutureTask.get(); // 返回值   此方法可能会产生阻塞，最好放在最后一行
        System.out.println(o);
    }
}

class MyThread implements Callable<Integer> {
    @Override
    public Integer call() throws Exception {
        System.out.println("call()");
        return 7;
    }
}
```

## CountDownLatch减法计数器

- CountDownLatch 允许**一个或多个**线程等待一些特定的操作完成，而这些操作是在其它的线程中进行的
- CountDownLatch 构造函数中有一个 count 参数，表示有多少个线程需要被等待。其他线程调用countDown()方法，每调用一次 countDown 方法就表示有一个被等待的线程到达，count 变为 0 时，latch（闩shuan锁）就会被打开，处于等待状态的那些线程接着可以执行
- 一个线程中可以调用多次countDown()
- CountDownLatch 是一次性使用的，没有为 count 变量提供 set 的方法
- CountDownLatch非常适合于对任务进行拆分，使其并行执行，总的执行时间将决定于执行最慢的任务

```java
import java.util.concurrent.CountDownLatch;

class MyCountDownLatch {
    public static void main(String[] args) throws InterruptedException {
        CountDownLatch countDownLatch = new CountDownLatch(6);

        new Thread(()->{
            try {
                countDownLatch.await();
                // 可以多个线程一起等待
                System.out.println("over1");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();

        for (int i = 0; i < 6; i++) {
            new Thread(() -> {
                System.out.println(Thread.currentThread().getName());
                // 计数器减一
                countDownLatch.countDown();
            }, String.valueOf(i)).start();
        }

        // 等待计数器归零才会往下执行
        countDownLatch.await();
        System.out.println("over2");
    }
}
```

## CyclicBarrier栅栏

- CyclicBarrier也叫同步屏障，在JDK1.5被引入，可以让一组线程达到一个屏障时被阻塞，直到最后一个线程达到屏障时，所以被阻塞的线程才能继续执行。
- CountDownLatch的计数器只能使用一次，而CyclicBarrier的计数器可以使用reset()方法重置，可以使用多次，所以CyclicBarrier能够处理更为复杂的场景；
- CyclicBarrier还提供了一些其他有用的方法，比如getNumberWaiting()方法可以获得CyclicBarrier阻塞的线程数量，isBroken()方法用来了解阻塞的线程是否被中断；
- CountDownLatch允许一个或多个线程等待一组事件的产生，而CyclicBarrier用于等待其他线程运行到栅栏位置。

```java
import java.util.concurrent.BrokenBarrierException;
import java.util.concurrent.CyclicBarrier;

class MyCyclicBarrier {
    public static void main(String[] args) throws BrokenBarrierException, InterruptedException {
        CyclicBarrier cyclicBarrier = new CyclicBarrier(7, () -> {
            System.out.println("over");
        });

        for (int i = 0; i < 7; i++) {
            final int temp = i;
            new Thread(() -> {
                System.out.println(Thread.currentThread().getName() + " " + temp);
                try {
                    cyclicBarrier.await();
                } catch (InterruptedException | BrokenBarrierException e) {
                    e.printStackTrace();
                }
            }).start();
        }
    }
}
```

## Semaphore

- 公共资源有限时用户控制流量
- 构造函数，默认非公平锁

```java
public Semaphore(int permits) {
    sync = new NonfairSync(permits);
}

public Semaphore(int permits, boolean fair) {
    sync = fair ? new FairSync(permits) : new NonfairSync(permits);
}
```

- 非公平的体现：

  当一个线程A执行acquire方法时，会直接尝试获取许可，而不管同一时刻阻塞队列中是否有线程也在等待许可，如果恰好有线程C执行release释放许可，并唤醒阻塞队列中第一个等待的线程B，这个时候，线程A和线程B是共同竞争可用许可，不公平性就是这么体现出来的，线程**A一点时间都没等待就和线程B同等对待**。

- 并发限流，控制最大线程数

```java
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

class MySemaphore {
    public static void main(String[] args) {
        // 线程数量 限流
        Semaphore semaphore = new Semaphore(3);
        for (int i = 0; i < 6; i++) {
            new Thread(() -> {
                try {
                    // P获取
                    semaphore.acquire();
                    System.out.println(Thread.currentThread().getName() + "获得资源");

                    // 6个线程一开始有三个获取到临界资源，剩下三个阻塞
                    TimeUnit.SECONDS.sleep(2);
                    System.out.println(Thread.currentThread().getName() + "释放资源");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    // V释放
                    semaphore.release();
                }
            }).start();
        }
    }
}
```

## ReadWriteLock读写锁

- ReadWriteLock只允许一个线程修改，但是get()方法只读，不修改数据，实际上允许多个线程同时调用，使用`ReadWriteLock`可以解决这个问题
- 适合读多写少的场景

- 源码

```java
public interface ReadWriteLock {
    Lock readLock();
    Lock writeLock();
}
```

- 实现类:ReentrantReadWriteLock
- 读锁（共享锁），写锁（独占锁）

```java
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

class MyReadWriteLock {
    public static void main(String[] args) {
        MyCache myCache = new MyCache();

        for (int i = 0; i < 6; i++) {
            final int temp = i;
            new Thread(() -> {
                // lambda无法访问到外部的变量
                myCache.put(temp + "", "value:" + temp);
            }, String.valueOf(i)).start();
        }

        for (int i = 0; i < 6; i++) {
            final int temp = i;
            new Thread(() -> {
                myCache.get(temp + "");
            }, String.valueOf(i)).start();
        }
    }
}

class MyCache {
    private final Map<String, Object> map = new HashMap<>();
    // 读写锁
    private final ReadWriteLock lock = new ReentrantReadWriteLock();

    // 只有一个可以写
    public void put(String key, Object value) {
        lock.writeLock().lock();

        try {
            System.out.println(Thread.currentThread().getName() + "写入" + value);
            map.put(key, value);
            System.out.println(Thread.currentThread().getName() + "写完毕");
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.writeLock().unlock();
        }
    }

    // 可以多个同时读
    public void get(String key) {
        lock.readLock().lock();

        try {
            System.out.println(Thread.currentThread().getName() + "读取" + map.get(key));
            System.out.println(Thread.currentThread().getName() + "读完毕");
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.readLock().unlock();
        }
    }
}
```

## BlockingQueue

- 实现类

![image-20211030173337184](./juc简介.assets/image-20211030173337184.png)

- Collection->Queue->BlockingQueue
- 使用场景：多线程并发处理，线程池
- Queue源码

```java
public interface Queue<E> extends Collection<E> {
    boolean add(E e);
    boolean offer(E e);
    E remove();
    E poll();
    E element();
    E peek();
}
```

- BlockingQueue源码

```java
public interface BlockingQueue<E> extends Queue<E> {
    boolean add(E e);
    boolean offer(E e);
    void put(E e) throws InterruptedException;
    boolean offer(E e, long timeout, TimeUnit unit)
        throws InterruptedException;
    E take() throws InterruptedException;
    E poll(long timeout, TimeUnit unit)
        throws InterruptedException;
    int remainingCapacity();
    boolean remove(Object o);
    boolean contains(Object o);
    int drainTo(Collection<? super E> c);
    int drainTo(Collection<? super E> c, int maxElements);
}
```

## ArrayBlockingQueue

- 依赖AQS实现并发操作
- ==四组API==

| 方式     | 抛出异常  | 不抛出异常 | 阻塞等待 | 超时等待                    |
| -------- | :-------: | ---------- | -------- | --------------------------- |
| 添加     |  add(o)   | offer(o)   | put(o)   | offer(o, timeout, timeunit) |
| 移除     | remove()  | poll()     | take()   | poll(timeout, timeunit)     |
| 判断队首 | element() | peek()     | ---      | ---                         |

```java
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;

class MyBlockingQueue {
    public static void main(String[] args) throws InterruptedException {

        // 抛出异常
//        test1();

        // 不抛出异常
//        test2();

        // 阻塞等待
//        test3();

        // 超时等待
        test4();
    }

    public static void test1() {
        // 队列大小
        ArrayBlockingQueue<Object> arrayBlockingQueue = new ArrayBlockingQueue<>(3);
        System.out.println(arrayBlockingQueue.add("a")); // true
        System.out.println(arrayBlockingQueue.add("b")); // true
        System.out.println(arrayBlockingQueue.add("c")); // true
//        System.out.println(arrayBlockingQueue.add("d")); // IllegalStateException队列满

        System.out.println(arrayBlockingQueue.element()); // 查看队首

        System.out.println(arrayBlockingQueue.remove()); // ture
        System.out.println(arrayBlockingQueue.remove()); // ture
        System.out.println(arrayBlockingQueue.remove()); // ture
//        System.out.println(arrayBlockingQueue.remove()); // NoSuchElementException
    }

    public static void test2() {
        // 队列大小
        ArrayBlockingQueue<Object> arrayBlockingQueue = new ArrayBlockingQueue<>(3);
        System.out.println(arrayBlockingQueue.offer("a"));
        System.out.println(arrayBlockingQueue.offer("b"));
        System.out.println(arrayBlockingQueue.offer("c"));
        System.out.println(arrayBlockingQueue.offer("d")); // 不跑出异常，返回false

        System.out.println(arrayBlockingQueue.peek());

        System.out.println(arrayBlockingQueue.poll());
        System.out.println(arrayBlockingQueue.poll());
        System.out.println(arrayBlockingQueue.poll());
        System.out.println(arrayBlockingQueue.poll()); // 不抛出异常，返回null

    }

    public static void test3() throws InterruptedException {
        // 队列大小
        ArrayBlockingQueue<Object> arrayBlockingQueue = new ArrayBlockingQueue<>(3);

        // 没有返回值
        arrayBlockingQueue.put("a");
        arrayBlockingQueue.put("b");
        arrayBlockingQueue.put("c");
//        arrayBlockingQueue.put("d");// 会一直等

        System.out.println(arrayBlockingQueue.take()); // a
        System.out.println(arrayBlockingQueue.take()); // b
        System.out.println(arrayBlockingQueue.take()); // c
//        System.out.println(arrayBlockingQueue.take());// 会一直等
    }

    public static void test4() throws InterruptedException {
        // 队列大小
        ArrayBlockingQueue<Object> arrayBlockingQueue = new ArrayBlockingQueue<>(3);
        arrayBlockingQueue.offer("a");
        arrayBlockingQueue.offer("b");
        arrayBlockingQueue.offer("c");
        arrayBlockingQueue.offer("d", 2, TimeUnit.SECONDS);// 两秒后结束等待

        System.out.println(arrayBlockingQueue.poll()); // a
        System.out.println(arrayBlockingQueue.poll()); // b
        System.out.println(arrayBlockingQueue.poll()); // c
        System.out.println(arrayBlockingQueue.poll(2, TimeUnit.SECONDS)); // 两秒后结束等待，返回null
        System.out.println("over");
    }
}
```

## SynchronousQueue同步队列

- 使用CAS实现线程的安全访问

- 构造函数，默认非公平

```java
public SynchronousQueue() {
    this(false);
}

public SynchronousQueue(boolean fair) {
    // 公平：队尾匹配队头出队
    // 非公平：先入栈后匹配
    transferer = fair ? new TransferQueue<E>() : new TransferStack<E>();
}
```

- 它一种阻塞队列，其中每个 put 必须等待一个 take，反之亦然。同步队列没有任何内部容量，甚至连一个队列的容量都没有。 

```java
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.TimeUnit;

class MySynchronousQueue {
    public static void main(String[] args) {
        // 同步队列
        BlockingQueue<String> blockingQueue = new SynchronousQueue<>();

        new Thread(() -> {
            try {
                System.out.println(Thread.currentThread().getName() + " put\t1");
                //  往queue放进去一个element以后就一直wait直到有其他thread进来把这个element取走
                blockingQueue.put("1");
                System.out.println(Thread.currentThread().getName() + " put\t2");
                blockingQueue.put("2");
                System.out.println(Thread.currentThread().getName() + " put\t3");
                blockingQueue.put("3");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }, "Producer").start();

        new Thread(() -> {
            try {
                TimeUnit.SECONDS.sleep(1);
                // 取出并删除element，取不到东西他会一直等
                System.out.println(Thread.currentThread().getName() + " take\t" +blockingQueue.take());
                TimeUnit.SECONDS.sleep(1);
                System.out.println(Thread.currentThread().getName() + " take\t" +blockingQueue.take());
                TimeUnit.SECONDS.sleep(1);
                System.out.println(Thread.currentThread().getName() + " take\t" +blockingQueue.take());
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }, "Consumer").start();
    }
}
```

## LinkedBlockingQueue

- 构造函数Integer.MAX_VALUE

```java
// 默认容量
public LinkedBlockingQueue() {
    this(Integer.MAX_VALUE);
}

public LinkedBlockingQueue(int capacity) {
    if (capacity <= 0) throw new IllegalArgumentException();
    this.capacity = capacity;
    last = head = new Node<E>(null);
}
```

## PriorityBlockingQueue

- 带优先级的无界阻塞队列
- 每次出队都返回优先级最高的元素，是**二叉树最小堆的实现**

## 线程池

- 3大方法，7大参数，4大拒绝策略
- 降低资源消耗
- 提高响应速度
- 方便管理
- ==线程复用，控制最大并发数，管理线程==
- 最大线程定义
  - CPU密集型：几核cpu就设置为几，通过代码去获取Runtime().getRuntime().availableProcessors()
  - IO密集型：判断程序中十分耗费IO的线程

```Java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

class Demo1 {
    public static void main(String[] args) {
        // 单个线程
//        ExecutorService threadPool = Executors.newSingleThreadExecutor();
        // 可伸缩的
//        ExecutorService threadPool = Executors.newCachedThreadPool();
        // 固定大小
        ExecutorService threadPool = Executors.newFixedThreadPool(5);

        // CPU核心数
        System.out.println(Runtime.getRuntime().availableProcessors() + "核");

        try {
            for (int i = 0; i < 10; i++) {
                // 使用线程池创建线程
                threadPool.execute(() -> {
                    System.out.println(Thread.currentThread().getName());
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            // 关闭线程池
            threadPool.shutdown();
        }
    }
}
```

- Executor源码

```java
public interface Executor {
    void execute(Runnable command);
}
```

- ExecutorService源码

```java
public interface ExecutorService extends Executor {

    void shutdown();

    List<Runnable> shutdownNow();

    boolean isShutdown();

    boolean isTerminated();

    boolean awaitTermination(long timeout, TimeUnit unit)
        throws InterruptedException;

    <T> Future<T> submit(Callable<T> task);

    <T> Future<T> submit(Runnable task, T result);

    Future<?> submit(Runnable task);

    <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks)
        throws InterruptedException;

    <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks,
                                  long timeout, TimeUnit unit)
        throws InterruptedException;

    <T> T invokeAny(Collection<? extends Callable<T>> tasks)
        throws InterruptedException, ExecutionException;

    <T> T invokeAny(Collection<? extends Callable<T>> tasks,
                    long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException;
}
```

- Executors部分函数全是调用了ThreadPoolExecutors的构造函数

```java
public static ExecutorService newSingleThreadExecutor () {
    return new FinalizableDelegatedExecutorService
            (new ThreadPoolExecutor(1, 1,
                    0L, TimeUnit.MILLISECONDS,
                    new LinkedBlockingQueue<Runnable>()));
}
public static ExecutorService newFixedThreadPool ( int nThreads){
    return new ThreadPoolExecutor(nThreads, nThreads,
            0L, TimeUnit.MILLISECONDS,
            new LinkedBlockingQueue<Runnable>());
}
public static ExecutorService newCachedThreadPool () {
    return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
            60L, TimeUnit.SECONDS,
            new SynchronousQueue<Runnable>());
}
```

- ThreadPoolExecutor主要构造函数

```java
public ThreadPoolExecutor(int corePoolSize, // 核心线程大小
int maximumPoolSize,                        // 最大大小
long keepAliveTime,                         // 超时了没人调用就会释放
TimeUnit unit,                              // 超时单位
BlockingQueue<Runnable> workQueue,          // 阻塞队列
ThreadFactory threadFactory,                // 线程工厂
RejectedExecutionHandler handler) {         // 拒绝策略
    if (corePoolSize < 0 ||
            maximumPoolSize <= 0 ||
            maximumPoolSize < corePoolSize ||
            keepAliveTime < 0)
        throw new IllegalArgumentException();
    if (workQueue == null || threadFactory == null || handler == null)
        throw new NullPointerException();
    this.corePoolSize = corePoolSize;
    this.maximumPoolSize = maximumPoolSize;
    this.workQueue = workQueue;
    this.keepAliveTime = unit.toNanos(keepAliveTime);
    this.threadFactory = threadFactory;
    this.handler = handler;
}
```

- 拒绝策略（阻塞队列满了后触发拒绝策略）

  - AbortPolicy()：抛出异常
  - CallerRunsPolicy()：把任务队列中的任务放在调用者线程当中运行
  - DiscardPolicy() ：丢弃任务队列中最老的一个任务，也就是当前任务队列中最先被添加进去的，马上要被执行的那个任务，并尝试再次提交
  - DiscardOldestPolicy()：尝试和最早的线程竞争，不会抛出异常
- 自定义线程池

```java
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

class Demo1 {
    public static void main(String[] args) {
        ThreadPoolExecutor threadPool = new ThreadPoolExecutor(2, // 核心线程大小
                5,  // 最大大小（阻塞队列满了后会启用新线程）
                3,     // 超时时间（超时释放的是非核心的线程）
                TimeUnit.SECONDS,  // 超时时间单位
                new LinkedBlockingQueue<>(3),  // 阻塞队列
                Executors.defaultThreadFactory(),      // 线程工厂
                new ThreadPoolExecutor.AbortPolicy()); // 阻塞队列满了后的拒绝策略

        try {
            // 最大承载 = 队列 + max
            for (int i = 0; i < 10; i++) {
                // 使用线程池创建线程
                threadPool.execute(() -> {
                    System.out.println(Thread.currentThread().getName());
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            // 关闭线程池
            threadPool.shutdown();
        }
    }
}
```
- 定时任务

```java
ScheduledThreadPoolExecutor executor = (ScheduledThreadPoolExecutor) Executors.newScheduledThreadPool(1);
executor.scheduleAtFixedRate(() -> {
    
}, 0, 50, TimeUnit.MILLISECONDS);
```

- 倒计时

```java
ScheduledExecutorService scheduledExecutorService = new ScheduledThreadPoolExecutor(1);
scheduledExecutorService.schedule(new Runnable() {
    @Override
    public void run() {
        System.out.println(111);
    }
}, 3, TimeUnit.SECONDS);
```


- 阻塞队列
  - new LinkedBlockingQueue<>(3)：设置固定的容量，此例中：i < 5时，阻塞队列刚刚满，5个任务使用两个核心线程；i < 6时，多了一个线程，6>队列+core，此时会新开辟一个线程（总线程数不大于5），6个任务使用两个核心线程和一个新开辟的线程
  - new LinkedBlockingQueue<>()：**无界阻塞队列**。默认容量为Integer.MAX_VALUE，核心线程都被使用后，新来的线程全都放在阻塞队列中，此时**相当于设置的maximumPoolSize无效**，并发数固定为corePoolSize
  - new SynchronousQueue<>()：创建的线程数大于maximumPoolSize时，**直接执行拒绝策略**
  - new ArrayBlockingQueue<>(3)：**有界阻塞队列**。类似new LinkedBlockingQueue<>(3)
  - new PriorityBlockingQueue<>()：优先级阻塞队列

# Stream流式计算

```java
package juc;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

public class Demo6 {
    /**
     * 有五个用户，进行筛选
     * 1.id为偶数
     * 2.年龄大于23
     * 3.用户名转大写
     * 4.用户名字母倒序
     * 5.只输出一个用户
     */
    public static void main(String[] args) {
        User u1 = new User(1,"a",21 );
        User u2 = new User(2,"b",22 );
        User u3 = new User(3,"c",23 );
        User u4 = new User(4,"d",24 );
        User u5 = new User(6,"e",25 );

        // 集合就是存储
        List<User> list = Arrays.asList(u1, u2, u3, u4, u5);

        // 计算交给Stream
        // 链式编程,lambda表达式,函数式接口,Stream流式计算
        list.stream()
                .filter(u ->{return u.getId()%2==0;})
                .filter(u->{return u.getAge()>23;})
                .map(u->{return u.getName().toUpperCase();})
                .sorted((uu1,uu2)->{return uu2.compareTo(uu1);})
                .limit(1)
                .forEach(System.out::println);
    }
}

class User{
    private int id;
    private String name;
    private int age;

    public User(){

    }

    public User(int id, String name, int age) {
        this.id = id;
        this.name = name;
        this.age = age;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", age=" + age +
                '}';
    }
}
```

# ForkJoin

- 工作窃取，里面维护的都是双端队列，大数据量的时候使用

```Java
package juc;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.ForkJoinTask;
import java.util.concurrent.RecursiveTask;
import java.util.stream.LongStream;

public class MyForkJoin extends RecursiveTask<Long> {

    private Long start;
    private Long end;

    private Long temp = 10000L;// 临界值

    public MyForkJoin(Long start, Long end) {
        this.start = start;
        this.end = end;
    }

    @Override
    protected Long compute() {
        if((end-start)<temp){
            Long sum = 0L;
            for (Long i = start; i <= end; i++) {
                sum += i;
            }
            return sum;
        }else{
            // 分支合并计算
            long middle = (start+end) / 2;// 中间值
            MyForkJoin task1 = new MyForkJoin(start, middle);
            task1.fork();// 拆分任务，把任务压入队列
            MyForkJoin task2 = new MyForkJoin(middle+1, end);
            task2.fork();// 拆分任务，把任务压入队列
            return task1.join() + task2.join();
        }
    }

    public static void main(String[] args) throws ExecutionException, InterruptedException {

//        test1();// 5483

//        test2();// 3799

        test3();// 124
    }

    // 普通的
    public static void test1(){
        Long sum = 0L;
        long start = System.currentTimeMillis();
        for (Long i = 1L; i <= 10_0000_0000; i++) {
            sum += i;
        }
        long end = System.currentTimeMillis();
        System.out.println("总时间：" + (end-start) + " sum=" + sum);
    }

    // 使用ForkJoin
    public static void test2() throws ExecutionException, InterruptedException {
        long start = System.currentTimeMillis();

        ForkJoinPool forkJoinPool = new ForkJoinPool();
        ForkJoinTask<Long> task = new MyForkJoin(0L, 10_0000_0000L);
        ForkJoinTask<Long> submit = forkJoinPool.submit(task);
        Long sum = submit.get();

        long end = System.currentTimeMillis();
        System.out.println("总时间：" + (end-start) + " sum=" + sum);
    }

    // Stream并行流
    public static void test3(){
        long start = System.currentTimeMillis();

        Long sum = LongStream.rangeClosed(0L, 10_0000_0000L)
                .parallel()
                .reduce(0, Long::sum);

        long end = System.currentTimeMillis();
        System.out.println("总时间：" + (end-start) + " sum=" + sum);
    }

}
```

# 异步回调

- 异步执行、成功回调、失败回调

```java
package juc.Future;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

public class MyFuture {
    public static void main(String[] args) throws ExecutionException, InterruptedException {
//        // 没有返回值的异步回调
//        CompletableFuture<Void> completableFuture = CompletableFuture.runAsync(()->{
//            try {
//                TimeUnit.SECONDS.sleep(2);
//            } catch (InterruptedException e) {
//                e.printStackTrace();
//            }
//            System.out.println(Thread.currentThread().getName() + "runAsync->void");
//        });
//
//        System.out.println("77777");
//        completableFuture.get();// 获取执行结果

        // 有返回值的异步回调
        CompletableFuture<Integer> uCompletableFuture = CompletableFuture.supplyAsync(() -> {
            System.out.println(Thread.currentThread().getName() + "supplyAsync->Integer");
            int i = 10/0;
            return 1024;
        });

        System.out.println(uCompletableFuture.whenComplete((t, u) -> {
            System.out.println("t=" + t);// 正常的返回
            System.out.println("u=" + u);// 错误信息
        }).exceptionally((e) -> {
            System.out.println(e.getMessage());
            return 404;// 可以获取到错误的返回结果
        }).get());

    }
}
```

# JMM

- java内存模型，不存在，只是概念、约定
- 线程解锁前：必须把共享变量立刻刷回主存
- 线程加锁前：必须读取主存中最新值到工作内存中
- 加锁解锁必须是同一把锁
- 八种操作
  - lock：作用于主内存的变量，它把有个变量表示为一个线程独占的状态
  - unlock：作用于主内存的变量，它把一个锁定状态的变量解锁，解锁之后的变量才可以被其他变量锁定
  - read：作用于主内存的变量，它把一个变量的值从主内存传输到线程的工作内存当中
  - load：作用于工作内存的变量，它把 load 操作从主内存中得到的变量的值放入工作内存的变量副本当中
  - use：作用于工作内存的变量，它把工作内存中的变量传递给执行引擎，每当虚拟机需要使用一个变量的值时就会只执行这个操作
  - assign：作用于工作内存的变量，它把从执行引擎接收到的值赋给工作内存中的变量，每当虚拟机遇到一个给变量赋值的字节码是执行操作
  - store：作用于工作内存的变量，它把工作内存中一个变量的值传送到主内存中，以便 write 使用
  - write：作用于主内存的变量，它把 store 操作从工作内存中得到的变量的值放到主内存的变量中
  - 要求
    - 不允许 read 和 load、store 和 write 操作之一单独出现，即：不允许一个变量从主内存中读取但是工作内存不接受，或者从工作内存发起会写了但是主内存不接受的情况出现
    - 不允许一个线程丢失了它的最近的 assign 操作，即：变量在工作内存中改变了之后必须把该变量同步到主内存当中
    - 不允许一个线程无原因（没有发生过任何 assign 操作）把数据从线程的工作内存同步回主内存
      一个新的变量只能在主内存中诞生（初始化）
    - 不允许在工作内存中直接使用一个未被初始化（load 或 assign）的变量，即：就是对一个变量实施 use、store 操作之前，必须先执行 assign 和 load 操作
    - 一个变量在同一个时刻只允许一个 lock 对其操作，但是 lock 操作可以被一个线程多次执行。执行多次 lock 之后只有执行相同的 unlock 变量才可以被其他线程使用
    - 如果对一个变量执行 lock 操作，那将会清空工作内存中此变量的值，在执行引擎使用这个变量之前，需要重新执行 load 或 assign 操作进行初始化
    - 如果一个变量实现没有被执行 lock 操作，那么无法执行 unlock 操作
    - 对一个变量执行 unlock 操作之前必须先把此变量同步到主内存当中（store、write 操作）
      

# Volatile

- jvm提供的==轻量级的同步机制==
- 保证可见性
- ==不保证原子性==
- 禁止指令重排：源代码，编译器优化的重排，指令并行重排，内存系统重排，执行

```java
package juc;

import java.util.concurrent.TimeUnit;

public class MyVolatile {

    // 加volatile可以保证可见性
    private volatile static int num = 0;

    public static void main(String[] args) {
        new Thread(()->{// 线程对主内存的变化不知道
            while (num == 0) {
            }
        }).start();

        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        num = 1;
        System.out.println(num);
    }
}
```

```java
package juc;

public class MyV {
    private volatile static int num = 0;

    public static void main(String[] args) {
        for (int i = 0; i < 20; i++) {
            new Thread(()->{
                for (int j = 0; j < 1000; j++) {
                    add();
                }
            }).start();
        }

        while (Thread.activeCount() > 2){
            Thread.yield();
        }

        System.out.println(Thread.currentThread().getName() + " " + num);// 结果小于20000
    }

    public static void add(){// 加synchronized可以保证原子性
        num++;
    }
}
```

# CAS

## CAS

缺点：循环会耗时；一次性只能保持一个共享变量的原子性；ABA问题

```java
package juc.cas;

import java.util.concurrent.atomic.AtomicInteger;

public class CASDemo {

    // CAS  compareAndSet比较并交换 是CPU的并发原语
    public static void main(String[] args) {
        AtomicInteger atomicInteger = new AtomicInteger(2020);
        // 如果是期望的值就更新，否则一直循环
        System.out.println(atomicInteger.compareAndSet(2020, 2021));// true
        System.out.println(atomicInteger.get());
        atomicInteger.getAndIncrement();// 2021

        System.out.println(atomicInteger.compareAndSet(2020, 2021));// false
        System.out.println(atomicInteger.get());// 2022

    }
}
```

- ABA问题

```java
package juc.cas;

import java.util.concurrent.atomic.AtomicInteger;

public class CASDemo {

    public static void main(String[] args) {
        AtomicInteger atomicInteger = new AtomicInteger(2020);
        // A对资源操作过了，又改回去了
        System.out.println(atomicInteger.compareAndSet(2020, 2021));// true
        System.out.println(atomicInteger.get());
        System.out.println(atomicInteger.compareAndSet(2021, 2020));// true
        System.out.println(atomicInteger.get());

        // B不知情
        System.out.println(atomicInteger.compareAndSet(2020, 2022));// true
        System.out.println(atomicInteger.get());

    }
}
```

- 原子引用解决ABA问题

```java
package juc.cas;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicStampedReference;

public class CASDemo {

    public static void main(String[] args) {
        // !如果泛型是一个包装类，注意对象的引用问题
        // 带版本号的原子操作
        AtomicStampedReference<Integer> atomicInteger = new AtomicStampedReference<>(1, 1);

        new Thread(()->{
            // 获得版本号
            System.out.println("A1->" + atomicInteger.getStamp());

            try {
                TimeUnit.SECONDS.sleep(2);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            System.out.println(atomicInteger.compareAndSet(1, 2,
                    atomicInteger.getStamp(), atomicInteger.getStamp() + 1));
            System.out.println("A2->" + atomicInteger.getStamp());

            System.out.println(atomicInteger.compareAndSet(2, 1,
                    atomicInteger.getStamp(), atomicInteger.getStamp() + 1));
            System.out.println("A3->" + atomicInteger.getStamp());

        },"A").start();

        // 乐观锁原理相同
        new Thread(()->{
            int stamp = atomicInteger.getStamp();// 获得版本号
            System.out.println("B1->" + atomicInteger.getStamp());

            try {
                TimeUnit.SECONDS.sleep(2);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            System.out.println(atomicInteger.compareAndSet(1, 6, stamp, stamp + 1));
            System.out.println("B2->" + atomicInteger.getStamp());

        },"B").start();
    }
}
```

- 注意！：Integer有对象缓存机制



## Unsafe类

```java
@IntrinsicCandidate
public final int getAndAddInt(Object o, long offset, int delta) {
    int v;
    do {
        v = getIntVolatile(o, offset);
    } while (!weakCompareAndSetInt(o, offset, v, v + delta));// 获取内存地址中的值，自旋锁
    return v;
}
```

```java
public final int getAndIncrement() {
    return U.getAndAddInt(this, VALUE, 1);
}
```

## 各种锁的理解

- 公平锁：不能插队，必须先来后到
- 非公平锁：可以插队，默认都是非公平

```java
public ReentrantLock() {
    sync = new NonfairSync();
}

public ReentrantLock(boolean fair) {
    sync = fair ? new FairSync() : new NonfairSync();
}
```

- 可重入锁：拿到外面的锁，就可以拿到里面的锁，自动获得

```java
package juc.lock;

public class Demo1 {
    public static void main(String[] args) {
        Phone phone = new Phone();
        new Thread(()->{
            phone.sms();
        }, "A").start();

        new Thread(()->{
            phone.sms();
        }, "B").start();

        /**
         * Asms
         * Acall
         * Bsms
         * Bcall
         */
    }
}

class Phone{
    public synchronized void sms(){
        System.out.println(Thread.currentThread().getName() + "sms");
        call();
    }

    public synchronized void call(){
        System.out.println(Thread.currentThread().getName() + "call");
    }
}
```

```java
package juc.lock;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class Demo2 {
    public static void main(String[] args) {
        Phone2 phone = new Phone2();
        new Thread(()->{
            phone.sms();
        }, "A").start();

        new Thread(()->{
            phone.sms();
        }, "B").start();

        /**
         * Asms
         * Acall
         * Bsms
         * Bcall
         */
    }
}

class Phone2{
    Lock lock = new ReentrantLock();

    public void sms(){

        lock.lock();// 和call的锁不同，是两把锁
        try {
            System.out.println(Thread.currentThread().getName() + "sms");
            call();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }

    public void call(){

        lock.lock();
        try {
            System.out.println(Thread.currentThread().getName() + "call");
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }
}
```

- 自旋锁

```java
package juc.lock;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

public class MySpinlock {
    AtomicReference<Thread> atomicReference = new AtomicReference<>();
    // 加锁
    public void myLock() {
        Thread thread = Thread.currentThread();
        System.out.println(Thread.currentThread().getName() + " -> mylock");

        // 自旋锁
        while (!atomicReference.compareAndSet(null, thread)){

        }
    }

    // 解锁
    public void myUnLock() {
        Thread thread = Thread.currentThread();
        System.out.println(Thread.currentThread().getName() + " -> myUnlock");
        atomicReference.compareAndSet(thread, null);
    }

    public static void main(String[] args) throws InterruptedException {
        MySpinlock mySpinlock = new MySpinlock();
        new Thread(()->{
            mySpinlock.myLock();
            try {
                TimeUnit.SECONDS.sleep(3);
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                mySpinlock.myUnLock();
            }
        }, "A").start();

        TimeUnit.SECONDS.sleep(1);

        new Thread(()->{
            mySpinlock.myLock();
            try {
                TimeUnit.SECONDS.sleep(3);
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                mySpinlock.myUnLock();
            }
        }, "B").start();

        /**
         * A -> mylock
         * B -> mylock
         * A -> myUnlock
         * B -> myUnlock
         */
    }
}
```

- 死锁
  - 使用“jps -l”定位进程号
  - 使用“jstack 进程号”寻找死锁问题

