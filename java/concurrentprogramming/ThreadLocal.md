---
title: ThreadLocal
date: 2024-07-27 02:29:38 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, ThreadLocal]
description: 
---
ThreadLocal 是 Java 中提供的一种用于实现线程局部变量的工具类。它允许每个线程都拥有自己的独立副本，从而实现线程隔离，用于解决多线程中共享对象的线程安全问题。

通常，我们会使用 synchronzed 关键字 或者 lock 来控制线程对临界区资源的同步顺序，但这种加锁的方式会让未获取到锁的线程进行阻塞，很显然，这种方式的时间效率不会特别高。

**线程安全问题的核心在于多个线程会对同一个临界区的共享资源进行访问**，那如果每个线程都拥有自己的“共享资源”，各用各的，互不影响，这样就不会出现线程安全的问题了。

事实上，这就是一种“**空间换时间**”的思想，每个线程拥有自己的“共享资源”，虽然内存占用变大了，但由于不需要同步，也就减少了线程可能存在的阻塞问题，从而提高时间上的效率。

顾名思义，**ThreadLocal 就是线程的“本地变量”，即每个线程都拥有该变量的一个副本，达到人手一份的目的，这样就可以避免共享资源的竞争**。

## ThreadLocal 的源码分析

### set 方法

**set 方法用于设置当前线程中 ThreadLocal 的变量值**，该方法的源码如下：

```java
public void set(T value) {
	// 获取当前线程实例对象
    Thread t = Thread.currentThread();

	// 通过当前线程实例获取到ThreadLocalMap对象
    ThreadLocalMap map = getMap(t);

    if (map != null)
	   // 如果Map不为null,则以当前ThreadLocal实例为key,值为value进行存入
       map.set(this, value);
    else
	   // map为null,则新建ThreadLocalMap并存入value
       createMap(t, value);
}
```

- 通过 `Thread.currentThread()` 方法获取当前调用此方法的线程实例。
- 每个线程都有自己的 ThreadLocalMap，这个映射表存储了线程的局部变量，其中键是 ThreadLocal 对象，值为特定于线程的对象。
- 如果 Map 不为 null，则以当前 ThreadLocal 实例为 key，值为 value 进行存入；如果 map 为 null，则新建 ThreadLocalMap 并存入 value。

**ThreadLocalMap 是怎样来的呢**？通过`getMap(t)`：

```java
ThreadLocalMap getMap(Thread t) {
    return t.ThreadLocals;
}
```

该方法直接返回当前线程对象 t 的一个成员变量 ThreadLocals：

```java
/* ThreadLocal values pertaining to this thread. This map is maintained
 * by the ThreadLocal class. */
ThreadLocal.ThreadLocalMap ThreadLocals = null;
```

再来看 set 方法，当 map 为 null 的时候会通过`createMap(t，value)`方法 new 出来一个：

```java
void createMap(Thread t, T firstValue) {
    t.ThreadLocals = new ThreadLocalMap(this, firstValue);
}
```

该方法 new 了一个 ThreadLocalMap 实例对象，然后以当前 ThreadLocal 实例作为 key，值为 value 存放到 ThreadLocalMap 中，然后将当前线程对象的 ThreadLocals 赋值为 ThreadLocalMap 对象。

set 方法的重要性在于它确保了每个线程都有自己的变量副本。由于这些变量是存储在与线程关联的映射表中的，所以不同的线程之间的这些变量互不影响。

### get 方法

**get 方法用于获取当前线程中 ThreadLocal 的变量值**，同样的还是来看源码：

```java
public T get() {
  // 获取当前线程的实例对象
  Thread t = Thread.currentThread();

  // 获取当前线程的ThreadLocalMap
  ThreadLocalMap map = getMap(t);
  if (map != null) {
	// 获取map中当前ThreadLocal实例为key的值的entry
    ThreadLocalMap.Entry e = map.getEntry(this);

    if (e != null) {
      @SuppressWarnings("unchecked")
	  // 当前entitiy不为null的话，就返回相应的值value
      T result = (T)e.value;
      return result;
    }
  }
  // 若map为null或者entry为null的话通过该方法初始化，并返回该方法返回的value
  return setInitialValue();
}
```

```java
private T setInitialValue() {
    T value = initialValue();
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
    return value;
}
```

该方法的逻辑和 set 方法几乎一样，主要来看下 initialValue 方法:

```java
protected T initialValue() {
    return null;
}
```

