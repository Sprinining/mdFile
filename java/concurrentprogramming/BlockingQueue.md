---
title: BlockingQueue
date: 2024-07-26 09:30:46 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, BlockingQueue, JUC]
description: 
---
BlockingQueue 是 Java 中的一个接口，它代表了一个==线程安全==的队列，不仅可以由多个线程并发访问，还添加了==等待/通知机制==，以便在队列为空时阻塞获取元素的线程，直到队列变得可用，或者在队列满时阻塞插入元素的线程，直到队列变得可用。

最常见的"生产者-消费者"问题中，队列通常被视作线程间的数据容器，生产者将“生产”出来的数据放入数据容器，消费者从“数据容器”中获取数据，这样，生产者线程和消费者线程就解耦了，各自只需要专注自己的业务即可。

阻塞队列（BlockingQueue）被广泛用于“生产者-消费者”问题中，其原因是 BlockingQueue 提供了可阻塞的插入和移除方法。**当队列容器已满，生产者线程会被阻塞，直到队列未满；当队列容器为空时，消费者线程会被阻塞，直至队列非空时为止**

## 基本操作

------

由于 BlockingQueue 继承了 Queue 接口，因此，BlockingQueue 也具有 Queue 接口的基本操作，如下所示：

### 插入元素

- `boolean add(E e)` ：将元素添加到队列尾部，如果队列满了，则抛出异常 IllegalStateException。

- `boolean offer(E e)`：将元素添加到队列尾部，如果队列满了，则返回 false。

### 删除元素

- `boolean remove(Object o)`：从队列中删除元素，成功返回`true`，失败返回`false`

- `E poll()`：检索并删除此队列的头部，如果此队列为空，则返回null。

### 查找元素

- `E element()`：检索但不删除此队列的头部，如果队列为空时则抛出 NoSuchElementException 异常；

- `peek()`：检索但不删除此队列的头部，如果此队列为空，则返回 null.

除了从 Queue 接口 继承到一些方法，BlockingQueue 自身还定义了一些其他的方法，

比如说插入操作：

- `void put(E e)`：将元素添加到队列尾部，如果队列满了，则线程将阻塞直到有空间。

- `offer(E e, long timeout, TimeUnit unit)`：将指定的元素插入此队列中，如果队列满了，则等待指定的时间，直到队列可用。

比如说删除操作：

- `take()`：检索并删除此队列的头部，如有必要，则等待直到队列可用；

- `poll(long timeout, TimeUnit unit)`：检索并删除此队列的头部，如果需要元素变得可用，则等待指定的等待时间。

## ArrayBlockingQueue

------

BlockingQueue 接口的实现类有 ArrayBlockingQueue、DelayQueue、LinkedBlockingDeque、LinkedBlockingQueue、LinkedTransferQueue、PriorityBlockingQueue、SynchronousQueue 等。

**ArrayBlockingQueue** 它是一个基于数组的有界阻塞队列：

- 有界：ArrayBlockingQueue 的==大小是在构造时就确定了==，并且在之后不能更改。这个界限提供了流量控制，有助于资源的合理使用。
- FIFO：队列操作符合先进先出的原则。
- 当队列容量满时，尝试将元素放入队列将导致阻塞；尝试从一个空的队列取出元素也会阻塞。

ArrayBlockingQueue 并不能保证绝对的公平，所谓公平是指严格按照线程等待的绝对时间顺序，即最先等待的线程能够最先访问到 ArrayBlockingQueue。这是因为还有其他系统级别的因素，如线程调度，可能会影响到实际的执行顺序。如果需要公平的 ArrayBlockingQueue，可在声明的时候设置公平标志为 true：

```java
private static ArrayBlockingQueue<Integer> blockingQueue = new ArrayBlockingQueue<Integer>(10, true);
```

### 成员变量

