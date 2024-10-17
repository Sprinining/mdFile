---
title: Unsafe
date: 2024-07-27 02:16:07 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, Unsafe]
description: 
---
## Unsafe 基础

------

Unsafe 是 Java 中一个非常特殊的类，它为 Java 提供了一种底层、"不安全"的机制来直接访问和操作内存、线程和对象。正如其名字所暗示的，Unsafe 提供了许多不安全的操作，因此它的使用应该非常小心，并限于那些确实需要使用这些底层操作的场景。

Unsafe 在 static 静态代码块中，以单例的方式初始化了一个 Unsafe 对象：

```java
public final class Unsafe {
     private static final Unsafe theUnsafe;
     ...
     private Unsafe() {
     }
     ...
     static {
         theUnsafe = new Unsafe();
     }   
 }
```

Unsafe 类提供了一个静态方法`getUnsafe`，看上去貌似可以用它来获取 Unsafe 实例：

```java
@CallerSensitive
public static Unsafe getUnsafe() {
    Class var0 = Reflection.getCallerClass();
    if (!VM.isSystemDomainLoader(var0.getClassLoader())) {
        throw new SecurityException("Unsafe");
    } else {
        return theUnsafe;
    }
}
```

直接调用这个静态方法，会抛出 `SecurityException `异常：

```java
Exception in thread "main" java.lang.SecurityException: Unsafe
	at sun.misc.Unsafe.getUnsafe(Unsafe.java:90)
	at org.example.Main.main(Main.java:7)
```

这是因为在`getUnsafe`方法中，会对调用者的`classLoader`进行检查，判断当前类是否由`Bootstrap classLoader`加载，如果不是的话就会抛出一个`SecurityException`异常。只有启动类加载器加载的类才能够调用 Unsafe 类中的方法，这是为了防止这些方法在不可信的代码中被调用。

Unsafe 类实现的功能可以被分为 8 类：内存操作、内存屏障、对象操作、数组操作、CAS 操作、线程调度、Class 操作、系统信息。

### 创建实例

```java
public class Main {
    public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
        User user = new User(2);
        fieldTest(getUnsafe(), user);
    }

    // 利用反射获得 Unsafe 类中已经实例化完成的单例对象
    public static Unsafe getUnsafe() throws IllegalAccessException, NoSuchFieldException {
        // Field unsafeField = Unsafe.class.getDeclaredFields()[0]; //也可以这样，作用相同
        Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
        unsafeField.setAccessible(true);
        return (Unsafe) unsafeField.get(null);
    }

    public static void fieldTest(Unsafe unsafe, User user) throws NoSuchFieldException {
        // 获取到了对象中字段的偏移地址，这个偏移地址不是内存中的绝对地址而是一个相对地址
        long fieldOffset = unsafe.objectFieldOffset(User.class.getDeclaredField("age"));
        System.out.println("offset:" + fieldOffset);
        // 通过这个偏移地址对int类型字段的属性值进行读写操作
        unsafe.putInt(user, fieldOffset, 20);
        System.out.println("age:" + unsafe.getInt(user, fieldOffset));
        System.out.println("age:" + user.getAge());
    }

    static class User {
        private int age;

        public User() {
        }

        public User(int age) {
            this.age = age;
        }

        public int getAge() {
            return age;
        }

        public void setAge(int age) {
            this.age = age;
        }

    }
}
```

上面的例子中调用了 Unsafe 类的`putInt`和`getInt`方法，看一下源码中的方法：

```java
// 从对象的指定偏移地址处读取一个 int
public native int getInt(Object o, long offset);
// 从对象的指定偏移地址处写入一个 int，即使类中的这个属性是 private 类型的，也可以对它进行读写
public native void putInt(Object o, long offset, int x);
```

Unsafe 类中的很多基础方法都属于`native`方法，原因如下：

- 需要用到 Java 中不具备的依赖于操作系统的特性，Java 在实现跨平台的同时要实现对底层的控制，需要借助其他语言发挥作用
- 对于其他语言已经完成的一些现成功能，可以使用 Java 直接调用
- 程序对时间敏感或对性能要求非常高时，有必要使用更加底层的语言，例如 C/C++甚至是汇编

