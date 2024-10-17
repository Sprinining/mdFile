---
title: Buffer和Channel
date: 2024-08-17 12:58:44 +0800
categories: [java, network programming]
tags: [Java, Network Programming, NIO, Buffer, Channel]
description: 
---




IO 和 NIO 区别：

- 可简单认为：**IO 是面向流的处理，NIO 是面向块(缓冲区)的处理**
- 面向流的 I/O 系统**一次一个字节地处理数据**。
- 一个面向块(缓冲区)的 I/O 系统**以块的形式处理数据**。

NIO 主要有**两个核心部分组成**：

- **Buffer 缓冲区**
- **Channel 通道**

相对于传统 IO 而言，**流是单向的**。对于 NIO 而言，有了 Channel 通道这个概念，**读写都是双向**的

## Buffer 缓冲区

------

Buffer 是缓冲区的抽象类，其中 ByteBuffer 是用得最多的实现类(在通道中读写字节数据)，其余还有 IntBuffer、CharBuffer、LongBuffer。

### 成员变量

Buffer 类维护了 4 个核心变量来提供关于其所包含的数组信息。

```java
// Invariants: mark <= position <= limit <= capacity
// 一个备忘位置。用于记录上一次读写的位置
private int mark = -1;
// 下一个要被读或写的元素的位置。position 会自动由相应的 get() 和 put() 函数更新
private int position = 0;
// 缓冲区里的数据的总数，代表了当前缓冲区中一共有多少数据，字节为单位
private int limit;
// 缓冲区能够容纳的数据元素的最大数量。容量在缓冲区创建时被设定，并且永远不能被改变。(底层是数组)
private int capacity;
```

```java
public static void main(String[] args) {
    // 创建一个缓冲区
    ByteBuffer byteBuffer = ByteBuffer.allocate(1024);

    // 看一下初始时4个核心变量的值
    System.out.println("初始时：");
    System.out.println("limit = " + byteBuffer.limit());
    System.out.println("position = " + byteBuffer.position());
    System.out.println("capacity = " + byteBuffer.capacity());
    System.out.println("mark = " + byteBuffer.mark());

    // 添加一些数据到缓冲区中
    String s = "嘻哈";
    byteBuffer.put(s.getBytes());

    // 看一下初始时4个核心变量的值
    System.out.println("put完之后：");
    System.out.println("limit = " + byteBuffer.limit());
    System.out.println("position = " + byteBuffer.position());
    System.out.println("capacity = " + byteBuffer.capacity());
    System.out.println("mark = " + byteBuffer.mark());
}
```

```java
初始时：
limit = 1024
position = 0
capacity = 1024
mark = java.nio.HeapByteBuffer[pos=0 lim=1024 cap=1024]
put完之后：
limit = 1024
position = 6
capacity = 1024
mark = java.nio.HeapByteBuffer[pos=6 lim=1024 cap=1024]
```

### flip、clear、rewind

`flip()`方法：使缓冲区为新的通道写入或相对获取操作序列做好准备：它将 limit 设置为 position，然后将  position 设置为零。

```java
// flip()方法
byteBuffer.flip();
System.out.println("flip()方法之后：");
System.out.println("limit = "+byteBuffer.limit());
System.out.println("position = "+byteBuffer.position());
System.out.println("capacity = "+byteBuffer.capacity());
System.out.println("mark = " + byteBuffer.mark());
```

```java
flip()方法之后：
limit = 6
position = 0
capacity = 1024
mark = java.nio.HeapByteBuffer[pos=0 lim=6 cap=1024]
```

当切换成读模式之后，就可以读取缓冲区的数据了：

```java
// 创建一个 limit() 大小的字节数组
byte[] bytes = new byte[byteBuffer.limit()];
// 装进字节数组
byteBuffer.get(bytes);
// 输出
System.out.println(new String(bytes, 0, bytes.length));
```

读完后 position 会更新到6。

```java
读完后：
limit = 6
position = 6
capacity = 1024
mark = java.nio.HeapByteBuffer[pos=6 lim=6 cap=1024]
```

`clear()` 方法，使缓冲区为新的通道读取或相对放置操作序列做好准备：它将 limit 设置为 capacity 并把 position 设置为零。

```java
clear后：
limit = 1024
position = 0
capacity = 1024
mark = java.nio.HeapByteBuffer[pos=0 lim=1024 cap=1024]
```