这个**方法是通过 protected 修饰的，也就意味着 ThreadLocal 的子类可以重写该方法给一个合适的初始值**。

这里是 initialValue 方法的典型用法：

```java
private static ThreadLocal<Integer> myThreadLocal = new ThreadLocal<Integer>() {
    @Override
    protected Integer initialValue() {
        return 0; // 初始值设置为0
    }
};
```

此代码段创建了一个新的 `ThreadLocal<Integer>` 对象，其初始值为 0。任何尝试首次访问此 ThreadLocal 变量的线程都会看到值 0。

整个 setInitialValue 方法的目的是确保每个线程在第一次尝试访问其 ThreadLocal 变量时都有一个合适的值。这种“懒惰”初始化的方法确保了仅在实际需要特定于线程的值时才创建这些值。

### remove 方法

```java
public void remove() {
	// 获取当前线程的ThreadLocalMap
	ThreadLocalMap m = getMap(Thread.currentThread());
 	if (m != null)
		// 从map中删除以当前ThreadLocal实例为key的键值对
		m.remove(this);
}
```

remove 方法的作用是从当前线程的 ThreadLocalMap 中删除与当前 ThreadLocal 实例关联的条目。这个方法在释放线程局部变量的资源或重置线程局部变量的值时特别有用。

以下是使用 remove 方法的示例代码：

```java
ThreadLocal<String> threadLocal = ThreadLocal.withInitial(() -> "Initial Value");

Thread thread = new Thread(() -> {
    System.out.println(threadLocal.get()); // 输出 "Initial Value"
    threadLocal.set("Updated Value");
    System.out.println(threadLocal.get()); // 输出 "Updated Value"
    threadLocal.remove();
    System.out.println(threadLocal.get()); // 输出 "Initial Value"
});
thread.start();
```

## ThreadLocalMap 的源码分析

ThreadLocalMap 是 ThreadLocal 类的静态内部类，它是一个定制的哈希表，专门用于保存每个线程中的线程局部变量。

```java
static class ThreadLocalMap {}
```

和大多数容器一样，ThreadLocalMap 内部维护了一个 Entry 类型的数组 类型的数组 table，长度为 2 的幂次方。

```java
private Entry[] table;
```

来看下 Entry 是什么：

```java
static class Entry extends WeakReference<ThreadLocal<?>> {
    /** The value associated with this ThreadLocal. */
    Object value;

    Entry(ThreadLocal<?> k, Object v) {
        super(k);
        value = v;
    }
}
```

Entry 继承了弱引用 `WeakReference<ThreadLocal<?>>`，它的 value 字段用于存储与特定 ThreadLocal 对象关联的值。使用弱引用作为键允许垃圾收集器在不再需要的情况下回收 ThreadLocal 实例。

这里我们可以用一张图来理解下 Thread、ThreadLocal、ThreadLocalMap、Entry 之间的关系：

![ThreadLocal各引用间的关系](./ThreadLocal.assets/ThreadLocal-01.png)

上图中的实线表示强引用，虚线表示弱引用。每个线程都可以通过 ThreadLocals 获取到 ThreadLocalMap，而 ThreadLocalMap 实际上就是一个以 ThreadLocal 实例为 key，任意对象为 value 的 Entry 数组。

当我们为 ThreadLocal 变量赋值时，实际上就是以当前 ThreadLocal 实例为 key，值为 Entry 往这个 ThreadLocalMap 中存放。

注意，Entry 的 key 为弱引用，意味着当 ThreadLocal 外部强引用被置为 null（`ThreadLocalInstance=null`）时，根据可达性分析，ThreadLocal 实例此时没有任何一条链路引用它，所以系统 GC 的时候 ThreadLocal 会被回收。

这样一来，ThreadLocalMap 就会出现 key 为 null 的 Entry，也就没办法访问这些 key 对应的 value，如果线程迟迟不结束的话，这些 key 为 null 的 value 就会一直存在一条强引用链：Thread Ref -> Thread -> ThreaLocalMap -> Entry -> value，无法回收就会造成内存泄漏。

当然，如果 thread 运行结束，ThreadLocal、ThreadLocalMap、Entry 没有引用链可达，在垃圾回收时都会被系统回收。但实际开发中，线程为了复用是不会主动结束的，比如说数据库连接池，过大的线程池可能会增加内存泄漏的风险，因此合理配置线程池的大小和线程的存活时间有助于减轻这个问题。