`juc`包的很多并发工具类在实现并发机制时，都调用了`native`方法，通过 native 方法可以打破 Java 运行时的界限，能够接触到操作系统底层的某些功能。对于同一个`native`方法，不同的操作系统可能会通过不同的方式来实现，但是对于使用者来说是透明的，最终都会得到相同的结果。

## Unsafe 应用

------

### 内存操作

Unsafe 中，提供的下列接口都可以直接进行内存操作：

```java
// 分配新的本地空间
public native long allocateMemory(long bytes);
// 重新调整内存空间的大小
public native long reallocateMemory(long address, long bytes);
// 将内存设置为指定值
public native void setMemory(Object o, long offset, long bytes, byte value);
// 内存拷贝
public native void copyMemory(Object srcBase, long srcOffset,Object destBase, long destOffset,long bytes);
// 清除内存
public native void freeMemory(long address);
```

```java
public class Main {

    public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
        Unsafe unsafe = getUnsafe();
        // 字节长度
        int size = 4;
        // 申请 4 字节长度的内存空间
        long address1 = unsafe.allocateMemory(size);
        // 重新分配为 8 个字节长度
        long address2 = unsafe.reallocateMemory(address1, size * 2);
        System.out.println("address1: " + address1);
        System.out.println("address2: " + address2);
        try {
            // 向每个字节写入内容为byte类型的 1
            unsafe.setMemory(null, address1, size, (byte) 1);
            for (int i = 0; i < 2; i++) {
                // 每次拷贝四个字节
                unsafe.copyMemory(null, address1, null, address2 + size * i, 4);
            }
            // 00000001000000010000000100000001B = 16843009
            System.out.println(unsafe.getInt(address1));
            // 0000000100000001000000010000000100000001000000010000000100000001B = 72340172838076673
            System.out.println(unsafe.getLong(address2));
        } finally {
            // 通过这种方式分配的内存属于堆外内存，是无法进行垃圾回收的
            // 需要手动调用freeMemory方法进行释放，否则会产生内存泄漏
            unsafe.freeMemory(address1);
            unsafe.freeMemory(address2);
        }
    }

    public static Unsafe getUnsafe() throws IllegalAccessException, NoSuchFieldException {
        // Field unsafeField = Unsafe.class.getDeclaredFields()[0]; //也可以这样，作用相同
        Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
        unsafeField.setAccessible(true);
        return (Unsafe) unsafeField.get(null);
    }
}
```

### 内存屏障

指令重排序可能会带来一个不好的结果，导致 CPU 的高速缓存和内存中数据的不一致，而内存屏障（`Memory Barrier`）就是通过组织屏障两边的指令重排序从而避免编译器和硬件的不正确优化情况。

在硬件层面上，内存屏障是 CPU 为了防止代码进行重排序而提供的指令，不同的硬件平台上实现内存屏障的方法可能并不相同。

在 Java8 中，引入了 3 个内存屏障的方法，它屏蔽了操作系统底层的差异，允许在代码中定义、并统一由 jvm 来生成内存屏障指令，来实现内存屏障的功能。Unsafe 中提供了下面三个内存屏障相关方法：

```java
// 禁止读操作重排序
public native void loadFence();
// 禁止写操作重排序
public native void storeFence();
// 禁止读、写操作重排序
public native void fullFence();
```

内存屏障可以看做对内存随机访问操作中的一个同步点，使得此点之前的所有读写操作都执行后才可以开始执行此点之后的操作。

以`loadFence`方法为例，它会禁止读操作重排序，保证在这个屏障之前的所有读操作都已经完成，并且将缓存数据设为无效，重新从主存中进行加载。

基于读内存屏障，我们也能实现相同的功能。下面定义一个线程方法，在线程中去修改`flag`标志位，注意这里的`flag`是没有被`volatile`修饰的：

