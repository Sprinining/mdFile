---
title: Iterator和Iterable
date: 2024-07-13 02:10:39 +0800
categories: [java, collections framework]
tags: [Java, Collections Framework, Iterator, Iterable]
description: 
---
## Java遍历List有三种方式

```java
public static void main(String[] args) {
    List<String> list = new ArrayList<>();

    // for循环
    for (int i = 0; i < list.size(); i++) {
        System.out.println(list.get(i) + ", ");
    }

    // for-each，实际也是Iterator
    for (String s : list) {
        System.out.println(s + ", ");
    }

    // 迭代器
    Iterator<String> it = list.iterator();
    while (it.hasNext()) {
        System.out.println(it.next() + ", ");
    }
}
```

## Iterator源码

```java
public interface Iterator<E> {
    // 判断集合中是否存在下一个对象
    boolean hasNext();
    
    // 返回集合中的下一个对象，并将访问指针移动一位
    E next();
    
    // 删除集合中调用next()方法返回的对象
    default void remove() {
        throw new UnsupportedOperationException("remove");
    }
    
    default void forEach(Consumer<? super T> action) {
    	Objects.requireNonNull(action);
    	for (T t : this) {
        	action.accept(t);
    	}
	}
}

```

- 它对 Iterable 的每个元素执行给定操作，具体指定的操作需要自己写Consumer接口通过accept方法回调出来。

```java
List<Integer> list = new ArrayList<>(Arrays.asList(1, 2, 3));
list.forEach(new Consumer<Integer>() {
    @Override
    public void accept(Integer integer) {
        System.out.println(integer);
    }
});

```

- List 的关系图谱中并没有直接使用 Iterator，而是使用 Iterable 做了过渡

```java
public interface Iterable<T> {

    Iterator<T> iterator();

    default void forEach(Consumer<? super T> action) {
        Objects.requireNonNull(action);
        for (T t : this) {
            action.accept(t);
        }
    }

    default Spliterator<T> spliterator() {
        return Spliterators.spliteratorUnknownSize(iterator(), 0);
    }
}
```

## ArrayList重写了Iterable的iterator方法

```java
public Iterator<E> iterator() {
    return new Itr();
}
```

```java
private class Itr implements Iterator<E> {
    // 下个元素的索引
    int cursor;       // index of next element to return
    // 上个元素的索引
    int lastRet = -1; // index of last element returned; -1 if no such
    // 预期的结构性修改次数
    int expectedModCount = modCount;

    Itr() {}

    // 判断是否还有下个元素
    public boolean hasNext() {
        return cursor != size;
    }

    @SuppressWarnings("unchecked")
    // 获取下个元素
    public E next() {
        checkForComodification();
        // 记录当前迭代器的位置
        int i = cursor;
        if (i >= size)
            throw new NoSuchElementException();
        // 获取 ArrayList 对象的内部数组
        Object[] elementData = ArrayList.this.elementData;
        if (i >= elementData.length)
            throw new ConcurrentModificationException();
        // 将游标位置加 1，为下一次迭代做准备
        cursor = i + 1;
        // 记录上一个元素的索引
        return (E) elementData[lastRet = i];
    }

    // 删除最后一个返回的元素，迭代器只能删除最后一次调用 next 方法返回的元素
    public void remove() {
        // 如果上一次调用 next 方法之前没有调用 remove 方法，则抛出 IllegalStateException 异常
        if (lastRet < 0)
            throw new IllegalStateException();
        // 检查在最后一次调用 next 方法之后是否进行了结构性修改
        checkForComodification();

        try {
            // 调用 ArrayList 对象的 remove(int index) 方法删除上一个元素
            ArrayList.this.remove(lastRet);
            // 将游标位置设置为上一个元素的位置
            cursor = lastRet;
            // 将上一个元素的索引设置为 -1，表示没有上一个元素
            lastRet = -1;
            // 更新预期的结构性修改次数
            expectedModCount = modCount;
        } catch (IndexOutOfBoundsException ex) {
            throw new ConcurrentModificationException();
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    public void forEachRemaining(Consumer<? super E> consumer) {
        Objects.requireNonNull(consumer);
        final int size = ArrayList.this.size;
        int i = cursor;
        if (i >= size) {
            return;
        }
        final Object[] elementData = ArrayList.this.elementData;
        if (i >= elementData.length) {
            throw new ConcurrentModificationException();
        }
        while (i != size && modCount == expectedModCount) {
            consumer.accept((E) elementData[i++]);
        }
        // update once at end of iteration to reduce heap write traffic
        cursor = i;
        lastRet = i - 1;
        checkForComodification();
    }

    final void checkForComodification() {
        if (modCount != expectedModCount)
            throw new ConcurrentModificationException();
    }
}
```

- Map 就没办法直接使用 for-each，因为 Map 没有实现 Iterable 接口，只有通过 `map.entrySet()`、`map.keySet()`、`map.values()` 这种返回一个 Collection 的方式才能 使用 for-each。

## LinkedList的父类 AbstractSequentialList重写 Iterable 接口的 iterator 方法

- LinkedList 并没有直接重写 Iterable 接口的 iterator 方法，而是由它的父类 AbstractSequentialList 来完成

```java
public Iterator<E> iterator() {
    return listIterator();
}
```

- LinkedList重写了listIterator方法

```java
public ListIterator<E> listIterator(int index) {
    checkPositionIndex(index);
    return new ListItr(index);
}
```

```java
// 在遍历List 时可以从任意下标开始遍历，而且支持双向遍历。
// Iterator 不仅支持 List，还支持 Set，但 ListIterator 就只支持 List
public interface ListIterator<E> extends Iterator<E> {

    boolean hasNext();

    E next();

    boolean hasPrevious();

    E previous();

    int nextIndex();

    int previousIndex();

    void remove();

    void set(E e);

    void add(E e);
}
```

- LinkedList的逆序遍历

```java
private class DescendingIterator implements Iterator<E> {
    // 使用 ListItr 对象进行逆向遍历。
    private final ListItr itr = new ListItr(size());

    // 判断是否还有下一个元素。
    public boolean hasNext() {
        return itr.hasPrevious();
    }

    // 获取下一个元素。
    public E next() {
        return itr.previous();
    }

    // 删除最后一个返回的元素。
    public void remove() {
        itr.remove();
    }
}
```