`rewind()` 方法，limit 不变，position 设置为零

## Channel 通道

------

Channel 通道**只负责传输数据、不直接操作数据**。操作数据都是通过 Buffer 缓冲区来进行操作！通常，通道可以分为两大类：文件通道和套接字通道。

`FileChannel`：用于文件 I/O 的通道，支持文件的读、写和追加操作。FileChannel 允许在文件的任意位置进行数据传输，支持文件锁定以及内存映射文件等高级功能。FileChannel 无法设置为非阻塞模式，因此它只适用于阻塞式文件操作。

`SocketChannel`：用于 TCP 套接字 I/O 的通道。SocketChannel 支持非阻塞模式，可以与 Selector 一起使用，实现高效的网络通信。SocketChannel 允许连接到远程主机，进行数据传输。

与之匹配的有ServerSocketChannel：用于监听 TCP 套接字连接的通道。与 SocketChannel 类似，ServerSocketChannel 也支持非阻塞模式，并可以与 Selector 一起使用。ServerSocketChannel 负责监听新的连接请求，接收到连接请求后，可以创建一个新的 SocketChannel 以处理数据传输。

`DatagramChannel`：用于 UDP 套接字 I/O 的通道。DatagramChannel 支持非阻塞模式，可以发送和接收数据报包，适用于无连接的、不可靠的网络通信。

### 文件通道 FileChannel

1. 打开一个通道

```java
FileChannel.open(Paths.get("docs/xx.md"), StandardOpenOption.WRITE);
```

2. 使用 FileChannel 配合 ByteBuffer 缓冲区实现文件复制的功能

```java
public static void main(String[] args) throws IOException {
    try (FileChannel sourceChannel = FileChannel.open(Paths.get("hello.txt"), StandardOpenOption.READ);
         FileChannel destinationChannel = FileChannel.open(Paths.get("hello2.txt"), StandardOpenOption.WRITE, StandardOpenOption.CREATE)) {
        // 创建缓冲区
        ByteBuffer buffer = ByteBuffer.allocate(1024);

        // 当 read() 方法返回 -1 时，表示已经到达文件末尾
        while (sourceChannel.read(buffer) != -1) {
            // limit 设置为 position，并将 position 置零
            buffer.flip();
            destinationChannel.write(buffer);
            // limit 设置为 capacity，并将 position 置零
            buffer.clear();
        }
    }
}
```

3. 使用内存映射文件（MappedByteBuffer）的方式实现文件复制的功能(直接操作缓冲区)

```java
public static void main(String[] args) throws IOException {
    try (FileChannel sourceChannel = FileChannel.open(Paths.get("hello.txt"), StandardOpenOption.READ);
         FileChannel destinationChannel = FileChannel.open(Paths.get("hello2.txt"), StandardOpenOption.WRITE, StandardOpenOption.CREATE, StandardOpenOption.READ)) {

        // 返回该通道文件的当前大小，字节为单位
        long fileSize = sourceChannel.size();
        // 调用 FileChannel 的 map() 方法创建 MappedByteBuffer 对象
        MappedByteBuffer sourceMappedBuffer = sourceChannel.map(FileChannel.MapMode.READ_ONLY, 0, fileSize);
        // map() 方法接受三个参数：映射模式（FileChannel.MapMode）、映射起始位置、映射的长度。
        // 映射模式包括只读模式（READ_ONLY）、读写模式（READ_WRITE）和专用模式（PRIVATE）
        MappedByteBuffer destinationMappedBuffer = destinationChannel.map(FileChannel.MapMode.READ_WRITE, 0, fileSize);

        // 逐字节地从源文件的 MappedByteBuffer 读取数据并将其写入目标文件的 MappedByteBuffer
        for (int i = 0; i < fileSize; i++) {
            byte b = sourceMappedBuffer.get(i);
            destinationMappedBuffer.put(i, b);
        }

        // 数据的修改可能不会立即写入磁盘。可以通过调用 MappedByteBuffer 的 force() 方法将数据立即写回磁盘
        destinationMappedBuffer.force();
    }
}
```

MappedByteBuffer 是 Java NIO 中的一个类，它继承自 `java.nio.ByteBuffer`。MappedByteBuffer 用于表示一个内存映射文件，即将文件的一部分或全部映射到内存中，以便通过直接操作内存来实现对文件的读写。这种方式可以提高文件 I/O 的性能，因为操作系统可以直接在内存和磁盘之间传输数据，无需通过 Java 应用程序进行额外的数据拷贝。