```java
public class Main {
    public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
        Unsafe unsafe = getUnsafe();
        ChangeThread changeThread = new ChangeThread();
        new Thread(changeThread).start();
        while (true) {
            boolean flag = changeThread.flag;
            // 加入读内存屏障，使主线程中的缓存数据设为无效，必须重新从主存中进行加载。
            // 如果没有内存屏障，主线程中的flag一直都是旧值false，无法结束循环
            unsafe.loadFence();
            if (flag) {
                System.out.println("detected flag changed");
                break;
            }
        }
        System.out.println("main thread end");
    }

    static class ChangeThread implements Runnable {
        // 加上 volatile 后，注释掉 loadFence，主线程循环一样能退出
        boolean flag = false;

        @Override
        public void run() {
            try {
                TimeUnit.SECONDS.sleep(2);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println("before subThread change flag");
            flag = true;
            System.out.println("after subThread change flag");
        }
    }

    public static Unsafe getUnsafe() throws IllegalAccessException, NoSuchFieldException {
        // Field unsafeField = Unsafe.class.getDeclaredFields()[0]; //也可以这样，作用相同
        Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
        unsafeField.setAccessible(true);
        return (Unsafe) unsafeField.get(null);
    }
}
```

==运行中的线程不是直接读取主内存中变量的==，只能操作自己工作内存中的变量，然后同步到主内存中，并且线程的工作内存是不能共享的。子线程借助于主内存，将修改后的结果同步给了主线程，进而修改主线程中的工作空间，跳出循环。

### 对象操作

1.除了前面的`putInt`、`getInt`方法外，Unsafe 提供了 8 种基础数据类型以及`Object`的`put`和`get`方法，并且所有的`put`方法都可以越过访问权限，直接修改内存中的数据。

阅读 openJDK 源码中的注释可以发现，基础数据类型和`Object`的读写稍有不同，基础数据类型是直接操作的属性值（`value`），而`Object`的操作则是基于引用值（`reference value`）。下面是`Object`的读写方法：

```java
// 在对象的指定偏移地址获取一个对象引用
public native Object getObject(Object o, long offset);
// 在对象指定偏移地址写入一个对象引用
public native void putObject(Object o, long offset, Object x);
```

除了对象属性的普通读写外，Unsafe 还提供了 `volatile 读写`和`有序写入`方法。`volatile`读写方法的覆盖范围与普通读写相同，包含了全部基础数据类型和`Object`类型，以`int`类型为例：

```java
// 在对象的指定偏移地址处读取一个int值，支持volatile load语义
public native int getIntVolatile(Object o, long offset);
// 在对象指定偏移地址处写入一个int，支持volatile store语义
public native void putIntVolatile(Object o, long offset, int x);
```

相对于普通读写来说，`volatile`读写具有更高的成本，因为它需要保证可见性和有序性。在执行`get`操作时，会==强制从主存中获取属性值==，在使用`put`方法设置属性值时，会==强制将值更新到主存中==，从而保证这些变更对其他线程是可见的。

有序写入的方法有以下三个：

```java
public native void putOrderedObject(Object o, long offset, Object x);
public native void putOrderedInt(Object o, long offset, int x);
public native void putOrderedLong(Object o, long offset, long x);
```

有序写入的成本相对`volatile`较低，因为它只保证写入时的有序性，而不保证可见性，也就是一个线程写入的值不能保证其他线程立即可见。

为了解决这里的差异性，需要对内存屏障的知识点再进一步进行补充，首先需要了解两个指令的概念：

- `Load`：将主内存中的数据拷贝到处理器的缓存中
- `Store`：将处理器缓存的数据刷新到主内存中

顺序写入与`volatile`写入的差别在于，在顺序写时加入的内存屏障类型为`StoreStore`类型，而在`volatile`写入时加入的内存屏障是`StoreLoad`类型。

```java
// putOrderedXXX：Store1 -> StoreStore -> Store2
// putXXVolatile：Store1 -> StoreLoad -> Store2
```

在有序写入方法中，使用的是`StoreStore`屏障，该屏障确保`Store1`立刻刷新数据到内存，这一操作先于`Store2`以及后续的存储指令操作。