```java
public class ArrayBlockingQueue<E> extends AbstractQueue<E>
        implements BlockingQueue<E>, java.io.Serializable {

    /**
     * Serialization ID. This class relies on default serialization
     * even for the items array, which is default-serialized, even if
     * it is empty. Otherwise it could not be declared final, which is
     * necessary here.
     */
    private static final long serialVersionUID = -817911632652898426L;

    /** The queued items */
    // 用于存储队列元素的数组。队列的大小在构造时定义，并且在生命周期内不会改变。
    final Object[] items;

    /** items index for next take, poll, peek or remove */
    // 这个索引用于下一个 take、poll、peek 或 remove 操作。它指向当前可被消费的元素位置。
    int takeIndex;

    /** items index for next put, offer, or add */
    // 这个索引用于下一个 put、offer 或 add 操作。它指向新元素将被插入的位置。
    int putIndex;

    /** Number of elements in the queue */
    // 这是队列中当前元素的数量。当达到数组大小时，进一步的 put 操作将被阻塞。
    int count;

    /*
     * Concurrency control uses the classic two-condition algorithm
     * found in any textbook.
     */

    /** Main lock guarding all access */
    // 用于保护队列访问的 ReentrantLock 对象。所有的访问和修改队列的操作都需要通过这个锁来同步。
    final ReentrantLock lock;

    /** Condition for waiting takes */
    // 这个条件 Condition 用于等待 take 操作。当队列为空时，尝试从队列中取元素的线程将等待这个条件。
    private final Condition notEmpty;

    /** Condition for waiting puts */
    // 这个条件 Condition 用于等待 put 操作。当队列已满时，尝试向队列中添加元素的线程将等待这个条件。
    private final Condition notFull;
    
    ...
```

### 构造方法

```java
public ArrayBlockingQueue(int capacity) {
    this(capacity, false);
}

public ArrayBlockingQueue(int capacity, boolean fair) {
    if (capacity <= 0)
        throw new IllegalArgumentException();
    this.items = new Object[capacity];
    lock = new ReentrantLock(fair);
    notEmpty = lock.newCondition();
    notFull =  lock.newCondition();
}

public ArrayBlockingQueue(int capacity, boolean fair,
                          Collection<? extends E> c) {
    this(capacity, fair);
	...
}
```

### put 方法

```java
public void put(E e) throws InterruptedException {
    // 确保传入的元素不为null
    checkNotNull(e);
    final ReentrantLock lock = this.lock;

    // 请求锁，如果线程被中断则抛出异常
    lock.lockInterruptibly();
    try {
        // 循环检查队列是否已满，如果满了则在notFull条件上等待
        while (count == items.length) {
            notFull.await();
        }
        // 队列未满，将元素加入队列
        enqueue(e);
    } finally {
        // 在try块后释放锁，确保锁最终被释放
        lock.unlock();
    }
}

private void enqueue(E x) {
    // assert lock.getHoldCount() == 1;
    // assert items[putIndex] == null;
    final Object[] items = this.items;
	//插入数据
    items[putIndex] = x;
    if (++putIndex == items.length)
        putIndex = 0;
    count++;
	//通知消费者线程，当前队列中有数据可供消费
    notEmpty.signal();
}
```

### take 方法

```java
public E take() throws InterruptedException {
    final ReentrantLock lock = this.lock;
    lock.lockInterruptibly();
    try {
		//如果队列为空，没有数据，将消费者线程移入等待队列中
        while (count == 0)
            notEmpty.await();
		//获取数据
        return dequeue();
    } finally {
        lock.unlock();
    }
}

private E dequeue() {
    // assert lock.getHoldCount() == 1;
    // assert items[takeIndex] != null;
    final Object[] items = this.items;
    @SuppressWarnings("unchecked")
	//获取数据
    E x = (E) items[takeIndex];
    items[takeIndex] = null;
    if (++takeIndex == items.length)
        takeIndex = 0;
    count--;
    if (itrs != null)
        itrs.elementDequeued();
    //通知被阻塞的生产者线程
	notFull.signal();
    return x;
}
```

put 和 take 方法主要通过 Condition 的通知机制来完成阻塞式的数据生产和消费。

### 示例

```java
public class Main {
    private static final ArrayBlockingQueue<Integer> blockingQueue = new ArrayBlockingQueue<>(5);

    public static void main(String[] args) {
        new Thread(new Producer()).start();
        new Thread(new Consumer()).start();
    }

    static class Producer implements Runnable {

        @Override
        public void run() {
            for (int i = 0; i < 20; i++) {
                try {
                    blockingQueue.put(i);
                    System.out.println("produce: " + i);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }


    static class Consumer implements Runnable {

        @Override
        public void run() {
            for (int i = 0; i < 20; i++) {
                try {
                    blockingQueue.take();
                    System.out.println("consume: " + i);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
```

## LinkedBlockingQueue

------

LinkedBlockingQueue 是一个基于链表的线程安全的阻塞队列：

