---
title: HashMap
date: 2024-09-22 10:30:54 +0800
categories: [java, collections framework]
tags: [Java, Collections Framework, HashMap]
description: 
---
- HashMap 的实现原理是基于哈希表的，它的底层是一个数组，数组的每个位置可能是一个链表或红黑树，也可能只是一个键值对。当添加一个键值对时，HashMap 会根据键的哈希值计算出该键对应的数组下标（索引），然后将键值对插入到对应的位置。

- 当通过键查找值时，HashMap 也会根据键的哈希值计算出数组下标，并查找对应的值。
- Java 8 之前，HashMap 使用链表来解决冲突，即当两个或者多个键映射到同一个桶时，它们被放在同一个桶的链表上。当链表上的节点（Node）过多时，链表会变得很长，查找的效率（LinkedList的查找效率为 O（n））就会受到影响。
- Java 8 中，当链表的节点数超过一个阈值（8）时，链表将转为红黑树（节点为 TreeNode），红黑树是一种高效的平衡树结构，能够在 O(log n) 的时间内完成插入、删除和查找等操作。这种结构在节点数很多时，可以提高 HashMap 的性能和可伸缩性。

## hash方法原理

![hash-01](./HashMap.assets/hash-01.png)

- ==hash方法是用来做哈希值优化的==，把哈希值右移 16 位，也就正好是自己长度的一半，之后与原哈希值做异或运算，这样就混合了原哈希值中的高位和低位，==增大了随机性，让数据元素更加均衡的分布，减少碰撞==

```java
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}
```

```java
static final int hash(Object key) {
    int h;
    // 如果键值为 null，则哈希码为 0
    // 否则，通过调用hashCode()方法获取键的哈希码，并将其与逻辑右移 16 位的哈希码进行异或运算。
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```

- HashMap 扩容之前的数组初始大小只有 16，所以这个哈希值是不能直接拿来用的，用之前要和数组的长度做与运算（ `(n - 1) & hash`），用得到的值来访问数组下标才行。

### java取模取余

在 Java 中，通常使用 % 运算符来表示取余，用 `Math.floorMod()` 来表示取模。

- 当操作数都是正数的话，取模运算和取余运算的结果是一样的。
- 只有当操作数出现负数的情况，结果才会有所不同。
- ==取模运算的商向负无穷靠近；取余运算的商向 0 靠近==。
- 当数组的长度是 2 的 n 次方，或者 n 次幂，或者 n 的整数倍时，取模运算/取余运算可以用位运算来代替，效率更高。这也是==HashMap数组长度取2的整数次方的原因==

```java
public static void main(String[] args) {
    int a = -7;
    int b = 3;

    // a 对 b 取余
    int remainder = a % b;
    // a 对 b 取模
    int modulus = Math.floorMod(a, b);

    System.out.println("数字: a = " + a + ", b = " + b);
    System.out.println("取余 (%): " + remainder);
    System.out.println("取模 (Math.floorMod): " + modulus);

    // 改变 a 和 b 的正负情况
    a = 7;
    b = -3;

    remainder = a % b;
    modulus = Math.floorMod(a, b);

    System.out.println("\n数字: a = " + a + ", b = " + b);
    System.out.println("取余 (%): " + remainder);
    System.out.println("取模 (Math.floorMod): " + modulus);
    /*
        数字: a = -7, b = 3
        取余 (%): -1
        取模 (Math.floorMod): 2

        数字: a = 7, b = -3
        取余 (%): 1
        取模 (Math.floorMod): -2
     */
}
```

- 取余：余数的定义是基于常规除法的，所以它的符号总是与被除数相同。商趋向于0。例如，对于 `-7 % 3`，余数是 `-1`。因为-7/3可以有两种结果，一种是商-2余-1；一种是商-3余2，因为取余的商趋向于0，-2比-3更接近0，所以取余的结果是-1。

- 取模：取模也是基于除法的，只不过它的符号总是与除数相同。商趋向于负无穷。例如，对于 `Math.floorMod(-7, 3)`，结果是 `2`。同理，因为-7/3可以有两种结果，一种是商-2余-1；一种是商-3余2，因为取模的商趋向于负无穷，-3比-2更接近于负无穷，所以取模的结果是2。