4. 通道之间通过`transfer()`实现数据的传输(直接操作缓冲区)

```java
public static void main(String[] args) throws IOException {
    try (FileChannel sourceChannel = FileChannel.open(Paths.get("hello.txt"), StandardOpenOption.READ);
         FileChannel destinationChannel = FileChannel.open(Paths.get("hello2.txt"), StandardOpenOption.WRITE, StandardOpenOption.CREATE, StandardOpenOption.READ)) {
        // 三个参数：源文件中开始传输的位置、要传输的字节数、接收数据的目标通道
        sourceChannel.transferTo(0, sourceChannel.size(), destinationChannel);
    } catch (IOException e) {
        throw new RuntimeException(e);
    }
}
```

FileChannel 的 `transferTo()` 方法是一个高效的文件传输方法，它允许将文件的一部分或全部内容直接从源文件通道传输到目标通道（通常是另一个文件通道或网络通道）。这种传输方式可以避免将文件数据在用户空间和内核空间之间进行多次拷贝，提高了文件传输的性能。

`transferTo()` 方法可能无法一次传输所有请求的字节。在实际应用中，需要==使用循环来确保所有字节都被传输==。

```java
public static void main(String[] args) throws IOException {
    Path sourcePath = Paths.get("hello.txt");
    Path destinationPath = Paths.get("hello2.txt");

    // 使用 try-with-resources 语句确保通道资源被正确关闭
    try (FileChannel sourceChannel = FileChannel.open(sourcePath, StandardOpenOption.READ);
         FileChannel destinationChannel = FileChannel.open(destinationPath, StandardOpenOption.CREATE, StandardOpenOption.WRITE)) {
        long position = 0;
        long count = sourceChannel.size();

        // 循环传输，直到所有字节都被传输
        while (position < count) {
            // 返回实际传输的字节数，可能为零
            long transferred = sourceChannel.transferTo(position, count - position, destinationChannel);
            position += transferred;
        }
    } catch (IOException e) {
        e.printStackTrace();
    }
}
```

此外，`transferTo()` 方法在底层使用了操作系统提供的零拷贝功能（如 Linux 的 `sendfile()` 系统调用），可以大幅提高文件传输性能。但是，不同操作系统和 JVM 实现可能会影响零拷贝的可用性和性能，因此实际性能可能因环境而异。

零拷贝（Zero-Copy）是一种优化数据传输性能的技术，它最大限度地减少了在数据传输过程中的 CPU 和内存开销。在传统的数据传输过程中，数据通常需要在用户空间和内核空间之间进行多次拷贝，这会导致额外的 CPU 和内存开销。零拷贝技术通过避免这些多余的拷贝操作，实现了更高效的数据传输。

在 Java 中，零拷贝技术主要应用于文件和网络 I/O。FileChannel 类的 `transferTo()` 和 `transferFrom()` 方法就利用了零拷贝技术，可以在文件和网络通道之间高效地传输数据。

### 直接和非直接缓冲区

非直接缓冲区：

- 分配在 JVM 堆内存中
- 受到垃圾回收的管理
- 在读写操作时，需要将数据从堆内存复制到操作系统的本地内存，再进行 I/O 操作
- 创建： `ByteBuffer.allocate(int capacity)`

直接缓冲区：

- 分配在操作系统的本地内存中
- 不受垃圾回收的管理
- 在读写操作时，直接在本地内存中进行，避免了数据复制，提高了性能
- 创建： `ByteBuffer.allocateDirect(int capacity)`
- `FileChannel.map()` 方法，会返回一个类型为 MappedByteBuffer 的直接缓冲区。

ByteBuffer.allocate和ByteBuffer.allocateDirect直接的差异：

```java
// position 置零，limit 设为 capacity，mark 未定义，所有元素初始化为0
public static ByteBuffer allocate(int capacity) {
    // 缓冲区容量字节数
    if (capacity < 0)
        throw new IllegalArgumentException();
    // 非直接缓冲区
    return new HeapByteBuffer(capacity, capacity);
}
```

```java
// position 置零，limit 设为 capacity，mark 未定义，所有元素初始化为0
public static ByteBuffer allocateDirect(int capacity) {
    // 直接缓冲区
    return new DirectByteBuffer(capacity);
}
```