为了避免这个问题，在每次使用完 ThreadLocal 之后，最好明确调用 ThreadLocal 的 remove 方法来删除与当前线程关联的值。这样可以确保线程再次使用时不会存储旧的、不再需要的值。

与 ConcurrentHashMap、HashMap 等容器一样，ThreadLocalMap 也是通过哈希表实现的。

### set 方法

```java
private void set(ThreadLocal<?> key, Object value) {

    // We don't use a fast path as with get() because it is at
    // least as common to use set() to create new entries as
    // it is to replace existing ones, in which case, a fast
    // path would fail more often than not.

    Entry[] tab = table;
    int len = tab.length;
	// 根据ThreadLocal的hashCode确定Entry应该存放的位置
    int i = key.ThreadLocalHashCode & (len-1);

	// 采用开放地址法，hash冲突的时候使用线性探测
    for (Entry e = tab[i];
         e != null;
         e = tab[i = nextIndex(i, len)]) {
        ThreadLocal<?> k = e.get();
		// 覆盖旧Entry
        if (k == key) {
            e.value = value;
            return;
        }
		// 当key为null时，说明ThreadLocal强引用已经被释放掉，那么就无法
		// 再通过这个key获取ThreadLocalMap中对应的entry，这里就存在内存泄漏的可能性
        if (k == null) {
			// 用当前插入的值替换掉这个key为null的“脏”entry
            replaceStaleEntry(key, value, i);
            return;
        }
    }
	// 新建entry并插入table中i处
    tab[i] = new Entry(key, value);
    int sz = ++size;
	// 插入后再次清除一些key为null的“脏”entry,如果大于阈值就需要扩容
    if (!cleanSomeSlots(i, sz) && sz >= threshold)
        rehash();
}
```

#### 01、ThreadLocal 的 hashcode

```java
private final int ThreadLocalHashCode = nextHashCode();
private static final int HASH_INCREMENT = 0x61c88647;
private static AtomicInteger nextHashCode =new AtomicInteger();
  /**
   * Returns the next hash code.
   */
  private static int nextHashCode() {
      return nextHashCode.getAndAdd(HASH_INCREMENT);
  }
```

ThreadLocal 的 hashCode 是通过 `nextHashCode()` 方法获取的，该方法实际上是用 AtomicInteger 加上 0x61c88647 来实现的。

0x61c88647 是一个魔数，用于 ThreadLocal 的哈希码递增。这个值的选择并不是随机的，它是一个质数，具有以下特性：

- 质数：它是一个质数，这意味着它不能被除 1 和它本身之外的任何数字整除。
- 黄金比例：这个数字大约等于黄金比例的 32 位浮点表示的一半。黄金比例具有一些有趣的数学特性，其中之一是与斐波那契数列的关系。
- 递增分布：在 ThreadLocal 中，这个数字用于在哈希表中分散不同线程的哈希码，从而减少冲突。每当创建新的 ThreadLocal 对象时，都会将此值添加到上一个 ThreadLocal 的哈希码中。这个递增的步长有助于在哈希表中均匀地分配 ThreadLocal 对象。
- 性能优化：通过使用这个特定的值，算法能够确保哈希码的均匀分布，从而减少哈希冲突的可能性。这对于哈希表的性能至关重要，因为冲突可能会降低查找的效率。

#### 02、怎样确定新值插入的位置？

通过这行代码：`key.ThreadLocalHashCode & (len-1)`。

同 HashMap 一样，通过当前 key 的 hashcode 与哈希表大小相与。原理我们在 HashMap 的时候已经讲过了，不记得的小伙伴可以回去看一遍。

#### 03、怎样解决 hash 冲突？

通过 `nextIndex(i, len)`，该方法中的`((i + 1 < len) ? i + 1 : 0);` 能不断往后线性探测，当到哈希表末尾的时候再从 0 开始，成环形。

#### 04、怎样解决“脏”Entry？

我们知道，使用 ThreadLocal 有可能存在内存泄漏的问题，针对这种 key 为 null 的 Entry，我们称之为“stale entry”，直译为不新鲜的 entry，我把它理解为“脏 entry”。

当然了，Josh Bloch 和 Doug Lea 已经替我们考虑了这种情况，源码中提供了这些解决方案：

在向ThreadLocalMap添加新条目时，可以检查是否有“脏”Entry（键为null的Entry），并用新的条目替换它。这就是源码中的replaceStaleEntry方法所做的事情。