- 可以在队列头部和尾部进行高效的插入和删除操作。
- 当队列为空时，取操作会被阻塞，直到队列中有新的元素可用。当队列已满时，插入操作会被阻塞，直到队列有可用空间。
- 可以在构造时指定最大容量。如果不指定，默认为 Integer.MAX_VALUE，这意味着队列的大小受限于可用内存。

### 成员变量

```java
/** Current number of elements */
// 表示队列中当前元素的数量。通过原子操作保证其线程安全。
private final AtomicInteger count = new AtomicInteger();

/**
 * Head of linked list.
 * Invariant: head.item == null
 */
// 队列的头部节点。由于这是一个 FIFO 队列，所以元素总是从头部移除。头部节点的 item 字段始终为 null，它作为一个虚拟节点，用于帮助管理队列。
transient Node<E> head;

/**
 * Tail of linked list.
 * Invariant: last.next == null
 */
// 队列的尾部节点。新元素总是插入到尾部。
private transient Node<E> last;

/** Lock held by take, poll, etc */
// takeLock 用于控制取操作
private final ReentrantLock takeLock = new ReentrantLock();

/** Wait queue for waiting takes */
// 当队列为空时，尝试从队列中取出元素的线程将会在 notEmpty 上等待。当新元素被放入队列时，这些等待的线程将会被唤醒。
private final Condition notEmpty = takeLock.newCondition();

/** Lock held by put, offer, etc */
// putLock 用于控制放入操作，这样的设计使得放入和取出操作能够在一定程度上并行执行，从而提高队列的吞吐量。
private final ReentrantLock putLock = new ReentrantLock();

/** Wait queue for waiting puts */
// 当队列已满时，尝试向队列中放入元素的线程将会在 notFull 上等待，等待队列有可用空间时被唤醒。
private final Condition notFull = putLock.newCondition();
```

### 构造方法

```java
public LinkedBlockingDeque() {
    this(Integer.MAX_VALUE);
}

public LinkedBlockingDeque(int capacity) {
    if (capacity <= 0) throw new IllegalArgumentException();
    this.capacity = capacity;
}

public LinkedBlockingDeque(Collection<? extends E> c) {
    this(Integer.MAX_VALUE);
    ...
}
```

### 链表的 Node 节点

```java
static final class Node<E> {
    /**
     * The item, or null if this node has been removed.
     */
    // 存储节点包含的元素
    E item;

    /**
     * One of:
     * - the real predecessor Node
     * - this Node, meaning the predecessor is tail
     * - null, meaning there is no predecessor
     */
    // 表示节点在队列中的前驱节点。这个字段有三个可能的值：前驱节点的实际引用;此节点自身的引用，意味着前驱节点是尾节点的上一个节点;null，表示没有前驱节点，也就是说此节点是队列的第一个实际节点。
    Node<E> prev;

    /**
     * One of:
     * - the real successor Node
     * - this Node, meaning the successor is head
     * - null, meaning there is no successor
     */
     // 表示节点在队列中的后继节点。这个字段有三个可能的值：后继节点的实际引用;此节点自身的引用，意味着后继节点是头节点的下一个节点;null，表示没有后继节点，也就是说此节点是队列的最后一个节点。
    Node<E> next;

    Node(E x) {
        item = x;
    }
}
```

### put 方法

```java
public void put(E e) throws InterruptedException {
    // 如果传入的元素为 null，则抛出 NullPointerException。LinkedBlockingQueue 不允许插入 null 元素。
    if (e == null) throw new NullPointerException();
    // Note: convention in all put/take/etc is to preset local var
    // holding count negative to indicate failure unless set.
    // 用于存储操作前的队列元素数量，预设为 -1 表示失败，除非稍后设置。
    int c = -1;
    // 创建一个新的节点包含要插入的元素 e。
    Node<E> node = new Node<E>(e);
    // 获取队列的锁和计数器对象。
    final ReentrantLock putLock = this.putLock;
    final AtomicInteger count = this.count;
    // 尝试获取用于插入操作的锁，如果线程被中断，则抛出 InterruptedException。
    putLock.lockInterruptibly();
    try {
        /*
         * Note that count is used in wait guard even though it is
         * not protected by lock. This works because count can
         * only decrease at this point (all other puts are shut
         * out by lock), and we (or some other waiting put) are
         * signalled if it ever changes from capacity. Similarly
         * for all other uses of count in other wait guards.
         */
		// 如果队列已满，则阻塞当前线程，将其移入等待队列
        while (count.get() == capacity) {
            notFull.await();
        }
		// 入队操作，插入数据
        enqueue(node);
        // 获取并递增队列的元素计数
        c = count.getAndIncrement();
		// 若队列满足插入数据的条件，则通知被阻塞的生产者线程
        if (c + 1 < capacity)
            notFull.signal();
    } finally {
        putLock.unlock();
    }
    if (c == 0)
        // 如果插入操作将队列从空变为非空，则唤醒可能正在等待非空队列的消费者线程。
        signalNotEmpty();
}
```