而在`volatile`写入中，使用的是`StoreLoad`屏障，该屏障确保`Store1`立刻刷新数据到内存，这一操作先于`Load2`及后续的装载指令，并且，`StoreLoad`屏障会使该屏障之前的所有内存访问指令，包括存储指令和访问指令全部完成之后，才执行该屏障之后的内存访问指令。

在上面的三类写入方法中，在写入效率方面，按照`put`、`putOrder`、`putVolatile`的顺序效率逐渐降低。

2.使用 Unsafe 的`allocateInstance`方法，允许我们使用非常规的方式进行对象的实例化，首先定义一个实体类，并且在构造方法中对其成员变量进行赋值操作：

```java
public class Main {
    public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException, InstantiationException {
        A a1 = new A();
        // 1
        System.out.println(a1.getB());

        A a2 = A.class.newInstance();
        // 1
        System.out.println(a2.getB());

        A a3 = (A) getUnsafe().allocateInstance(A.class);
        // 0
        // 通过allocateInstance方法创建对象过程中，不会调用类的构造方法
        System.out.println(a3.getB());
    }

    static class A {
        private int b;

        // 如果将 A 类的构造方法改为private类型，将无法通过构造方法和反射创建对象，但allocateInstance方法仍然有效。
        public A() {
            this.b = 1;
        }

        public int getB() {
            return b;
        }
    }

    public static Unsafe getUnsafe() throws IllegalAccessException, NoSuchFieldException {
        // Field unsafeField = Unsafe.class.getDeclaredFields()[0]; //也可以这样，作用相同
        Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
        unsafeField.setAccessible(true);
        return (Unsafe) unsafeField.get(null);
    }
}
```

使用这种方式创建对象时，只用到了`Class`对象，所以说如果想要跳过对象的初始化阶段或者跳过构造器的安全检查，就可以使用这种方法。

### 数组操作

在 Unsafe 中，可以使用`arrayBaseOffset`方法获取数组中第一个元素的偏移地址，使用`arrayIndexScale`方法可以获取数组中元素间的偏移地址增量。

```java
public class Main {
    public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
        Unsafe unsafe = getUnsafe();

        String[] array = new String[]{"str1str1str", "str2", "str3"};
        // 获取数组中第一个元素的偏移地址
        int baseOffset = unsafe.arrayBaseOffset(String[].class);
        System.out.println("第一个元素的偏移地址 baseOffset = " + baseOffset);
        int scale = unsafe.arrayIndexScale(String[].class);
        // 获取数组中元素间的偏移地址增量
        System.out.println("偏移地址增量 scale = " + scale);

        for (int i = 0; i < array.length; i++) {
            int offset = baseOffset + scale * i;
            System.out.println(offset + " : " + unsafe.getObject(array, offset));
        }
    }

    public static Unsafe getUnsafe() throws IllegalAccessException, NoSuchFieldException {
        // Field unsafeField = Unsafe.class.getDeclaredFields()[0]; //也可以这样，作用相同
        Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
        unsafeField.setAccessible(true);
        return (Unsafe) unsafeField.get(null);
    }
}
```

### CAS 操作

在 Unsafe 类中，提供了`compareAndSwapObject`、`compareAndSwapInt`、`compareAndSwapLong`方法来实现的对`Object`、`int`、`long`类型的 CAS 操作。

```java
public final native boolean compareAndSwapInt(Object o, long offset,int expected,int x);
```

参数中`o`为需要更新的对象，`offset`是对象`o`中整形字段的偏移量，如果这个字段的值与`expected`相同，则将字段的值设为`x`这个新值，并且此更新是不可被中断的，也就是一个原子操作。