非直接缓冲区存储在JVM内部，数据需要从应用程序（Java）复制到非直接缓冲区，再复制到内核缓冲区，最后发送到设备（磁盘/网络）。而对于直接缓冲区，数据可以直接从应用程序（Java）复制到内核缓冲区，无需经过JVM的非直接缓冲区。

### 异步文件通道 AsynchronousFileChannel

AsynchronousFileChannel 是 Java 7 引入的一个异步文件通道类，提供了对文件的异步读、写、打开和关闭等操作。

可以通过 `AsynchronousFileChannel.open()` 方法打开一个异步文件通道，该方法接受一个 Path 对象和一组打开选项（如 StandardOpenOption.READ、StandardOpenOption.WRITE 等）作为参数。

```java
Path file = Paths.get("example.txt");
AsynchronousFileChannel fileChannel = AsynchronousFileChannel.open(file, StandardOpenOption.READ, StandardOpenOption.WRITE);
```

AsynchronousFileChannel 提供了两种异步操作的方式：

#### Future 方式

使用 Future 对象来跟踪异步操作的完成情况。当我们调用一个异步操作（如 `read()` 或 `write()`）时，它会立即返回一个 Future 对象。可以使用这个对象来检查操作是否完成，以及获取操作的结果。这种方式适用于不需要在操作完成时立即执行其他操作的场景。

```java
public static void main(String[] args) throws IOException, ExecutionException, InterruptedException {
    Path path = Paths.get("hello.txt");

    try (AsynchronousFileChannel fileChannel = AsynchronousFileChannel.open(path, StandardOpenOption.READ)) {
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        long position = 0;

        while (true) {
            Future<Integer> result = fileChannel.read(buffer, position);

            while (!result.isDone()) {
                // 在这里可以执行其他任务，例如处理其他 I/O 操作
            }

            // 获取实际读取的字节数
            int bytesRead = result.get();
            if (bytesRead <= 0) break;

            position += bytesRead;
            buffer.flip();
            byte[] data = new byte[buffer.limit()];
            buffer.get(data);
            System.out.println(new String(data));

            buffer.clear();
        }
    }
}
```

#### CompletionHandler 方式

使用一个实现了 CompletionHandler 接口的对象来处理异步操作的完成。我们需要提供一个 CompletionHandler 实现类，重写 `completed()` 和 `failed()` 方法，分别处理操作成功和操作失败的情况。当异步操作完成时，系统会自动调用相应的方法。这种方式适用于需要在操作完成时立即执行其他操作的场景。

```java
public class Main {
    public static void main(String[] args) throws IOException, InterruptedException {
        readAllBytes(Paths.get("hello.txt"));
    }

    public static void readAllBytes(Path path) throws IOException, InterruptedException {
        AsynchronousFileChannel fileChannel = AsynchronousFileChannel.open(path, StandardOpenOption.READ);
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        // 记录当前读取的文件位置
        AtomicLong position = new AtomicLong(0);
        // 异步操作完成时通知主线程
        CountDownLatch latch = new CountDownLatch(1);

        // 异步读取
        // 参数包括：用于存储数据的缓冲区、当前读取位置、附加对象（在这个例子中不需要，所以传递 null）以及一个实现了 CompletionHandler 接口的对象，用于在读取操作完成时回调。
        fileChannel.read(buffer, position.get(), null, new CompletionHandler<Integer, Object>() {
            @Override
            public void completed(Integer bytesRead, Object attachment) {
                // 大于 0，说明还有数据需要读取
                if (bytesRead > 0) {
                    position.addAndGet(bytesRead);
                    buffer.flip();
                    byte[] data = new byte[buffer.limit()];
                    buffer.get(data);
                    System.out.print(new String(data));
                    buffer.clear();

                    // 再次调用 fileChannel.read() 方法，以继续从文件中读取数据
                    fileChannel.read(buffer, position.get(), attachment, this);
                } else {
                    // 如果 bytesRead 等于或小于 0，说明我们已经读取完文件中的所有数据。
                    // 此时调用 latch.countDown() 方法，以通知主线程异步操作已完成。关闭 fileChannel
                    latch.countDown();
                    try {
                        fileChannel.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }

            @Override
            public void failed(Throwable exc, Object attachment) {
                System.out.println("Error: " + exc.getMessage());
                latch.countDown();
            }
        });

        // 主线程将在此处阻塞，直到 latch 的计数变为 0
        latch.await();
    }
}
```