![img](./ThreadLocal.assets/ThreadLocal-20230822211802.png)

在某些操作过程中（例如添加、获取等），可以增加额外的清理操作来扫描并移除“脏”Entry。这可以通过遍历哈希表，并删除那些键为null的条目来实现。源码中的cleanSomeSlots方法就是这样一个例子。

![img](./ThreadLocal.assets/ThreadLocal-20230822212010.png)

#### 05、如何进行扩容？

和 HashMap 一样，ThreadLocalMap 也有扩容机制，那么它的 threshold 又是怎样确定的呢？

```java
private int threshold; // Default to 0
/**
 * The initial capacity -- MUST be a power of two.
 */
private static final int INITIAL_CAPACITY = 16;

ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
    table = new Entry[INITIAL_CAPACITY];
    int i = firstKey.ThreadLocalHashCode & (INITIAL_CAPACITY - 1);
    table[i] = new Entry(firstKey, firstValue);
    size = 1;
    setThreshold(INITIAL_CAPACITY);
}

/**
 * Set the resize threshold to maintain at worst a 2/3 load factor.
 */
private void setThreshold(int len) {
    threshold = len * 2 / 3;
}
```

在第一次对 ThreadLocal 赋值的时候会创建初始大小为 16 的 ThreadLocalMap，并且通过 setThreshold 方法设置 threshold，其值为当前哈希数组长度乘以（2/3），也就是说加载因子为 2/3。

加载因子（Load Factor）是哈希表的一个重要概念，它表示哈希表中已经存放的条目数量与哈希表容量的比例。加载因子可以用来衡量哈希表的满载程度，影响哈希表的查找、插入和删除操作的性能。相信大家都还记得，HashMap 的加载因子都为 0.75。

这里**ThreadLocalMap 初始大小为 16**，**加载因子为 2/3**，所以哈希表可用大小为：16*2/3=10，即哈希表可用容量为 10。

当哈希表的 size 大于 threshold 的时候，会通过 resize 方法进行扩容。

```java
/**
 * Double the capacity of the table.
 */
private void resize() {
    Entry[] oldTab = table;
    int oldLen = oldTab.length;
	//新数组为原数组的2倍
    int newLen = oldLen * 2;
    Entry[] newTab = new Entry[newLen];
    int count = 0;

    for (int j = 0; j < oldLen; ++j) {
        Entry e = oldTab[j];
        if (e != null) {
            ThreadLocal<?> k = e.get();
			//遍历过程中如果遇到脏entry的话直接另value为null,有助于value能够被回收
            if (k == null) {
                e.value = null; // Help the GC
            } else {
				//重新确定entry在新数组的位置，然后进行插入
                int h = k.ThreadLocalHashCode & (newLen - 1);
                while (newTab[h] != null)
                    h = nextIndex(h, newLen);
                newTab[h] = e;
                count++;
            }
        }
    }
	//设置新哈希表的threshHold和size属性
    setThreshold(newLen);
    size = count;
    table = newTab;
}
```

方法逻辑**请看注释**，新建的数组为原来数组长度的两倍，然后遍历旧数组中的 entry 并将其插入到新的数组中。注意，这段代码考虑得非常周全，**在扩容的过程中，针对脏 entry 会把 value 设为 null，以便被垃圾回收，解决隐藏的内存泄漏问题**。

### getEntry 方法

getEntry 方法的源码如下：

```java
private Entry getEntry(ThreadLocal<?> key) {
	// 确定在哈希数组中的位置
    int i = key.ThreadLocalHashCode & (table.length - 1);
	// 根据索引i获取entry
    Entry e = table[i];
	// 满足条件则返回该entry
    if (e != null && e.get() == key)
        return e;
    else
		// 未查找到满足条件的entry，额外在做的处理
        return getEntryAfterMiss(key, i, e);
}
```

方法的逻辑很简单，如果当前 entry 的 key 和查找的 key 相同就直接返回这个 entry，否则的就通过 getEntryAfterMiss 做进一步处理：如果索引处的条目为null，或者其键与给定的键不匹配，那么需要调用getEntryAfterMiss方法来处理可能的哈希冲突。

getEntryAfterMiss 方法如下：