```java
public class Main {
    private volatile int a;

    public static void main(String[] args) {
        Main obj = new Main();

        new Thread(() -> {
            for (int i = 1; i < 5; i++) {
                obj.increment(i);
                System.out.print(obj.a + " ");
            }
        }).start();
        new Thread(() -> {
            for (int i = 5; i < 10; i++) {
                obj.increment(i);
                System.out.print(obj.a + " ");
            }
        }).start();
        // 依次输出 1 2 3 4 5 6 7 8 9
    }

    private void increment(int x) {
        Unsafe unsafe = null;
        try {
            unsafe = getUnsafe();
        } catch (IllegalAccessException | NoSuchFieldException e) {
            throw new RuntimeException(e);
        }
        // 在调用compareAndSwapInt方法后，会直接返回true或false的修改结果，因此需要我们在代码中手动添加自旋的逻辑。
        // 在AtomicInteger类的设计中，也是采用了将compareAndSwapInt的结果作为循环条件，直至修改成功才退出死循环的方式来实现的原子性的自增操作。
        while (true) {
            try {
                long fieldOffset = unsafe.objectFieldOffset(Main.class.getDeclaredField("a"));
                // 只有在a的值等于传入的参数x减一时，才会将a的值变为x
                if (unsafe.compareAndSwapInt(this, fieldOffset, x - 1, x))
                    break;
            } catch (NoSuchFieldException e) {
                e.printStackTrace();
            }
        }
    }

    public static Unsafe getUnsafe() throws IllegalAccessException, NoSuchFieldException {
        // Field unsafeField = Unsafe.class.getDeclaredFields()[0]; //也可以这样，作用相同
        Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
        unsafeField.setAccessible(true);
        return (Unsafe) unsafeField.get(null);
    }
}
```

### 线程调度

Unsafe 类中提供了`park`、`unpark`、`monitorEnter`、`monitorExit`、`tryMonitorEnter`方法进行线程调度。

`LockSupport`的源码，可以看到它也是调用的 Unsafe 类中的方法：

```java
public static void park(Object blocker) {
    Thread t = Thread.currentThread();
    setBlocker(t, blocker);
    UNSAFE.park(false, 0L);
    setBlocker(t, null);
}

public static void unpark(Thread thread) {
    if (thread != null)
        UNSAFE.unpark(thread);
}
```

LockSupport 的`park`方法调用了 Unsafe 的`park`方法来阻塞当前线程，此方法将线程阻塞后就不会继续往后执行，直到有其他线程调用`unpark`方法唤醒当前线程。

```java
public class Main {
    public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
        Unsafe unsafe = getUnsafe();

        // 子线程开始运行后先进行睡眠，确保主线程能够调用park方法阻塞自己，子线程在睡眠 3 秒后，调用unpark方法唤醒主线程，使主线程能继续向下执行
        Thread mainThread = Thread.currentThread();
        new Thread(() -> {
            try {
                TimeUnit.SECONDS.sleep(3);
                System.out.println("subThread try to unpark mainThread");
                unsafe.unpark(mainThread);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();

        System.out.println("park main mainThread");
        unsafe.park(false, 0L);
        System.out.println("unpark mainThread success");
        /*
            park main mainThread
            subThread try to unpark mainThread
            unpark mainThread success
         */
    }

    public static Unsafe getUnsafe() throws IllegalAccessException, NoSuchFieldException {
        // Field unsafeField = Unsafe.class.getDeclaredFields()[0]; //也可以这样，作用相同
        Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
        unsafeField.setAccessible(true);
        return (Unsafe) unsafeField.get(null);
    }
}
```

Unsafe 源码中`monitor`相关的三个方法已经被标记为`deprecated`，不建议被使用：

```java
// 获得对象锁
@Deprecated
public native void monitorEnter(Object var1);
// 释放对象锁
@Deprecated
public native void monitorExit(Object var1);
// 尝试获得对象锁
@Deprecated
public native boolean tryMonitorEnter(Object var1);
```

`monitorEnter`方法用于获得对象锁，`monitorExit`用于释放对象锁，如果对一个没有被`monitorEnter`加锁的对象执行此方法，会抛出`IllegalMonitorStateException`异常。`tryMonitorEnter`方法尝试获取对象锁，如果成功则返回`true`，反之返回`false`。

### Class 操作

1.静态属性读取相关的方法：

```java
// 获取静态属性的偏移量
public native long staticFieldOffset(Field f);
// 获取静态属性的对象指针
public native Object staticFieldBase(Field f);
// 判断类是否需要实例化（用于获取类的静态属性前进行检测）
public native boolean shouldBeInitialized(Class<?> c);
```