### take 方法

```java
public E take() throws InterruptedException {
    E x;
    int c = -1;
    final AtomicInteger count = this.count;
    final ReentrantLock takeLock = this.takeLock;
    takeLock.lockInterruptibly();
    try {
		// 当前队列为空，则阻塞当前线程，将其移入到等待队列中，直至满足条件
        while (count.get() == 0) {
            notEmpty.await();
        }
		// 移除队头元素，获取数据
        x = dequeue();
        c = count.getAndDecrement();
        // 如果当前满足移除元素的条件，则通知被阻塞的消费者线程
		if (c > 1)
            notEmpty.signal();
    } finally {
        takeLock.unlock();
    }
    if (c == capacity)
        signalNotFull();
    return x;
}
```

## ArrayBlockingQueue 与 LinkedBlockingQueue 的比较

------

**相同点**：

- ArrayBlockingQueue 和 LinkedBlockingQueue 都是通过 Condition 通知机制来实现可阻塞的插入和删除。

**不同点**：

- ArrayBlockingQueue 基于数组实现，而 LinkedBlockingQueue 基于链表实现；

- ArrayBlockingQueue 使用一个单独的 ReentrantLock 来控制对队列的访问，而 LinkedBlockingQueue 使用两个锁（putLock 和 takeLock），一个用于放入操作，另一个用于取出操作。这可以提供更细粒度的控制，并可能减少线程之间的竞争。

## PriorityBlockingQueue

------

PriorityBlockingQueue 是一个具有优先级排序特性的无界阻塞队列。元素在队列中的排序遵循自然排序或者通过提供的比较器进行定制排序。你可以通过实现 Comparable 接口来定义自然排序。

```java
class Task implements Comparable<Task> {
    private final int priority;
    private final String name;

    public Task(int priority, String name) {
        this.priority = priority;
        this.name = name;
    }

    public int compareTo(Task other) {
        return Integer.compare(other.priority, this.priority);
    }

    public String getName() {
        return name;
    }
}


public class Main {
    public static void main(String[] args) throws InterruptedException {
        PriorityBlockingQueue<Task> queue = new PriorityBlockingQueue<>();
        queue.put(new Task(1, "Low priority task"));
        queue.put(new Task(50, "High priority task"));
        queue.put(new Task(10, "Medium priority task"));

        while (!queue.isEmpty()) {
            System.out.println(queue.take().getName());
        }
    }
}
```

## SynchronousQueue

------

SynchronousQueue 是一个非常特殊的阻塞队列，它不存储任何元素。每一个插入操作必须等待另一个线程的移除操作，反之亦然。因此，SynchronousQueue 的内部实际上是空的，但它允许一个线程向另一个线程逐个传输元素。

SynchronousQueue 允许线程直接将元素交付给另一个线程。因此，如果一个线程尝试插入一个元素，并且有另一个线程尝试移除一个元素，则插入和移除操作将同时成功。

```java
public class Main {
    public static void main(String[] args) {
        SynchronousQueue<String> queue = new SynchronousQueue<>();

        new Thread(() -> {
            try {
                String event = "SYNCHRONOUS_EVENT";
                System.out.println("Putting: " + event);
                queue.put(event);
                System.out.println("Put successfully: " + event);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "生产者").start();

        new Thread(() -> {
            try {
                String event = queue.take();
                System.out.println("Taken: " + event);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "消费者").start();
    }
}
```

## LinkedTransferQueue

------

LinkedTransferQueue 是一个基于链表结构的无界传输队列，实现了 TransferQueue 接口，它提供了一种强大的线程间交流机制。它的功能与其他阻塞队列类似，但还包括“转移”语义：允许一个元素直接从生产者传输给消费者，如果消费者已经在等待。如果没有等待的消费者，元素将入队。

常用方法有两个：

- `transfer(E e)`，将元素转移到等待的消费者，如果不存在等待的消费者，则元素会入队并阻塞直到该元素被消费。
- `tryTransfer(E e)`，尝试立即转移元素，如果有消费者正在等待，则传输成功；否则，返回 false。

