---
title: TreeMap
date: 2024-07-13 10:38:03 +0800
categories: [java, collections framework]
tags: [Java, Collections Framework, TreeMap]
description: 
---
- TreeMap 由红黑树实现，可以保持元素的自然顺序，或者实现了 Comparator 接口的自定义顺序
- 红黑树（英语：Red–black tree）是一种自平衡的二叉查找树（Binary Search Tree），结构复杂，但却有着良好的性能，完成查找、插入和删除的时间复杂度均为 log(n)。

## 自然顺序

- 默认情况下，TreeMap 是根据 key 的自然顺序排列的。

```java
// 红黑树中包含的元素数
private transient int size = 0;

// 比较器，为null时表示自然顺序
private final Comparator<? super K> comparator;

public V put(K key, V value) {
    // 将根节点赋值给变量t
    Entry<K, V> t = root;
    // 如果根节点为null，说明TreeMap为空
    if (t == null) {
        // 检查key的类型是否合法
        compare(key, key); // type (and possibly null) check
        // 创建一个新节点作为根节点
        root = new Entry<>(key, value, null);
        size = 1;
        modCount++;
        // 返回null，表示插入成功
        return null;
    }
    int cmp;
    Entry<K, V> parent;
    // split comparator and comparable paths
    // 获取比较器，根据使用的比较方法进行查找
    Comparator<? super K> cpr = comparator;
    if (cpr != null) {
        // 如果使用了Comparator
        do {
            // 将当前节点赋值给parent
            parent = t;
            // 使用Comparator比较key和t的键的大小
            cmp = cpr.compare(key, t.key);
            if (cmp < 0)
                // 在t的左子树中查找
                t = t.left;
            else if (cmp > 0)
                // 在t的右子树中查找
                t = t.right;
            else
                // 直接更新t的值，覆盖原来的值
                return t.setValue(value);
        } while (t != null);
    } else {
        // 如果没有使用Comparator
        if (key == null)
            throw new NullPointerException();
        @SuppressWarnings("unchecked")
        // 将key强制转换为Comparable类型
        Comparable<? super K> k = (Comparable<? super K>) key;
        do {
            parent = t;
            cmp = k.compareTo(t.key);
            if (cmp < 0)
                t = t.left;
            else if (cmp > 0)
                t = t.right;
            else
                return t.setValue(value);
        } while (t != null);
    }
    // 如果没有找到相同的键，需要创建一个新节点插入到TreeMap中
    Entry<K, V> e = new Entry<>(key, value, parent);
    if (cmp < 0)
        // 将e作为parent的左子节点
        parent.left = e;
    else
        // 将e作为parent的右子节点
        parent.right = e;
    // 插入节点后需要进行平衡操作
    fixAfterInsertion(e);
    size++;
    modCount++;
    return null;
}
```

- String类的compareTo()

```java
public int compareTo(String anotherString) {
    // 获取当前字符串和另一个字符串的长度
    int len1 = value.length;
    int len2 = anotherString.value.length;
    // 取两个字符串长度的较短者作为比较的上限
    int lim = Math.min(len1, len2);
    // 获取当前字符串和另一个字符串的字符数组
    char v1[] = value;
    char v2[] = anotherString.value;

    int k = 0;
    // 对两个字符串的每个字符进行比较
    while (k < lim) {
        char c1 = v1[k];
        char c2 = v2[k];
        // 如果两个字符不相等，返回它们的差值
        if (c1 != c2) {
            return c1 - c2;
        }
        k++;
    }
    // 如果两个字符串前面的字符都相等，返回它们长度的差值
    return len1 - len2;
}
```

## 自定义顺序

- TreeMap 提供了可以指定排序规则的构造方法

```java
public TreeMap(Comparator<? super K> comparator) {
    this.comparator = comparator;
}
```

- `Comparator.reverseOrder()` 返回的是 Collections.ReverseComparator 对象，就是用来反转顺序的

```java
TreeMap<Integer, String> map = new TreeMap<>(Comparator.reverseOrder());
```

```java
private static class ReverseComparator
    implements Comparator<Comparable<Object>>, Serializable {
    private static final long serialVersionUID = 7207038068494060240L;
    
    // 单例模式，用于表示逆序比较器
    static final ReverseComparator REVERSE_ORDER
        = new ReverseComparator();
	// 实现比较方法，对两个实现了Comparable接口的对象进行逆序比较
    public int compare(Comparable<Object> c1, Comparable<Object> c2) {
        // 调用c2的compareTo()方法，以c1为参数，实现逆序比较
        return c2.compareTo(c1);
    }

    // 反序列化时，返回Collections.reverseOrder()，保证单例模式
    private Object readResolve() { return Collections.reverseOrder(); }

    // 返回正序比较器
    @Override
    public Comparator<Comparable<Object>> reversed() {
        return Comparator.naturalOrder();
    }
}
```

## 排序的用处

```java
// 获取最后一个key
Integer highestKey = map.lastKey();
// 获取第一个key
Integer lowestKey = map.firstKey();

// 获取key之前的keySet
Set<Integer> keysLessThan3 = map.headMap(3).keySet();
// 获取key之后的keySet
Set<Integer> keysGreaterThanEqTo3 = map.tailMap(3).keySet();

Map<Integer, String> headMap = map.headMap(3);
Map<Integer, String> tailMap = map.tailMap(4);
// 获取key在大于等于2，且小于4的键值对
Map<Integer, String> subMap = map.subMap(2, 4);
```

## Map的选择

| 特性     | TreeMap        | HashMap        | LinkedHashMap    |
| -------- | -------------- | -------------- | ---------------- |
| 排序     | 支持           | 不支持         | 不支持           |
| 插入顺序 | 不保证         | 不保证         | 保证             |
| 查找效率 | O(log n)       | O(1)           | O(1)             |
| 空间占用 | 通常较大       | 通常较小       | 通常较大         |
| 适用场景 | 需要排序的场景 | 无需排序的场景 | 需要保持插入顺序 |