```java
public class Main {

    public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
        Unsafe unsafe = getUnsafe();

        User user = new User();
        // false，注释掉上一行后就是true
        System.out.println(unsafe.shouldBeInitialized(User.class));
        Field sexField = User.class.getDeclaredField("name");
        // 获取静态属性的偏移量
        long fieldOffset = unsafe.staticFieldOffset(sexField);
        // 获取静态属性的对象指针
        Object fieldBase = unsafe.staticFieldBase(sexField);
        Object object = unsafe.getObject(fieldBase, fieldOffset);
        System.out.println(object);
    }

    public static Unsafe getUnsafe() throws IllegalAccessException, NoSuchFieldException {
        // Field unsafeField = Unsafe.class.getDeclaredFields()[0]; //也可以这样，作用相同
        Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
        unsafeField.setAccessible(true);
        return (Unsafe) unsafeField.get(null);
    }
}

class User {
    public static String name = "Spring";
    int age;
}
```

在上面的代码中，获取`Field`对象需要依赖`Class`，而获取静态变量的属性时则不再依赖于`Class`。

在上面的代码中，首先创建一个`User`对象，这是因为如果一个类没有被实例化，那么它的静态属性也不会被初始化，最后获取的字段属性将是`null`。所以在获取静态属性前，需要调用`shouldBeInitialized`方法，判断在获取前是否需要初始化这个类。如果删除创建 User 对象的语句，运行结果会变为：true null

2.使用`defineClass`方法允许程序在运行时动态地创建一个类，方法定义如下：

```java
public native Class<?> defineClass(String name, byte[] b, int off, int len,
                                    ClassLoader loader,ProtectionDomain protectionDomain);
```

在实际使用过程中，可以只传入字节数组、起始字节的下标以及读取的字节长度，默认情况下，类加载器（`ClassLoader`）和保护域（`ProtectionDomain`）来源于调用此方法的实例。下面的例子中实现了反编译生成后的 class 文件的功能：

```java
private static void defineTest() {
     String fileName="xxx\\User.class";
     File file = new File(fileName);
     try(FileInputStream fis = new FileInputStream(file)) {
         byte[] content=new byte[(int)file.length()];
         fis.read(content);
         Class clazz = unsafe.defineClass(null, content, 0, content.length, null, null);
         Object o = clazz.newInstance();
         Object age = clazz.getMethod("getAge").invoke(o, null);
         System.out.println(age);
     } catch (Exception e) {
         e.printStackTrace();
     }
 }
```

在上面的代码中，首先读取了一个`class`文件并通过文件流将它转化为字节数组，之后使用`defineClass`方法动态的创建了一个类，并在后续完成了它的实例化工作，且通过这种方式创建的类，会跳过 JVM 的所有安全检查。

除了`defineClass`方法外，Unsafe 还提供了一个`defineAnonymousClass`方法：

```java
public native Class<?> defineAnonymousClass(Class<?> hostClass, byte[] data, Object[] cpPatches);
```

使用该方法可以动态的创建一个匿名类，Lambda 表达式中就是使用 ASM 动态生成字节码的，然后利用该方法定义实现相应的函数式接口的匿名类。

在 JDK 15 发布的新特性中，在隐藏类（`Hidden classes`）一条中，指出将在未来的版本中弃用 Unsafe 的`defineAnonymousClass`方法。

### 系统信息

Unsafe 中提供的`addressSize`和`pageSize`方法用于获取系统信息，调用`addressSize`方法会返回系统指针的大小，如果在 64 位系统下默认会返回 8，而 32 位系统则会返回 4。调用 pageSize 方法会返回内存页的大小，值为 2 的整数幂。使用下面的代码可以直接进行打印：

```java
System.out.println(unsafe.addressSize());
System.out.println(unsafe.pageSize());
```

这两个方法的应用场景比较少，在`java.nio.Bits`类中，在使用`pageCount`计算所需的内存页的数量时，调用了`pageSize`方法获取内存页的大小。另外，在使用`copySwapMemory`方法拷贝内存时，调用了`addressSize`方法，检测 32 位系统的情况。
