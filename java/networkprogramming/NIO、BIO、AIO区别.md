---
title: NIO、BIO、AIO区别
date: 2024-08-01 10:19:31 +0800
categories: [java, network programming]
tags: [Java, Network Programming, NIO, BIO, AIO]
description: 
---
BIO 全称 Block-IO 是一种**同步且阻塞**的通信模式。是一个比较传统的通信方式，模式简单，使用方便。但并发处理能力低，通信耗时，依赖网速。

Java NIO，全程 Non-Block IO ，是 Java SE 1.4 版以后，针对网络传输效能优化的新功能。是一种**非阻塞同步**的通信模式。

NIO 与原来的 I/O 有同样的作用和目的, 他们之间最重要的区别是数据打包和传输的方式。原来的 I/O 以流的方式处理数据，而 NIO 以块的方式处理数据。

面向流的 I/O 系统一次一个字节地处理数据。一个输入流产生一个字节的数据，一个输出流消费一个字节的数据。

面向块的 I/O 系统以块的形式处理数据。每一个操作都在一步中产生或者消费一个数据块。按块处理数据比按(流式的)字节处理数据要快得多。但是面向块的 I/O 缺少一些面向流的 I/O 所具有的优雅性和简单性。

Java AIO，全称 Asynchronous IO，是**异步非阻塞**的 IO。是一种非阻塞异步的通信模式。

在 NIO 的基础上引入了新的异步通道的概念，并提供了异步文件通道和异步套接字通道的实现。

## 区别

------

**BIO （Blocking I/O）：同步阻塞 I/O 模式。**

**NIO （New I/O）：同步非阻塞模式。**

**AIO （Asynchronous I/O）：异步非阻塞 I/O 模型。**

### 适用场景

BIO 方式适用于连接数目比较小且固定的架构，这种方式对服务器资源要求比较高，并发局限于应用中，JDK1.4 以前的唯一选择，但程序直观简单易理解。

NIO 方式适用于连接数目多且连接比较短（轻操作）的架构，比如聊天服务器，并发局限于应用中，编程比较复杂，JDK1.4 开始支持。

AIO 方式适用于连接数目多且连接比较长（重操作）的架构，比如相册服务器，充分调用 OS 参与并发操作，编程比较复杂，JDK7 开始支持。

### 使用方式

```java
public class BioFileDemo {
    public static void main(String[] args) {
        BioFileDemo demo = new BioFileDemo();
        demo.writeFile();
        demo.readFile();
    }

    // 使用 BIO 写入文件
    public void writeFile() {
        String filename = "xx.txt";
        try {
            FileWriter fileWriter = new FileWriter(filename);
            BufferedWriter bufferedWriter = new BufferedWriter(fileWriter);

            bufferedWriter.write("学编程就上技术派");
            bufferedWriter.newLine();

            System.out.println("写入完成");
            bufferedWriter.close();
            fileWriter.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 使用 BIO 读取文件
    public void readFile() {
        String filename = "xx.txt";
        try {
            FileReader fileReader = new FileReader(filename);
            BufferedReader bufferedReader = new BufferedReader(fileReader);

            String line;
            while ((line = bufferedReader.readLine()) != null) {
                System.out.println("读取的内容: " + line);
            }

            bufferedReader.close();
            fileReader.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

```java
public class NioFileDemo {
    public static void main(String[] args) {
        NioFileDemo demo = new NioFileDemo();
        demo.writeFile();
        demo.readFile();
    }

    // 使用 NIO 写入文件
    public void writeFile() {
        Path path = Paths.get("cc.txt");
        try {
            FileChannel fileChannel = FileChannel.open(path, EnumSet.of(StandardOpenOption.CREATE, StandardOpenOption.WRITE));

            ByteBuffer buffer = StandardCharsets.UTF_8.encode("hh");
            fileChannel.write(buffer);

            System.out.println("写入完成");
            fileChannel.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 使用 NIO 读取文件
    public void readFile() {
        Path path = Paths.get("xx.txt");
        try {
            FileChannel fileChannel = FileChannel.open(path, StandardOpenOption.READ);
            ByteBuffer buffer = ByteBuffer.allocate(1024);

            int bytesRead = fileChannel.read(buffer);
            while (bytesRead != -1) {
                buffer.flip();
                System.out.println("读取的内容: " + StandardCharsets.UTF_8.decode(buffer));
                buffer.clear();
                bytesRead = fileChannel.read(buffer);
            }

            fileChannel.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

```java
public class AioDemo {

    public static void main(String[] args) {
        AioDemo demo = new AioDemo();
        demo.writeFile();
        demo.readFile();
    }

    // 使用 AsynchronousFileChannel 写入文件
    public void writeFile() {
        // 使用 Paths.get() 获取文件路径
        Path path = Paths.get("xx.txt");
        try {
            // 用 AsynchronousFileChannel.open() 打开文件通道，指定写入和创建文件的选项。
            AsynchronousFileChannel fileChannel = AsynchronousFileChannel.open(path, StandardOpenOption.WRITE, StandardOpenOption.CREATE);

            // 将要写入的字符串（"学编程就上技术派"）转换为 ByteBuffer。
            ByteBuffer buffer = StandardCharsets.UTF_8.encode("学编程就上技术派");
            // 调用 fileChannel.write() 方法将 ByteBuffer 中的内容写入文件。这是一个异步操作，因此需要使用 Future 对象等待写入操作完成。
            Future<Integer> result = fileChannel.write(buffer, 0);
            // 等待写操作完成
            result.get();

            System.out.println("写入完成");
            fileChannel.close();
        } catch (IOException | InterruptedException | java.util.concurrent.ExecutionException e) {
            e.printStackTrace();
        }
    }

    // 使用 AsynchronousFileChannel 读取文件
    public void readFile() {
        Path path = Paths.get("xx.txt");
        try {
            // 指定读取文件的选项。
            AsynchronousFileChannel fileChannel = AsynchronousFileChannel.open(path, StandardOpenOption.READ);
            // 创建一个 ByteBuffer，用于存储从文件中读取的数据。
            ByteBuffer buffer = ByteBuffer.allocate(1024);

            // 调用 fileChannel.read() 方法从文件中异步读取数据。该方法接受一个 CompletionHandler 对象，用于处理异步操作完成后的回调。
            fileChannel.read(buffer, 0, buffer, new CompletionHandler<Integer, ByteBuffer>() {
                @Override
                public void completed(Integer result, ByteBuffer attachment) {
                    // 在 CompletionHandler 的 completed() 方法中，翻转 ByteBuffer（attachment.flip()），然后使用 Charset.forName("UTF-8").decode() 将其解码为字符串并打印。最后，清空缓冲区并关闭文件通道。
                    attachment.flip();
                    System.out.println("读取的内容: " + StandardCharsets.UTF_8.decode(attachment));
                    attachment.clear();
                    try {
                        fileChannel.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }

                @Override
                public void failed(Throwable exc, ByteBuffer attachment) {
                    // 如果异步读取操作失败，CompletionHandler 的 failed() 方法将被调用，打印错误信息。
                    System.out.println("读取失败");
                    exc.printStackTrace();
                }
            });

            // 等待异步操作完成
            Thread.sleep(1000);

        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