- 当数组的长度是2的n次方时，`hash & (length - 1) = hash % length`
  - 对于``hash%length`
    - 当length为2的n次方时，从二进制角度看，hash/length 等价于 hash/(2的n次方)，等价于hash>>n，即hash算术右移n位，得到的就是hash/(2的n次方)的商，被移出去的部分就是余数hash%(2的n次方)
    - 2的n次方的二进制为1后面跟n个0（1000...)，2的n次方的二进制为n个1(1111...)
    - hash%(2的n次方)得到的就是hash低n位的值
  - 对于`hash & (length - 1)`
    - 当length为2的n次方时，hash & (length - 1)实际上是保留hash二进制表示的低n位，其他高位都被清零。所以两个式子在length位2的n次方时相等，但在计算机中位运算速度要比取余快得多。

### HashMap中的两处取模运算

- 往 HashMap 中 put 的时候（会调用私有的 `putVal` 方法）

```java
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}
```

```java
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
               boolean evict) {
    // 数组
    Node<K, V>[] tab;
    // 元素
    Node<K, V> p;
    // n为数组长度，i为下标
    int n, i;
    // 数组为空
    if ((tab = table) == null || (n = tab.length) == 0)
        // 第一次扩容后的长度
        n = (tab = resize()).length;
    // 计算节点的插入位置，如果该位置为空，则新建一个节点插入
    if ((p = tab[i = (n - 1) & hash]) == null)
        tab[i] = newNode(hash, key, value, null);
    else {
        Node<K, V> e;
        K k;
        // 节点key存在，直接覆盖value
        if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
            e = p;
        // 判断该链为红黑树
        else if (p instanceof TreeNode)
            e = ((TreeNode<K, V>) p).putTreeVal(this, tab, hash, key, value);
        // 该链为链表
        else {
            for (int binCount = 0; ; ++binCount) {
                if ((e = p.next) == null) {
                    p.next = newNode(hash, key, value, null);
                    // 链表长度大于8转换为红黑树进行处理
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        treeifyBin(tab, hash);
                    break;
                }
                // key已经存在直接覆盖value
                if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                    break;
                p = e;
            }
        }
        // 直接覆盖
        if (e != null) { // existing mapping for key
            V oldValue = e.value;
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;
            afterNodeAccess(e);
            return oldValue;
        }
    }
    ++modCount;
    // 超过最大容量 就扩容
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict);
    return null;
}
```

- 从 HashMap 中 get 的时候（会调用 `getNode` 方法）

```java
public V get(Object key) {
    Node<K, V> e;
    return (e = getNode(hash(key), key)) == null ? null : e.value;
}
```

```java
final Node<K, V> getNode(int hash, Object key) {
    // 获取当前的数组和长度，以及当前节点链表的第一个节点（根据索引直接从数组中找）
    Node<K, V>[] tab;
    Node<K, V> first, e;
    int n;
    K k;
    if ((tab = table) != null && (n = tab.length) > 0 &&
            (first = tab[(n - 1) & hash]) != null) {
        // 如果第一个节点就是要查找的节点，则直接返回
        if (first.hash == hash && // always check first node
                ((k = first.key) == key || (key != null && key.equals(k))))
            return first;
        // 如果第一个节点不是要查找的节点，则遍历节点链表查找 
        if ((e = first.next) != null) {
            if (first instanceof TreeNode)
                return ((TreeNode<K, V>) first).getTreeNode(hash, key);
            do {
                if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                    return e;
            } while ((e = e.next) != null);
        }
    }
    return null;
}
```

- `(n - 1) & hash`：key的hashCode()经过hash()计算后，再与（数组长-1）进行与运算

### 总结

- hash 方法的主要作用是将 key 的 hashCode 值进行处理，得到最终的哈希值。由于 key 的 hashCode 值是不确定的，可能会出现哈希冲突，因此需要将哈希值通过一定的算法映射到 HashMap 的实际存储位置上。

- hash 方法的原理是，先获取 key 对象的 hashCode 值，然后将其高位与低位进行异或操作，得到一个新的哈希值。为什么要进行异或操作呢？因为对于 hashCode 的高位和低位，它们的分布是比较均匀的，如果只是简单地将它们加起来或者进行位运算，容易出现哈希冲突，而异或操作可以避免这个问题。

- 然后将新的哈希值取模（mod），得到一个实际的存储位置。这个取模操作的目的是将哈希值映射到桶（Bucket）的索引上，桶是 HashMap 中的一个数组，每个桶中会存储着一个链表（或者红黑树），装载哈希值相同的键值对（没有相同哈希值的话就只存储一个键值对）。

- 总的来说，HashMap 的 hash 方法就是将 key 对象的 hashCode 值进行处理，得到最终的哈希值，并通过一定的算法映射到实际的存储位置上。这个过程决定了 HashMap 内部键值对的查找效率。

## HashMap的扩容

```java
// 该表在首次使用时初始化，并根据需要调整大小。分配时，长度始终是 2 的幂。 （在某些操作中容忍长度为零，以允许当前不需要的引导机制。）
transient Node<K, V>[] table;