```java
public class Main {
    public static void main(String[] args) throws InterruptedException {
        LinkedTransferQueue<String> queue = new LinkedTransferQueue<>();

        new Thread(() -> {
            try {
                System.out.println("消费者正在等待获取元素...");
                String element = queue.take();
                System.out.println("消费者收到: " + element);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "消费者").start();

        // 让消费者线程先开始执行
        TimeUnit.SECONDS.sleep(1);

        // 生产者
        System.out.println("生产者正在传输元素");
        queue.transfer("Hello, World!");

        System.out.println("生产者已转移元素");
    }
}
```

## LinkedBlockingDeque

------

LinkedBlockingDeque 是一个基于链表结构的双端阻塞队列。它同时支持从队列头部插入和移除元素，也支持从队列尾部插入和移除元素。因此，LinkedBlockingDeque 可以作为 FIFO 队列或 LIFO 队列来使用。

常用方法有：

- `addFirst(E e)`, `addLast(E e)`: 在队列的开头/结尾添加元素。
- `takeFirst()`, `takeLast()`: 从队列的开头/结尾移除和返回元素，如果队列为空，则等待。
- `putFirst(E e)`, `putLast(E e)`: 在队列的开头/结尾插入元素，如果队列已满，则等待。
- `pollFirst(long timeout, TimeUnit unit)`, `pollLast(long timeout, TimeUnit unit)`: 在队列的开头/结尾移除和返回元素，如果队列为空，则等待指定的超时时间。

```java
public class Main {
    public static void main(String[] args) throws InterruptedException {
        LinkedBlockingDeque<String> deque = new LinkedBlockingDeque<>(10);

        // 加到队尾
        deque.putLast("Item1");
        deque.putLast("Item2");

        // 加到队头
        deque.putFirst("Item3");

        // 移除队头
        System.out.println(deque.takeFirst()); // Output: Item3

        // 移除队尾
        System.out.println(deque.takeLast()); // Output: Item2
    }
}
```

## DelayQueue

------

DelayQueue 是一个无界阻塞队列，DelayQueue中存放的元素必须实现 Delayed 接口的元素，实现接口后相当于是每个元素都有个过期时间，当队列进行take获取元素时，先要判断元素有没有过期，只有过期的元素才能出队操作，没有过期的队列需要等待剩余过期时间才能进行出队操作。

DelayQueue 队列内部使用了 PriorityQueue 优先队列来进行存放数据，它采用的是二叉堆进行的优先队列，使用 ReentrantLock 锁来控制线程同步，由于内部元素是采用的 PriorityQueue 来进行存放数据，所以 Delayed 接口实现了 Comparable 接口，用于比较来控制优先级。

```java
public class Main {
    public static void main(String[] args) {
        DelayQueue<DelayedElement> queue = new DelayQueue<>();

        // 将带有5秒延迟的元素放入队列
        queue.put(new DelayedElement(5000, "这是一个 5 秒延迟的元素"));

        try {
            System.out.println("取一个元素...");
            // take() 将阻塞，直到延迟到期
            DelayedElement element = queue.take();
            System.out.println(element.getMessage());
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    static class DelayedElement implements Delayed {
        private final long delayUnit;
        private final String message;

        public DelayedElement(long delayInMillis, String message) {
            this.delayUnit = System.currentTimeMillis() + delayInMillis;
            this.message = message;
        }

        public String getMessage() {
            return message;
        }

        @Override
        public long getDelay(TimeUnit unit) {
            return unit.convert(delayUnit - System.currentTimeMillis(), TimeUnit.MILLISECONDS);
        }

        @Override
        public int compareTo(Delayed o) {
            return Long.compare(this.delayUnit, ((DelayedElement) o).delayUnit);
        }
    }
}
```

## 关于 final

------

源码中总是有 `final ReentrantLock lock = this.lock;` 这种写法。目的有两个：

- 将全局变量赋值给方法的一个局部变量，访问的时候直接在线程栈里面取，比访问成员变量速度要快，读取栈里面的变量只需要一条指令，读取成员变量则需要两条指令。
- 加了 `final` 原因就是为了多线程下的线程安全。一经初始化就无法被更改，并且保证对象访问的内存重排序，保证对象的可见性。（当final变量为对象或者数组时，可以改变对象的域或者数组中的元素）