```java
private Entry getEntryAfterMiss(ThreadLocal<?> key, int i, Entry e) {
    Entry[] tab = table;
    int len = tab.length;

    while (e != null) {
        ThreadLocal<?> k = e.get();
        if (k == key)
			// 找到和查询的key相同的entry则返回
            return e;
        if (k == null)
			// 解决脏entry的问题
            expungeStaleEntry(i);
        else
			// 继续向后环形查找
            i = nextIndex(i, len);
        e = tab[i];
    }
    return null;
}
```

getEntryAfterMiss 方法用于在发生哈希冲突的情况下继续在ThreadLocalMap中查找条目，通过开放寻址的策略，在哈希表中的其他位置查找，并适当地处理“脏”条目。

### remove 方法

直接来看源码：

```java
/**
 * Remove the entry for key.
 */
private void remove(ThreadLocal<?> key) {
    Entry[] tab = table;
    int len = tab.length;
    int i = key.ThreadLocalHashCode & (len-1);
    for (Entry e = tab[i];
         e != null;
         e = tab[i = nextIndex(i, len)]) {
        if (e.get() == key) {
			//将entry的key置为null
            e.clear();
			//将该entry的value也置为null
            expungeStaleEntry(i);
            return;
        }
    }
}
```

01、通过局部变量tab获取ThreadLocalMap的哈希表数组，len表示其长度。

02、通过`key.ThreadLocalHashCode & (len-1)`计算给定ThreadLocal键的哈希索引。这将决定从哪个索引位置开始搜索。

03、使用开放寻址法遍历哈希表，通过`nextIndex(i, len)`计算下一个索引以处理哈希冲突。

04、如果找到与给定键匹配的条目（即`e.get() == key`），执行以下操作：

- 清除键：通过调用`e.clear()`方法，将条目的键置为null。由于Entry是WeakReference的子类，clear方法将断开对ThreadLocal对象的引用，允许垃圾收集器在需要时回收它。
- 清除值：通过调用`expungeStaleEntry(i)`方法，清除该条目的值并对哈希表进行部分清理。该方法的目的是清除哈希表中的无效条目，即那些其键已被垃圾收集的条目。

05、结束删除操作：一旦找到并删除了匹配的条目，方法返回。如果遍历整个哈希表都没有找到匹配的键，则该方法不执行任何操作并正常返回。

## ThreadLocal 的使用场景

ThreadLocal 的使用场景非常多，比如说：

- 用于保存用户登录信息，这样在同一个线程中的任何地方都可以获取到登录信息。
- 用于保存数据库连接、Session 对象等，这样在同一个线程中的任何地方都可以获取到数据库连接、Session 对象等。
- 用于保存事务上下文，这样在同一个线程中的任何地方都可以获取到事务上下文。
- 用于保存线程中的变量，这样在同一个线程中的任何地方都可以获取到线程中的变量。

下面是一个使用ThreadLocal来保存用户登录信息的示例。这个示例适用于像Web服务器这样的多线程环境，其中每个线程处理一个独立的用户请求。

```java
public class UserAuthenticationService {

    // 创建一个ThreadLocal实例，用于保存用户登录信息
    private static ThreadLocal<User> currentUser = ThreadLocal.withInitial(() -> null);

    public static void main(String[] args) {
        // 模拟用户登录
        loginUser(new User("Alice", "password123"));
        System.out.println("User logged in: " + getCurrentUser().getUsername());

        // 模拟另一个线程处理另一个用户
        Runnable task = () -> {
            loginUser(new User("Bob", "password456"));
            System.out.println("User logged in: " + getCurrentUser().getUsername());
        };

        Thread thread = new Thread(task);
        thread.start();
    }

    // 模拟用户登录方法
    public static void loginUser(User user) {
        // 这里通常会有一些身份验证逻辑
        currentUser.set(user);
    }

    // 获取当前线程关联的用户信息
    public static User getCurrentUser() {
        return currentUser.get();
    }

    // 用户类
    public static class User {
        private final String username;
        private final String password;

        public User(String username, String password) {
            this.username = username;
            this.password = password;
        }

        public String getUsername() {
            return username;
        }

        // 其他getter和setter...
    }
}
```

这个示例定义了一个UserAuthenticationService类，该类使用ThreadLocal来保存与当前线程关联的用户登录信息。假设用户已经通过身份验证，将用户对象存储在currentUser ThreadLocal变量中。getCurrentUser方法用于检索与当前线程关联的用户信息。由于使用了ThreadLocal，因此不同的线程可以同时登录不同的用户，而不会相互干扰。