// 阈值=（容量 * 负载因子)，超过这个大小就会resize扩容
int threshold;

// 哈希表的负载因子
final float loadFactor;

// HashMap中包含的键值对个数，实时装载因子=size/capacity
transient int size;

// 数组table默认长16
static final int DEFAULT_INITIAL_CAPACITY = 1 << 4; // aka 16

// 数组最大长
static final int MAXIMUM_CAPACITY = 1 << 30;

// 默认的负载因子
static final float DEFAULT_LOAD_FACTOR = 0.75f;

final Node<K, V>[] resize() {
    // 获取原来的数组
    Node<K, V>[] oldTab = table;
    // capacity为数组长度，也就是HashMap中桶的数量，默认值为16
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    int oldThr = threshold;
    int newCap, newThr = 0;
 
    if (oldCap > 0) {
        // 原数组不空时
        if (oldCap >= MAXIMUM_CAPACITY) {
            // 超过最大值就不再扩充
            threshold = Integer.MAX_VALUE;
            return oldTab;
        // 新容量扩为两倍，然后如果新容量小于最大值并且旧容量大于默认最小值，就把阈值也扩为两倍
        } else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                oldCap >= DEFAULT_INITIAL_CAPACITY)
            newThr = oldThr << 1; // double threshold
    } else if (oldThr > 0) // initial capacity was placed in threshold
        // 原数组空但阈值 oldThr 不为零，则说明是通过带参数构造方法创建的 HashMap，此时将阈值作为新数组长度 newCap。
        newCap = oldThr;
    else {               // zero initial threshold signifies using defaults
        // 如果原来的数组 table 和阈值 oldThr 都为零，则说明是通过无参数构造方法创建的 HashMap，此时将默认初始容量 `DEFAULT_INITIAL_CAPACITY（16）`和默认负载因子 `DEFAULT_LOAD_FACTOR（0.75）`计算出新数组长度 newCap 和新阈值 newThr。
        newCap = DEFAULT_INITIAL_CAPACITY;
        // 负载系数*容量
        newThr = (int) (DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
    }
    
    // 计算新的 resize 上限threshold
    if (newThr == 0) {
        float ft = (float) newCap * loadFactor;
        newThr = (newCap < MAXIMUM_CAPACITY && ft < (float) MAXIMUM_CAPACITY ?
                (int) ft : Integer.MAX_VALUE);
    }
    // 将新阈值赋值给成员变量 threshold
    threshold = newThr;
    
    @SuppressWarnings({"rawtypes", "unchecked"})
    // 创建新数组 newTab
    Node<K, V>[] newTab = (Node<K, V>[]) new Node[newCap];
    // 将新数组 newTab 赋值给成员变量 table
    table = newTab;
    if (oldTab != null) {
        // 旧数组 oldTab 不为空时，遍历旧数组的每个元素
        for (int j = 0; j < oldCap; ++j) {
            Node<K, V> e;
            // 如果该元素不为空
            if ((e = oldTab[j]) != null) {
                // 将旧数组中该位置的元素置为 null，以便垃圾回收
                oldTab[j] = null;
                if (e.next == null)
                    // 如果该元素没有冲突，直接将该元素放入新数组
                    newTab[e.hash & (newCap - 1)] = e;
                else if (e instanceof TreeNode)
                    // 如果该元素是树节点，将该树节点分裂成两个链表
                    ((TreeNode<K, V>) e).split(this, newTab, j, oldCap);
                else { // preserve order
                    // 如果该元素是链表
                    // 低位链表的头结点和尾结点
                    Node<K, V> loHead = null, loTail = null;
                    // 高位链表的头结点和尾结点
                    Node<K, V> hiHead = null, hiTail = null;
                    Node<K, V> next;
                    // 遍历该链表
                    do {
                        next = e.next;
                        // 如果该元素在低位链表中
                        if ((e.hash & oldCap) == 0) {
                            if (loTail == null)
                                // 如果低位链表还没有结点，将该元素作为低位链表的头结点
                                loHead = e;
                            else
                                // 如果低位链表已经有结点，将该元素加入低位链表的尾部
                                loTail.next = e;
                            // 更新低位链表的尾结点
                            loTail = e;
                        } else {
                            if (hiTail == null)
                                hiHead = e;
                            else
                                hiTail.next = e;
                            hiTail = e;
                        }
                    } while ((e = next) != null);
                    // 如果低位链表不为空
                    if (loTail != null) {
                        // 将低位链表的尾结点指向 null，以便垃圾回收
                        loTail.next = null;
                        // 将低位链表作为新数组对应位置的元素
                        newTab[j] = loHead;
                    }
                    if (hiTail != null) {
                        hiTail.next = null;
                        newTab[j + oldCap] = hiHead;
                    }
                }
            }
        }
    }
    // 返回新数组
    return newTab;
}
```

1. 获取原来的数组 table、数组长度 oldCap 和阈值 oldThr。
   1. 如果原来的数组 table 不为空，则根据扩容规则计算新数组长度 newCap 和新阈值 newThr，然后将原数组中的元素复制到新数组中。
   2. 如果原来的数组 table 为空但阈值 oldThr 不为零，则说明是通过带参数构造方法创建的 HashMap，此时将阈值作为新数组长度 newCap。
   3. 如果原来的数组 table 和阈值 oldThr 都为零，则说明是通过无参数构造方法创建的 HashMap，此时将默认初始容量 `DEFAULT_INITIAL_CAPACITY（16）`和默认负载因子 `DEFAULT_LOAD_FACTOR（0.75）`计算出新数组长度 newCap 和新阈值 newThr。
2. 计算新阈值 threshold，并将其赋值给成员变量 threshold。
3. 创建新数组 newTab，并将其赋值给成员变量 table。
4. 如果旧数组 oldTab 不为空，则遍历旧数组的每个元素，将其复制到新数组中。
5. 返回新数组 newTab。

- 数组扩容后的索引位置，要么就是原来的索引位置，要么就是“原索引+原来的容量”

## 负载因子

- 指哈希表中填充元素的个数与桶的数量的比值，当元素个数达到负载因子与桶的数量的乘积时，就需要进行扩容。这个值一般选择 0.75，是因为这个值可以在时间和空间成本之间做到一个折中，使得哈希表的性能达到较好的表现。

## 线程不安全

- 多线程下扩容会死循环（JDK7时使用头插法存放链表，多线程下扩容可能会出现环形链表）

- 多线程同时执行 put 操作时，如果计算出来的索引位置是相同的，那会造成前一个 key 被后一个 key 覆盖，从而导致元素的丢失。
- put 和 get 并发时会导致 get 到 null：线程 1 执行 put 时，因为元素个数超出阈值而导致出现扩容，线程 2 此时执行 get，就有可能出现这个问题

- HashMap 是线程不安全的主要是因为它在进行插入、删除和扩容等操作时可能会导致链表的结构发生变化，从而破坏了 HashMap 的不变性。为了解决这个问题，Java 提供了线程安全的 HashMap 实现类ConcurrentHashMap。ConcurrentHashMap 内部采用了分段锁（Segment），将整个 Map 拆分为多个小的 HashMap，每个小的 HashMap 都有自己的锁，不同的线程可以同时访问不同的小 Map，从而实现了线程安全。在进行插入、删除和扩容等操作时，只需要锁住当前小 Map，不会对整个 Map 进行锁定，提高了并发访问的效率。

## 总结

- HashMap 采用数组+链表/红黑树的存储结构，能够在 O(1)的时间复杂度内实现元素的添加、删除、查找等操作。
- HashMap 是线程不安全的，因此在多线程环境下需要使用ConcurrentHashMap来保证线程安全。
- HashMap 的扩容机制是通过扩大数组容量和重新计算 hash 值来实现的，扩容时需要重新计算所有元素的 hash 值，因此在元素较多时扩容会影响性能。
- 在 Java 8 中，HashMap 的实现引入了拉链法、树化等机制来优化大量元素存储的情况，进一步提升了性能。
- HashMap 中的 key 是唯一的，如果要存储重复的 key，则后面的值会覆盖前面的值。
- HashMap 的初始容量和加载因子都可以设置，初始容量表示数组的初始大小，加载因子表示数组的填充因子。一般情况下，初始容量为 16，加载因子为 0.75。
- HashMap 在遍历时是无序的，因此如果需要有序遍历，可以使用TreeMap。
