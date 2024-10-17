---
title: 原子操作类Atomic
date: 2024-07-26 09:46:45 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, Atomic, JUC]
description: 
---
## 原子操作的基本数据类型

------

基本类型的原子操作主要有这些：

1. AtomicBoolean：以原子更新的方式更新 boolean；
2. AtomicInteger：以原子更新的方式更新 Integer;
3. AtomicLong：以原子更新的方式更新 Long；

这几个类的用法基本一致，这里以 AtomicInteger 为例。

1. `addAndGet(int delta)` ：增加给定的 delta，并获取新值。
2. `incrementAndGet()`：增加 1，并获取新值。
3. `getAndSet(int newValue)`：获取当前值，并将新值设置为 newValue。
4. `getAndIncrement()`：获取当前值，并增加 1。

AtomicInteger 的 getAndIncrement 方法：

```java
public final int getAndIncrement() {
    // 使用Unsafe类中的getAndAddInt方法原子地增加AtomicInteger的当前值
    // 第一个参数this是AtomicInteger的当前实例
    // 第二个参数valueOffset是一个偏移量，它指示在AtomicInteger对象中的哪个位置可以找到实际的int值
    // 第三个参数1表示要加到当前值上的值（即增加的值）
    // 此方法返回的是增加前的原始值
    return unsafe.getAndAddInt(this, valueOffset, 1);
}
```

Unsafe 类是 Java 中的一个特殊类，用于执行低级、不安全的操作。getAndIncrement 方法就是利用了 Unsafe 类提供的 CAS（Compare-And-Swap）操作来实现原子的 increment 操作。CAS 是一种常用的无锁技术，允许在多线程环境中原子地更新值。

示例：

```java
public class Main {
    private static final AtomicInteger atomicInteger = new AtomicInteger(1);

    public static void main(String[] args) {
        System.out.println(atomicInteger.getAndIncrement());
        System.out.println(atomicInteger.get());
    }
}
```

AtomicBoolean 类的 compareAndSet 方法：

```java
public final boolean compareAndSet(boolean expect, boolean update) {
    // 将expect布尔值转化为整数，true为1，false为0
    int e = expect ? 1 : 0;
    
    // 将update布尔值转化为整数，true为1，false为0
    int u = update ? 1 : 0;
    
    // 使用Unsafe类中的compareAndSwapInt方法尝试原子地更新AtomicBoolean的当前值
    // 第一个参数this是AtomicBoolean的当前实例
    // 第二个参数valueOffset是一个偏移量，它指示在AtomicBoolean对象中的哪个位置可以找到实际的int值
    // 第三个参数e是我们期望的当前值（转换为整数后的值）
    // 第四个参数u是我们想要更新的值（转换为整数后的值）
    // 如果当前值与期望值e相等，它会被原子地设置为u，并返回true；否则返回false。
    return unsafe.compareAndSwapInt(this, valueOffset, e, u);
}
```

## 原子操作的数组类型

------

如果需要原子更新数组里的某个元素，atomic 也提供了相应的类：

1. AtomicIntegerArray：这个类提供了一些原子更新 int 整数数组的方法。
2. AtomicLongArray：这个类提供了一些原子更新 long 型证书数组的方法。
3. AtomicReferenceArray：这个类提供了一些原子更新引用类型数组的方法。

这几个类的用法一致，就以 AtomicIntegerArray 来总结下常用的方法：

1. `addAndGet(int i, int delta)`：以原子更新的方式将数组中索引为 i 的元素与输入值相加；
2. `getAndIncrement(int i)`：以原子更新的方式将数组中索引为 i 的元素自增加 1；
3. `compareAndSet(int i, int expect, int update)`：将数组中索引为 i 的位置的元素进行更新

示例：

```java
public class Main {
    private static final int[] value = new int[]{1, 2, 3};
    private static final AtomicIntegerArray integerArray = new AtomicIntegerArray(value);

    public static void main(String[] args) {
        // 对数组中索引为1的位置的元素加5
        int result = integerArray.getAndAdd(1, 5);
        System.out.println(integerArray.get(1));
        System.out.println(result);
    }
}
```

## 原子操作的引用类型

------

如果需要原子更新引用类型的话，atomic 也提供了相关的类：

1. AtomicReference：原子更新引用类型；
2. AtomicReferenceFieldUpdater：原子更新引用类型里的字段；
3. AtomicMarkableReference：原子更新带有标记位的引用类型；

示例：

```java
public class Main {
    private static final AtomicReference<User> reference = new AtomicReference<>();

    public static void main(String[] args) {
        User user1 = new User("a", 1);
        reference.set(user1);
        User user2 = new User("b", 2);
        User user = reference.getAndSet(user2);
        System.out.println(user);
        System.out.println(reference.get());
    }

    static class User {
        private final String userName;
        private final int age;

        public User(String userName, int age) {
            this.userName = userName;
            this.age = age;
        }

        @Override
        public String toString() {
            return "User{" +
                    "userName='" + userName + '\'' +
                    ", age=" + age +
                    '}';
        }
    }
}
```

## 原子更新字段类型

------

如果需要更新对象的某个字段，atomic 同样也提供了相应的原子操作类：

1. AtomicIntegeFieldUpdater：原子更新整型字段类；
2. AtomicLongFieldUpdater：原子更新长整型字段类；
3. AtomicStampedReference：原子更新引用类型，这种更新方式会带有版本号，是为了解决 CAS 的 ABA 问题

使用原子更新字段需要两步：

1. 通过静态方法`newUpdater`创建一个更新器，并且设置想要更新的类和字段；
2. 字段必须使用`public volatile`进行修饰；

示例：

```java
public class Main {
    private static final AtomicIntegerFieldUpdater<User> updater = AtomicIntegerFieldUpdater.newUpdater(User.class, "age");

    public static void main(String[] args) {
        User user = new User("a", 1);
        int oldValue = updater.getAndAdd(user, 5);
        System.out.println(oldValue);
        System.out.println(updater.get(user));
    }

    static class User {
        private final String userName;
        public volatile int age;

        public User(String userName, int age) {
            this.userName = userName;
            this.age = age;
        }

        @Override
        public String toString() {
            return "User{" +
                    "userName='" + userName + '\'' +
                    ", age=" + age +
                    '}';
        }
    }
}
```
