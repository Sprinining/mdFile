---
title: for-each循环陷阱
date: 2024-07-13 02:47:46 +0800
categories: [java, collections framework]
tags: [Java, Collections Framework, for-each]
description: 
---
## for-each删除元素报错

```java
public static void main(String[] args) {
    List<String> list = new ArrayList<>();
    list.add("haha");
    list.add("xixi");
    list.add("hehe");

    for (String s : list) {
        if ("haha".equals(s))
            list.remove(s);
    }

    System.out.println(list);
}
```

```java
Exception in thread "main" java.util.ConcurrentModificationException
	at java.util.ArrayList$Itr.checkForComodification(ArrayList.java:911)
	at java.util.ArrayList$Itr.next(ArrayList.java:861)
	at test.foreachTest.Test.main(Test.java:13)
```

- remove 的时候触发执行了 `checkForComodification` 方法，该方法对 modCount 和 expectedModCount 进行了比较，发现两者不等，就抛出了 `ConcurrentModificationException` 异常。

- ArrayList重写了Iterable的iterator方法

```java
public Iterator<E> iterator() {
    return new Itr();
}
```

```java
// 计数器，用于记录 ArrayList 对象被修改的次数。ArrayList 的修改操作包括添加、删除、设置元素值等。每次对 ArrayList 进行修改操作时，modCount 的值会自增 1。
protected transient int modCount = 0;

private class Itr implements Iterator<E> {
    int cursor; 
    int lastRet = -1;
    // new Itr() 的时候 expectedModCount 被赋值为 modCount
    int expectedModCount = modCount;

    Itr() {}

    // 判断是否还有下个元素
    public boolean hasNext() {
        return cursor != size;
    }

    @SuppressWarnings("unchecked")
    // 获取下个元素
    public E next() {
        // 检查 ArrayList 是否被修改过
        checkForComodification();
        int i = cursor;
        if (i >= size)
            throw new NoSuchElementException();
        Object[] elementData = ArrayList.this.elementData;
        if (i >= elementData.length)
            throw new ConcurrentModificationException();
        cursor = i + 1;
        return (E) elementData[lastRet = i];
    }

    ...

    final void checkForComodification() {
        if (modCount != expectedModCount)
            throw new ConcurrentModificationException();
    }
}
```

- fail-fast 是一种通用的系统设计思想，一旦检测到可能会发生错误，就立马抛出异常，程序将不再往下执行。
- 在迭代 ArrayList 时，如果迭代过程中发现 modCount 的值与迭代器的 expectedModCount 不一致，则说明 ArrayList 已被修改过，此时会抛出 ConcurrentModificationException 异常。这种机制可以保证迭代器在遍历 ArrayList 时，不会遗漏或重复元素，同时也可以在多线程环境下检测到并发修改问题。

## 执行逻辑

- list执行3次add，每次add都会调用 ensureCapacityInternal 方法，ensureCapacityInternal 方法调用 ensureExplicitCapacity 方法，ensureExplicitCapacity 方法中会执行 `modCount++`。三次add后modCount为3
- 第一次遍历时，执行remove，remove 方法调用 fastRemove 方法，fastRemove 方法中会执行 `modCount++`，modCound变成4

- 第二次遍历时，会执行 Itr 的 next 方法，next 方法就会调用 `checkForComodification` 方法。此时 expectedModCount 为 3，modCount 为 4，抛出 ConcurrentModificationException 异常。

## 正确删除元素

### remove后break

```java
// 没法删除多个重复元素
for (String s : list) {
    if ("haha".equals(s)) {
        list.remove(s);
        break;
    }
}
```

### for循环

```java
for (int i = 0; i < list.size(); i++) {
    String s = list.get(i);
    if ("haha".equals(s)) {
        // 删除后，size减一，list中后一个元素会移到被删除的下标i处
        // 但下次循环不会再遍历下标i处的元素了
        list.remove(s);
    }
}
```

### Iterator自带的remove()

```java
Iterator<String> itr = list.iterator();
while (itr.hasNext()) {
    String s = itr.next();
    if ("haha".equals(s))
        itr.remove();
}
```

- ArrayList中的内部类Itr

```java
private class Itr implements Iterator<E> {
    int cursor;       // index of next element to return
    int lastRet = -1; // index of last element returned; -1 if no such
    int expectedModCount = modCount;
    
    ...
	public E next() {
        ...
        // 记录这次调用next返回的元素
        return (E) elementData[lastRet = i];
    }
    
    public void remove() {
        // 如果没有上一个返回元素的索引，则抛出异常
        if (lastRet < 0)
            throw new IllegalStateException();
        // 检查 ArrayList 是否被修改过
        checkForComodification();

        try {
            // 删除上一个返回元素，也就是上次调用next返回的元素
            ArrayList.this.remove(lastRet);
            // 更新下一个元素的索引
            cursor = lastRet;
            // 清空上一个返回元素的索引
            lastRet = -1;
            // 更新 ArrayList 的修改次数，保证了 expectedModCount 与 modCount 的同步
            expectedModCount = modCount;
        } catch (IndexOutOfBoundsException ex) {
            throw new ConcurrentModificationException();
        }
    }

    ...
}
```

### 流

- 采用 Stream 流的filter() 方法来过滤集合中的元素，然后再通过 collect() 方法将过滤后的元素收集到一个新的集合中。

```java
List<String> list = new ArrayList<>(Arrays.asList("haha", "xixi", "hehe"));
list = list.stream().filter(s -> !s.equals("haha")).collect(Collectors.toList());
```

## 总结

- 之所以==不能在foreach里执行删除操作==，是因为foreach 循环是基于迭代器实现的，而迭代器在遍历集合时会维护一个 expectedModCount 属性来记录集合被修改的次数。如果在 foreach 循环中执行删除操作会导致 expectedModCount 属性值与实际的 modCount 属性值不一致，从而导致迭代器的 hasNext() 和 next() 方法抛出 ConcurrentModificationException 异常。
- 为了避免这种情况，应该使用迭代器的 remove() 方法来删除元素，该方法会在删除元素后更新迭代器状态，确保循环的正确性。如果需要在循环中删除元素，应该使用迭代器的 remove() 方法，而不是集合自身的 remove() 方法。
