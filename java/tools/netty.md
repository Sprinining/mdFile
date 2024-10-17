---
title: netty
date: 2022-03-21 03:35:24 +0800
categories: [java, tools]
tags: [Java, Netty]
description: 
---
# Netty

## Buffer

```java
IntBuffer intBuffer = IntBuffer.allocate(5);

for (int i = 0; i < intBuffer.capacity(); i++) {
    intBuffer.put(i);
}

// 读写切换
intBuffer.flip();
while (intBuffer.hasRemaining()) {
    // 每次get，指针都会后移
    System.out.println(intBuffer.get());
}
```

### 类型化放入

```java
public static void main(String[] args) throws Exception {
    ByteBuffer buffer = ByteBuffer.allocate(64);

    // 类型化方式放入数据
    buffer.putInt(100);
    buffer.putChar('*');
    buffer.putLong(1L);

    buffer.flip();

    // 取出的顺序必须一致
    System.out.println(buffer.getInt());
    System.out.println(buffer.getChar());
    System.out.println(buffer.getLong());
}
```

### 只读

```java
public static void main(String[] args) throws Exception {
    ByteBuffer buffer = ByteBuffer.allocate(64);

    for (int i = 0; i < buffer.capacity(); i++) {
        buffer.put((byte) i);
    }

    buffer.flip();

    // 只读
    ByteBuffer readOnlyBuffer = buffer.asReadOnlyBuffer();
    while (readOnlyBuffer.hasRemaining()) {
        System.out.println(readOnlyBuffer.get());
    }

    // 会抛异常java.nio.ReadOnlyBufferException
    readOnlyBuffer.put((byte) 1);
}
```

### MappedByteBuffer

```java
public static void main(String[] args) throws Exception {
    RandomAccessFile randomAccessFile = new RandomAccessFile("file", "rw");
    FileChannel channel = randomAccessFile.getChannel();

    /**
     * 可让文件直接在堆外内存修改，不需要OS拷贝一次
     * 读写模式，可以直接修改的起始位置，映射到内存的大小（字节）
     * 可以直接修改的位置[0,5)
     * 实际类型是DirectByteBuffer
     */
    MappedByteBuffer map = channel.map(FileChannel.MapMode.READ_WRITE, 0, 5);
    map.put(0, (byte) 'X');
    map.put(4, (byte) 'Y');
    randomAccessFile.close();
}
```

### Buffer数组

```java
public static void main(String[] args) throws Exception {
    ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();
    InetSocketAddress inetSocketAddress = new InetSocketAddress(8888);
    // 绑定端口并启动
    serverSocketChannel.socket().bind(inetSocketAddress);

    ByteBuffer[] byteBuffers = new ByteBuffer[2];
    byteBuffers[0] = ByteBuffer.allocate(5);
    byteBuffers[1] = ByteBuffer.allocate(3);

    SocketChannel socketChannel = serverSocketChannel.accept();
    int count = 8;
    while (true) {
        int byteRead = 0;
        while (byteRead < count) {
            long l = socketChannel.read(byteBuffers);
            byteRead += l;
            System.out.println("byteRead:" + l);
            // 流打印
            Arrays.stream(byteBuffers)
                    .map(buffer -> "position:" + buffer.position()
                            + ", limit:" + buffer.limit())
                    .forEach(System.out::println);
        }

        // flip
        Arrays.asList(byteBuffers)
                .forEach(ByteBuffer::flip);

        // 读出数据显示在客户端
        long byteWrite = 0;
        while (byteWrite < count) {
            long l = socketChannel.write(byteBuffers);
            byteWrite += l;
        }

        // clear
        Arrays.asList(byteBuffers)
                .forEach(ByteBuffer::clear);
    }
}
```

## Channel

### ByteBuffer

```java
public static void main(String[] args) throws Exception {
    FileInputStream fileInputStream = new FileInputStream("file");
    FileChannel channel1 = fileInputStream.getChannel();

    FileOutputStream fileOutputStream = new FileOutputStream("file.txt");
    FileChannel channel2 = fileOutputStream.getChannel();

    ByteBuffer byteBuffer = ByteBuffer.allocate(1024);
    while (true) {
    /*    public Buffer clear() {
            position = 0;
            limit = capacity;
            mark = -1;
            return this;
        }*/
        byteBuffer.clear();

        // 从channel读出，放入到byteBuffer
        int read = channel1.read(byteBuffer);
        if (read == -1) {
            break;
        }

        // 将byteBuffer写入channel2
        byteBuffer.flip();
        channel2.write(byteBuffer);
    }

    fileInputStream.close();
    fileOutputStream.close();
}
```

### transferTo&transferFrom

```java
public static void main(String[] args) throws Exception {
    FileInputStream fileInputStream = new FileInputStream("file");
    FileChannel sourceChannel = fileInputStream.getChannel();

    FileOutputStream fileOutputStream = new FileOutputStream("file.txt");
    FileChannel destChannel = fileOutputStream.getChannel();

    // destChannel.transferFrom(sourceChannel, 0, sourceChannel.size());
    sourceChannel.transferTo(0, sourceChannel.size(), destChannel);

    fileInputStream.close();
    fileOutputStream.close();
}
```

## Selector

- 一个EventLoopGroup（事件循环组） 包含一个或者多个EventLoop；
- 一个EventLoop 在它的生命周期内只和一个Thread 绑定；
- 所有由EventLoop 处理的I/O 事件都将在它专有的Thread 上被处理；
- 一个Channel 在它的生命周期内只注册于一个EventLoop；
- 一个EventLoop 可能会被分配给一个或多个Channel。



- 有客户端连接时，会通过ServerSocketChannel得到SocketChannel
- 将SocketChannel注册到Selector上，`register(Selector sel, int ops, Object att)`，返回SelectionKey，会和该Selector上关联(集合)。一个Selector上可以注册多个SocketChannel
- Selector会用select方法进行监听，返回发生事件的通道个数
- 得到有事件发生的Channel的SelectionKey，然后得到该Channel

```java
selector.select(); // 阻塞
selector.select(100); // 阻塞100ms后返回
selector.wakeup(); // 唤醒
selector.selectNow();// 不阻塞，立刻返回
```

### NIO服务器

```java
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.Set;

class NIOServer {
    public static void main(String[] args) throws Exception {
        ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();

        Selector selector = Selector.open();

        serverSocketChannel.socket().bind(new InetSocketAddress(7899));
        // 设为非阻塞
        serverSocketChannel.configureBlocking(false);
        // 把serverSocketChannel注册到selector上，关心事件为OP_ACCEPT
        serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);

        // 等待连接
        while (true) {
            if (selector.select(1000) == 0) {
                System.out.println("服务器等待1s，无连接");
                continue;
            }

            // 返回关注事件的集合
            Set<SelectionKey> selectionKeys = selector.selectedKeys();
            // 迭代器遍历
            Iterator<SelectionKey> iterator = selectionKeys.iterator();
            while (iterator.hasNext()) {
                // 获取SelectionKey
                SelectionKey key = iterator.next();

                // 根据事件做相应处理
                if (key.isAcceptable()) {
                    // 新客户端连接
                    // accept实际不会阻塞，因为已经知道是OP_ACCEPT事件
                    SocketChannel socketChannel = serverSocketChannel.accept();
                    socketChannel.configureBlocking(false);
                    System.out.println("客户端连接成功" + socketChannel.hashCode());
                    // 注册到selector，关心事件为OP_READ，同时关联一个buffer
                    socketChannel.register(selector, SelectionKey.OP_READ, ByteBuffer.allocate(10));
                }

                if (key.isReadable()) {
                    // 通过key反向获取对应的Channel
                    SocketChannel channel = (SocketChannel) key.channel();
                    // 通过key获取Buffer
                    ByteBuffer byteBuffer = (ByteBuffer) key.attachment();
                    channel.read(byteBuffer);
                    System.out.println("客户端发来：" + new String(byteBuffer.array(), StandardCharsets.UTF_8));
                }

                // 从集合移动当前selectionKey，防止重复操作
                iterator.remove();
            }

        }
    }
}
```

### NIO客户端

```java
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;

class NIOClient {
    public static void main(String[] args) throws Exception {
        SocketChannel socketChannel = SocketChannel.open();
        // 设置非阻塞
        socketChannel.configureBlocking(false);
        InetSocketAddress inetSocketAddress = new InetSocketAddress("127.0.0.1", 7899);
        if (!socketChannel.connect(inetSocketAddress)) {
            while (!socketChannel.finishConnect()) {
                System.out.println("连接中，客户端不会阻塞，可以做其他事");
            }
        }

        // 连接成功后
        ByteBuffer byteBuffer = ByteBuffer.wrap("haha".getBytes(StandardCharsets.UTF_8));
        // 将buffer写入channel
        socketChannel.write(byteBuffer);
        System.in.read();
    }
}
```

## 零拷贝

### todo

## Reactor模式

### 单Reactor单线程

- **优点：**模型简单，没有多线程、进程通信和竞争的问题，全部都在一个线程中完成。

- **缺点：**
  - 性能问题，只有一个线程，无法发挥多核CPU的性能，Handler在处理某个连接业务时，整个进程无法处理其他连接事件，很容易导致性能瓶颈。
  - 可靠性问题，线程意外终止或进入死循环，会导致整个系统通信模块不可用，不能接收和处理外部消息，造成节点故障。

- GroupChatServer

```java
package groupchat;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.Scanner;
import java.util.concurrent.TimeUnit;

public class GroupChatClient {
    private static final String HOST = "127.0.0.1";
    private static final int PORT = 9998;
    private Selector selector;
    private SocketChannel socketChannel;
    private String userName;

    public GroupChatClient() {
        try {
            selector = Selector.open();
            socketChannel = SocketChannel.open();
            socketChannel.connect(new InetSocketAddress(HOST, PORT));
            socketChannel.configureBlocking(false);
            socketChannel.register(selector, SelectionKey.OP_READ);
            userName = socketChannel.getLocalAddress().toString().substring(1);
            System.out.println(userName + " is ok...");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void sendInfo(String info) {
        info = userName + " 说：" + info;
        try {
            socketChannel.write(ByteBuffer.wrap(info.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void readInfo() {
        try {
            int count = selector.select();
            if (count > 0) {
                Iterator<SelectionKey> iterator = selector.selectedKeys().iterator();
                while (iterator.hasNext()) {
                    SelectionKey key = iterator.next();
                    if (key.isReadable()) {
                        SocketChannel channel = (SocketChannel) key.channel();
                        ByteBuffer buffer = ByteBuffer.allocate(1024);
                        channel.read(buffer);
                        System.out.println(new String(buffer.array(), StandardCharsets.UTF_8));
                    }
                }
                iterator.remove();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        GroupChatClient groupChatClient = new GroupChatClient();
        new Thread(() -> {
            while (true) {
                groupChatClient.readInfo();
                try {
                    TimeUnit.SECONDS.sleep(3);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }).start();

        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNextLine()) {
            String s = scanner.nextLine();
            groupChatClient.sendInfo(s);
        }
    }
}

```

- GroupChatClient

```java
package groupchat;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.Scanner;
import java.util.concurrent.TimeUnit;

public class GroupChatClient {
    private static final String HOST = "127.0.0.1";
    private static final int PORT = 9998;
    private Selector selector;
    private SocketChannel socketChannel;
    private String userName;

    public GroupChatClient() {
        try {
            selector = Selector.open();
            socketChannel = SocketChannel.open();
            socketChannel.connect(new InetSocketAddress(HOST, PORT));
            socketChannel.configureBlocking(false);
            socketChannel.register(selector, SelectionKey.OP_READ);
            userName = socketChannel.getLocalAddress().toString().substring(1);
            System.out.println(userName + " is ok...");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void sendInfo(String info) {
        info = userName + " 说：" + info;
        try {
            socketChannel.write(ByteBuffer.wrap(info.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void readInfo() {
        try {
            int count = selector.select();
            if (count > 0) {
                Iterator<SelectionKey> iterator = selector.selectedKeys().iterator();
                while (iterator.hasNext()) {
                    SelectionKey key = iterator.next();
                    if (key.isReadable()) {
                        SocketChannel channel = (SocketChannel) key.channel();
                        ByteBuffer buffer = ByteBuffer.allocate(1024);
                        channel.read(buffer);
                        System.out.println(new String(buffer.array(), StandardCharsets.UTF_8));
                    }
                }
                iterator.remove();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        GroupChatClient groupChatClient = new GroupChatClient();
        new Thread(() -> {
            while (true) {
                groupChatClient.readInfo();
                try {
                    TimeUnit.SECONDS.sleep(3);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }).start();

        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNextLine()) {
            String s = scanner.nextLine();
            groupChatClient.sendInfo(s);
        }
    }
}
```

### 单Reactor多线程

- **流程**

1、Reactor对象通过select监听客户端请求事件，收到事件后，通过dispatch进行分发。

2、如果建立连接请求，则Acceptor通过accept处理连接请求，然后创建一个Handler对象处理完成连接后的各种事件。

3、如果不是连接请求，则由reactor分发调用连接对应的handler来处理。

4、handler只负责相应事件，不做具体的业务处理，通过read读取数据后，会分发给后面的worker线程池的某个线程处理业务。

5、worker线程池会分配独立线程完成真正的业务，并将结果返回给handler。

6、handler收到响应后，通过send分发将结果返回给client。

- **优点：可以充分利用多核cpu的处理能力**

- **缺点：多线程数据共享和访问比较复杂，rector处理所有的事件的监听和响应，在单线程运行，在高并发应用场景下，容易出现性能瓶颈。**

### 主从Reactor多线程

- **流程**

1、Reactor主线程MainReactor对象通过select监听连接事件，收到事件后，通过Acceptor处理连接事件。

2、当Acceptor处理连接事件后，MainReactor将连接分配给SubAcceptor。

3、SubAcceptor将连接加入到连接队列进行监听，并创建handler进行各种事件处理。

4、当有新事件发生时，SubAcceptor就会调用对应的handler进行各种事件处理。

5、handler通过read读取数据，分发给后面的work线程处理。

6、work线程池分配独立的work线程进行业务处理，并返回结果。

7、handler收到响应的结果后，再通过send返回给client。

**注意：Reactor主线程可以对应多个Reactor子线程，即SubAcceptor。**

## Netty案例

### Netty服务器

- NettyServer.java

```java
package netty;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.*;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.util.NettyRuntime;

public class NettyServer {
    public static void main(String[] args) throws Exception {
        //创建BossGroup 和 WorkerGroup
        //说明
        //1. 创建两个线程组 bossGroup 和 workerGroup
        //2. bossGroup 只是处理连接请求 , 真正的和客户端业务处理，会交给 workerGroup完成
        //3. 两个都是无限循环
        //4. bossGroup 和 workerGroup 含有的子线程(NioEventLoop)的个数
        //   默认实际 NettyRuntime.availableProcessors() * 2
        //
        EventLoopGroup bossGroup = new NioEventLoopGroup(1);
        EventLoopGroup workerGroup = new NioEventLoopGroup(); //8
        try {
            //创建服务器端的启动对象，配置参数
            ServerBootstrap bootstrap = new ServerBootstrap();
            //使用链式编程来进行设置
            bootstrap.group(bossGroup, workerGroup) //设置两个线程组
                    .channel(NioServerSocketChannel.class) //bossGroup使用NioSocketChannel 作为服务器的通道实现
                    .option(ChannelOption.SO_BACKLOG, 128) // 设置线程队列得到连接个数 option主要是针对boss线程组，
                    .childOption(ChannelOption.SO_KEEPALIVE, true) //设置保持活动连接状态 child主要是针对worker线程组
                    .childHandler(new ChannelInitializer<SocketChannel>() {//workerGroup使用 SocketChannel创建一个通道初始化对象                                                                                           (匿名对象)
                        //给pipeline 设置处理器
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            //可以使用一个集合管理 SocketChannel， 再推送消息时，可以将业务加入到各个channel 对应的 NIOEventLoop 的                            taskQueue 或者 scheduleTaskQueue
                            ch.pipeline().addLast(new NettyServerHandler());
                        }
                    }); // 给workerGroup 的 EventLoop 对应的管道设置处理器

            System.out.println(".....服务器 is ready...");
            //绑定一个端口并且同步, 生成了一个 ChannelFuture 对象
            //启动服务器(并绑定端口)
            ChannelFuture channelFuture = bootstrap.bind(8888).sync();
            //channelFuture注册监听器，监控我们关心的事件
            channelFuture.addListener(new ChannelFutureListener() {
                @Override
                public void operationComplete(ChannelFuture future) throws Exception {
                    if (channelFuture.isSuccess()) {
                        System.out.println("服务已启动,端口号为8888...");
                    } else {
                        System.out.println("服务启动失败...");
                    }
                }
            });
            //对关闭通道进行监听
            channelFuture.channel().closeFuture().sync();
        } finally {
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }
}
```

- NettyServerHandler.java

```java
package netty;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.util.CharsetUtil;

import java.util.concurrent.TimeUnit;

public class NettyServerHandler extends ChannelInboundHandlerAdapter {
    //读取数据实际(这里我们可以读取客户端发送的消息)
    /*
    1. ChannelHandlerContext ctx:上下文对象, 含有 管道pipeline , 通道channel, 地址
    2. Object msg: 就是客户端发送的数据 默认Object
     */
    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        System.out.println("server ctx =" + ctx);
        Channel channel = ctx.channel();
        //将 msg 转成一个 ByteBuf
        //ByteBuf 是 Netty 提供的，不是 NIO 的 ByteBuffer.
        ByteBuf buf = (ByteBuf) msg;
        System.out.println("客户端发送消息是:" + buf.toString(CharsetUtil.UTF_8));
        System.out.println("客户端地址:" + channel.remoteAddress());

        // 提交到taskQueue
        ctx.channel().eventLoop().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    TimeUnit.SECONDS.sleep(3);
                    System.out.println("延迟3s后执行的结果");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        });

        // 提交到scheduleTaskQueue
        ctx.channel().eventLoop().schedule(new Runnable() {
            @Override
            public void run() {
                System.out.println("定时4s后执行的结果");
            }
        }, 4, TimeUnit.SECONDS);
    }


    //数据读取完毕
    @Override
    public void channelReadComplete(ChannelHandlerContext ctx) throws Exception {
        //writeAndFlush 是 write + flush
        //将数据写入到缓存，并刷新
        //一般讲，我们对这个发送的数据进行编码
        ctx.writeAndFlush(Unpooled.copiedBuffer("公司最近账户没啥钱，再等几天吧！", CharsetUtil.UTF_8));
    }

    //处理异常, 一般是需要关闭通道
    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        ctx.close();
    }
}
```

### Netty客户端

- NettyClient.java

```java
package netty;

import io.netty.bootstrap.Bootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;

public class NettyClient {
    public static void main(String[] args) throws Exception {
        //客户端需要一个事件循环组
        EventLoopGroup group = new NioEventLoopGroup();
        try {
            //创建客户端启动对象
            //注意客户端使用的不是 ServerBootstrap 而是 Bootstrap
            Bootstrap bootstrap = new Bootstrap();
            //设置相关参数
            bootstrap.group(group) //设置线程组
                    .channel(NioSocketChannel.class) // 设置客户端通道的实现类(反射)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            ch.pipeline().addLast(new NettyClientHandler()); //加入自己的处理器
                        }
                    });
            System.out.println("客户端 ok..");
            //启动客户端去连接服务器端
            //关于 ChannelFuture 要分析，涉及到netty的异步模型
            ChannelFuture channelFuture = bootstrap.connect("127.0.0.1", 8888).sync();
            //给关闭通道进行监听
            channelFuture.channel().closeFuture().sync();
        } finally {
            group.shutdownGracefully();
        }
    }
}
```

- NettyClientHandler.java

```java
package netty;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.util.CharsetUtil;

public class NettyClientHandler extends ChannelInboundHandlerAdapter {

    //当通道就绪就会触发该方法
    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        System.out.println("client ctx =" + ctx);
        ctx.writeAndFlush(Unpooled.copiedBuffer("老板，工资什么时候发给我啊？", CharsetUtil.UTF_8));
    }

    //当通道有读取事件时，会触发
    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        ByteBuf buf = (ByteBuf) msg;
        System.out.println("服务器回复的消息:" + buf.toString(CharsetUtil.UTF_8));
        System.out.println("服务器的地址： "+ ctx.channel().remoteAddress());
    }

    //处理异常, 一般是需要关闭通道
    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        cause.printStackTrace();
        ctx.close();
    }
}
```

## Netty群聊

### 服务器

- GroupChatServer.java

```java
package nettygroupchat;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.*;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import io.netty.handler.logging.LogLevel;
import io.netty.handler.logging.LoggingHandler;
import io.netty.handler.timeout.IdleStateHandler;

public class GroupChatServer {

    private final int port;

    public GroupChatServer(int port) {
        this.port = port;
    }

    public void run() {
        EventLoopGroup bossGroup = new NioEventLoopGroup(1);
        EventLoopGroup workGroup = new NioEventLoopGroup();
        try {
            ServerBootstrap serverBootstrap = new ServerBootstrap()
                    .group(bossGroup, workGroup)
                    .channel(NioServerSocketChannel.class)
                    .option(ChannelOption.SO_BACKLOG, 128)
                    .childOption(ChannelOption.SO_KEEPALIVE, true)
                    .handler(new LoggingHandler(LogLevel.INFO))
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel socketChannel) throws Exception {
                            ChannelPipeline pipeline = socketChannel.pipeline();
                            pipeline.addLast(new StringDecoder());
                            pipeline.addLast(new StringEncoder());
                            // 多长时间没有读，写，读写，就会发送一个心跳检测是否连接
                            // IdleStateEvent触发后，会传递给管道下一个handler的userEventTriggered
                            pipeline.addLast(new IdleStateHandler(3, 5, 7));
                            // 对空闲检测做处理的handler
                            pipeline.addLast(new HeartBeatHandler());
                            pipeline.addLast(new GroupChatServerHandler());
                        }
                    });

            ChannelFuture channelFuture = serverBootstrap.bind(port).sync();
            channelFuture.channel().closeFuture().sync();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            bossGroup.shutdownGracefully();
            workGroup.shutdownGracefully();
        }
    }

    public static void main(String[] args) {
        GroupChatServer groupChatServer = new GroupChatServer(7788);
        groupChatServer.run();
    }
}
```

- GroupChatServerHandler.java

```java
package nettygroupchat;

import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.channel.group.ChannelGroup;
import io.netty.channel.group.DefaultChannelGroup;
import io.netty.util.concurrent.GlobalEventExecutor;

import java.text.SimpleDateFormat;

public class GroupChatServerHandler extends SimpleChannelInboundHandler<String> {

    // channel组，管理所有的Channel，必须是static。GlobalEventExecutor.INSTANCE是单例的全局事件执行器
    private static ChannelGroup channelGroup = new DefaultChannelGroup(GlobalEventExecutor.INSTANCE);
    SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    // 建立连接后第一个执行的方法
    @Override
    public void handlerAdded(ChannelHandlerContext ctx) throws Exception {
        Channel channel = ctx.channel();
        // 将该用户加入聊天的信息推送给其他在线用户
        // 自动遍历channelGroup中的channel并发送
        channelGroup.writeAndFlush("[客户端]" + channel.remoteAddress() + "加入聊天\n");
        // 当前channel加入组
        channelGroup.add(channel);
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        System.out.println(ctx.channel().remoteAddress() + "上线了");
    }

    @Override
    public void channelInactive(ChannelHandlerContext ctx) throws Exception {
        System.out.println(ctx.channel().remoteAddress() + "离线了");
    }

    @Override
    public void handlerRemoved(ChannelHandlerContext ctx) throws Exception {
        channelGroup.writeAndFlush("[客户端]" + ctx.channel().remoteAddress() + "离开了\n");
        // channelGroup会自动去掉当前channel
        System.out.println("channelGroup.size()=" + channelGroup.size());
    }

    @Override
    protected void channelRead0(ChannelHandlerContext channelHandlerContext, String s) throws Exception {
        Channel channel = channelHandlerContext.channel();
        channelGroup.forEach(ch -> {
            if (ch != channel) {
                ch.writeAndFlush("[客户端]" + channel.remoteAddress() + "发送：" + s + "\n");
            } else {
                ch.writeAndFlush("[自己]" + channel.remoteAddress() + "发送：" + s + "\n");
            }
        });
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        ctx.close();
    }
}
```

- HeartBeatHandler.java

```java
package nettygroupchat;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.timeout.IdleStateEvent;

public class HeartBeatHandler extends ChannelInboundHandlerAdapter {
    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof IdleStateEvent) {
            IdleStateEvent event = (IdleStateEvent) evt;
            String eventType = "";
            switch (event.state()) {
                case READER_IDLE:
                    eventType = "读空闲";
                    break;
                case WRITER_IDLE:
                    eventType = "写空闲";
                    break;
                case ALL_IDLE:
                    eventType = "读写空闲";
                    break;
            }
            System.out.println(ctx.channel().remoteAddress() + " 超时时间 " + eventType);
        }
    }
}
```

### 客户端

- GroupChatClient.java

```java
package nettygroupchat;

import io.netty.bootstrap.Bootstrap;
import io.netty.channel.*;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;

import java.util.Scanner;

public class GroupChatClient {
    private final String HOST;
    private final int PORT;

    public GroupChatClient(String HOST, int PORT) {
        this.HOST = HOST;
        this.PORT = PORT;
    }

    public void run() {
        EventLoopGroup eventLoopGroup = new NioEventLoopGroup();
        try {
            Bootstrap bootstrap = new Bootstrap()
                    .group(eventLoopGroup)
                    .channel(NioSocketChannel.class)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel socketChannel) throws Exception {
                            ChannelPipeline pipeline = socketChannel.pipeline();
                            pipeline.addLast(new StringDecoder());
                            pipeline.addLast(new StringEncoder());
                            pipeline.addLast(new GroupChatClientHandler());
                        }
                    });

            ChannelFuture channelFuture = bootstrap.connect(HOST, PORT).sync();
            Channel channel = channelFuture.channel();
            System.out.println(channel.remoteAddress() + "登录");
            Scanner scanner = new Scanner(System.in);
            while (scanner.hasNextLine()) {
                channel.writeAndFlush(scanner.nextLine() + "\n");
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            eventLoopGroup.shutdownGracefully();
        }

    }

    public static void main(String[] args) {
        new GroupChatClient("127.0.0.1", 7788).run();
    }
}
```

- GroupChatClientHandler.java

```java
package nettygroupchat;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;

public class GroupChatClientHandler extends SimpleChannelInboundHandler<String> {
    @Override
    protected void channelRead0(ChannelHandlerContext channelHandlerContext, String s) throws Exception {
        System.out.println(s.trim());
    }
}
```

## Protobuf



## Handler链调用机制

- 编解码handler接收到数据类型必须和待处理的数据类型一致，否则不会执行
- 解码器解码时，需要判断byteBuf中的数据是否足够

### 编码器

- MyLongToByteEncoder.java

```java
package inboundhandler;

import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.MessageToByteEncoder;

public class MyLongToByteEncoder extends MessageToByteEncoder<Long> {
    @Override
    protected void encode(ChannelHandlerContext channelHandlerContext, Long aLong, ByteBuf byteBuf) throws Exception {
        System.out.println("编码器被调用");
        byteBuf.writeLong(aLong);
    }
}
```

### 解码器

- MyByteToLongDecoder.java

```java
package inboundhandler;

import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.ByteToMessageDecoder;

import java.util.List;

public class MyByteToLongDecoder extends ByteToMessageDecoder {
    // 根据接收的数据会被调用多次。直到没有新元素添加到list中，或者byteBuf没有可读字节。
    // 如果list不为空就会把list中的数据传递给下一个channelInboundHandler处理
    @Override
    protected void decode(ChannelHandlerContext channelHandlerContext, ByteBuf byteBuf, List<Object> list) throws Exception {
        System.out.println("解码器被调用");
        // 有8字节才能读取一个Long
        if (byteBuf.readableBytes() >= 8) {
            list.add(byteBuf.readLong());
        }
    }
}
```

### 服务器

- MyServer.java

```java
package inboundhandler;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.nio.NioServerSocketChannel;

public class MyServer {
    public static void main(String[] args) {
        EventLoopGroup bossGroup = new NioEventLoopGroup(1);
        EventLoopGroup workerGroup = new NioEventLoopGroup();
        try {
            ServerBootstrap serverBootstrap = new ServerBootstrap()
                    .group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .childHandler(new MyServerChannelInitializer());
            ChannelFuture sync = serverBootstrap.bind(9898).sync();
            sync.channel().closeFuture().sync();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }
}
```

- MyServerChannelInitializer.java

```java
package inboundhandler;

import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.socket.SocketChannel;

public class MyServerChannelInitializer extends ChannelInitializer<SocketChannel> {
    @Override
    protected void initChannel(SocketChannel socketChannel) throws Exception {
        ChannelPipeline pipeline = socketChannel.pipeline();
        // 入栈时从pipeline最前面开始
        pipeline.addLast(new MyByteToLongDecoder());
        pipeline.addLast(new MyLongToByteEncoder());
        pipeline.addLast(new MyServerHandler());
    }
}
```

- MyServerHandler.java

```java
package inboundhandler;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;

public class MyServerHandler extends SimpleChannelInboundHandler<Long> {

    @Override
    protected void channelRead0(ChannelHandlerContext channelHandlerContext, Long aLong) throws Exception {
        System.out.println("从客户端" + channelHandlerContext.channel().remoteAddress() + "读取到long：" + aLong);
        System.out.println("服务器发送消息");
        // 给客户端发送Long
        channelHandlerContext.writeAndFlush(8828L);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        cause.printStackTrace();
        ctx.close();
    }
}
```

### 客户端

- MyClient.java

```java
package inboundhandler;

import io.netty.bootstrap.Bootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.nio.NioSocketChannel;

public class MyClient {
    public static void main(String[] args) {
        NioEventLoopGroup eventExecutors = new NioEventLoopGroup();
        try {
            Bootstrap bootstrap = new Bootstrap()
                    .group(eventExecutors)
                    .channel(NioSocketChannel.class)
                    .handler(new MyClientChannelInitializer());
            ChannelFuture channelFuture = bootstrap.connect("127.0.0.1", 9898);
            channelFuture.channel().closeFuture().sync();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            eventExecutors.shutdownGracefully();
        }
    }
}
```

- MyClientChannelInitializer.java

```java
package inboundhandler;

import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.socket.SocketChannel;

public class MyClientChannelInitializer extends ChannelInitializer<SocketChannel> {
    @Override
    protected void initChannel(SocketChannel socketChannel) throws Exception {
        ChannelPipeline pipeline = socketChannel.pipeline();
        // 出栈时从pipeline尾部开始执行
        pipeline.addLast(new MyByteToLongDecoder());
        pipeline.addLast(new MyLongToByteEncoder());
        pipeline.addLast(new MyClientHandler());
    }
}
```

- MyClientHandler.java

```java
package inboundhandler;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;

public class MyClientHandler extends SimpleChannelInboundHandler<Long> {
    @Override
    protected void channelRead0(ChannelHandlerContext channelHandlerContext, Long aLong) throws Exception {
        System.out.println("收到服务器[" + channelHandlerContext.channel().remoteAddress() + "]消息：" + aLong);
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        System.out.println("MyClientHandler发送消息");
        ctx.writeAndFlush(1111L);
        // acceptOutboundMessage会判断msg是不是要处理的，不是就会跳过encode方法
//        ctx.writeAndFlush(Unpooled.copiedBuffer("abcdabcdabcdabcd", CharsetUtil.UTF_8));
    }
}
```

### 其他编解码器

- ReplayingDecoder：不需要判断byteBuf是否足够读取
- LineBasedFrameDecoder：使用行尾控制字符作为分隔符（\n或者\r\n)
- DelimiterBasedFrameDecoder：自定义分隔符
- HttpObjectDecoder：HTTP数据解码器
- LengthFieldBasedFrameDecoder：指定长度标识整包信息，避免粘包半包
- ......

## 粘包

### 协议包

- MessageProtocol.java

```java
package protocoltcp;

public class MessageProtocol {
    private int len ;

    public MessageProtocol() {
    }

    public MessageProtocol(int len, byte[] content) {
        this.len = len;
        this.content = content;
    }

    private byte[] content;

    public int getLen() {
        return len;
    }

    public void setLen(int len) {
        this.len = len;
    }

    public byte[] getContent() {
        return content;
    }

    public void setContent(byte[] content) {
        this.content = content;
    }
}
```

### 编解码器

- MyMessageDecoder.java

```java
package protocoltcp;

import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.ReplayingDecoder;

import java.util.List;

public class MyMessageDecoder extends ReplayingDecoder<MessageProtocol> {
    @Override
    protected void decode(ChannelHandlerContext ctx, ByteBuf in, List<Object> out) throws Exception {
        System.out.println("解码器被调用");
        int len = in.readInt();
        byte[] bytes = new byte[len];
        in.readBytes(bytes);
        // 封装后传给下个handler处理
        MessageProtocol messageProtocol = new MessageProtocol(len, bytes);
        out.add(messageProtocol);
    }
}
```

- MyMessageEncoder.java

```java
package protocoltcp;

import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.MessageToByteEncoder;

public class MyMessageEncoder extends MessageToByteEncoder<MessageProtocol> {

    @Override
    protected void encode(ChannelHandlerContext ctx, MessageProtocol msg, ByteBuf out) throws Exception {
        System.out.println("编码器被调用");
        out.writeInt(msg.getLen());
        out.writeBytes(msg.getContent());
    }
}
```

### 服务器

- NettyServer.java

```java
package protocoltcp;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.*;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;

public class NettyServer {
    public static void main(String[] args) throws Exception {
        EventLoopGroup bossGroup = new NioEventLoopGroup(1);
        EventLoopGroup workerGroup = new NioEventLoopGroup();
        try {
            ServerBootstrap bootstrap = new ServerBootstrap();
            bootstrap.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .option(ChannelOption.SO_BACKLOG, 128)
                    .childOption(ChannelOption.SO_KEEPALIVE, true)
                    .childHandler(new ChannelInitializer<SocketChannel>() {//workerGroup使用 SocketChannel创建一个通道初始化对象                                                                                           (匿名对象)
                        //给pipeline 设置处理器
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            ch.pipeline().addLast(new MyMessageDecoder());
                            ch.pipeline().addLast(new MyMessageEncoder());
                            ch.pipeline().addLast(new NettyServerHandler());
                        }
                    });

            System.out.println(".....服务器 is ready...");
            ChannelFuture channelFuture = bootstrap.bind(8888).sync();
            channelFuture.addListener(new ChannelFutureListener() {
                @Override
                public void operationComplete(ChannelFuture future) throws Exception {
                    if (channelFuture.isSuccess()) {
                        System.out.println("服务已启动,端口号为8888...");
                    } else {
                        System.out.println("服务启动失败...");
                    }
                }
            });
            channelFuture.channel().closeFuture().sync();
        } finally {
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }
}
```

- NettyServerHandler.java

```java
package protocoltcp;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

public class NettyServerHandler extends SimpleChannelInboundHandler<MessageProtocol> {
    private int count;

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, MessageProtocol msg) throws Exception {
        System.out.println("服务器收到：" + "长度=" + msg.getLen() + ", " + "内容=" + new String(msg.getContent(), StandardCharsets.UTF_8));
        System.out.println("服务器收到消息包数量：" + ++this.count);
        // 回复
        String string = UUID.randomUUID().toString();
        byte[] content = string.getBytes(StandardCharsets.UTF_8);
        int len = content.length;
        MessageProtocol messageProtocol = new MessageProtocol(len, content);
        ctx.writeAndFlush(messageProtocol);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        cause.printStackTrace();
        ctx.close();
    }
}
```

### 客户端

- NettyClient.java

```java
package protocoltcp;

import io.netty.bootstrap.Bootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;

import java.io.PrintWriter;

public class NettyClient {
    public static void main(String[] args) throws Exception {
        EventLoopGroup group = new NioEventLoopGroup();
        try {
            Bootstrap bootstrap = new Bootstrap();
            bootstrap.group(group)
                    .channel(NioSocketChannel.class)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            ChannelPipeline pipeline = ch.pipeline();
                            pipeline.addLast(new MyMessageEncoder());
                            pipeline.addLast(new MyMessageDecoder());
                            pipeline.addLast(new NettyClientHandler());
                        }
                    });
            System.out.println("客户端 ok..");
            ChannelFuture channelFuture = bootstrap.connect("127.0.0.1", 8888).sync();
            channelFuture.channel().closeFuture().sync();
        } finally {
            group.shutdownGracefully();
        }
    }
}
```

- NettyClientHandler.java

```java
package protocoltcp;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;

import java.nio.charset.StandardCharsets;

public class NettyClientHandler extends SimpleChannelInboundHandler<MessageProtocol> {
    private int count;

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        for (int i = 0; i < 1000; i++) {
            String s = "哈哈，呵呵。";
            byte[] bytes = s.getBytes(StandardCharsets.UTF_8);
            int len = bytes.length;
            MessageProtocol messageProtocol = new MessageProtocol(len, bytes);
            ctx.writeAndFlush(messageProtocol);
        }
    }

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, MessageProtocol msg) throws Exception {
        System.out.println("第" + ++count + "个数据包");
        System.out.println("客户端收到：长度=" + msg.getLen() + ", 内容=" + new String(msg.getContent(), StandardCharsets.UTF_8) + " ");
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        cause.printStackTrace();
        ctx.close();
    }
}
```

## RPC框架

### 公共接口

- HelloService.java

```java
package rpc.publicinterface;

public interface HelloService {
    String hello(String msg);
}
```

## 服务器

- 启动器ServerBootstrap.java

```java
package rpc.provider;

import rpc.netty.NettyServer;

public class ServerBootstrap {
    public static void main(String[] args) {
        NettyServer.startServer("127.0.0.1", 7777);
    }
}
```

- 接口实现类HelloServiceImpl.java

```java
package rpc.provider;

import rpc.publicinterface.HelloService;

public class HelloServiceImpl implements HelloService {
    // 每次都会生成新的对象
    @Override
    public String hello(String msg) {
        System.out.println("收到客户端消息：" + msg);
        if (msg != null) {
            return "服务器返回：收到了" + msg;
        }
        return "服务器返回：没收到";
    }
}
```

- NettyServer.java

```java
package rpc.netty;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;

public class NettyServer {
    public static void startServer(String host, int port) {
        NioEventLoopGroup bossGroup = new NioEventLoopGroup(1);
        NioEventLoopGroup workerGroup = new NioEventLoopGroup();
        try {
            ServerBootstrap serverBootstrap = new ServerBootstrap()
                    .group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            ChannelPipeline pipeline = ch.pipeline();
                            pipeline.addLast(new StringDecoder());
                            pipeline.addLast(new StringEncoder());
                            pipeline.addLast(new NettyServerHandler());
                        }
                    });

            ChannelFuture channelFuture = serverBootstrap.bind(host, port).sync();
            System.out.println("服务器启动");
            channelFuture.channel().closeFuture().sync();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }
}
```

- NettyServerHandler.java

```java
package rpc.netty;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import rpc.provider.HelloServiceImpl;

public class NettyServerHandler extends ChannelInboundHandlerAdapter {

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        System.out.println("客户端:" + ctx.channel().remoteAddress() + "连接");
    }

    @Override
    public void channelInactive(ChannelHandlerContext ctx) throws Exception {
        System.out.println("客户端:" + ctx.channel().remoteAddress() + "断开连接");
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        // 获取客户端信息并调用服务
        System.out.println("msg=" + msg);
        // 符合协议才能调用服务
        if (msg.toString().startsWith("HelloService#hello#")) {
            String result = new HelloServiceImpl().hello(msg.toString().substring(msg.toString().lastIndexOf("#") + 1));
            ctx.writeAndFlush(result);
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        ctx.close();
    }
}
```

## 客户端

- 启动器ClientBootstrap.java

```java
package rpc.customer;

import rpc.netty.NettyClient;
import rpc.publicinterface.HelloService;

public class ClientBootstrap {
    public static final String providerName = "HelloService#hello#";

    public static void main(String[] args) {
        NettyClient nettyClient = new NettyClient();
        // 创建代理对象
        HelloService bean = (HelloService) nettyClient.getBean(HelloService.class, providerName);
        // 通过代理对象调用服务提供者的方法
        String res = bean.hello("哈哈");
        System.out.println("调用结果：" + res);
    }
}
```

- NettyClient.java

```java
package rpc.netty;

import io.netty.bootstrap.Bootstrap;
import io.netty.channel.*;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;

import java.lang.reflect.Proxy;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class NettyClient {
    private static final ExecutorService executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
    private static NettyClientHandler clientHandler;

    // 获取一个代理对象
    public Object getBean(final Class<?> serviceClass, final String providerName) {
        return Proxy.newProxyInstance(Thread.currentThread().getContextClassLoader(),
                new Class<?>[]{serviceClass}, (proxy, method, args) -> {
                    // 客户端每次调用hello都会执行
                    if (clientHandler == null) {
                        startClient();
                    }
                    // 协议头 + 参数
                    clientHandler.setPara(providerName + args[0]);
                    return executor.submit(clientHandler).get();
                });
    }

    private static void startClient() {
        clientHandler = new NettyClientHandler();
        NioEventLoopGroup eventExecutors = new NioEventLoopGroup();
        Bootstrap bootstrap = new Bootstrap()
                .group(eventExecutors)
                .channel(NioSocketChannel.class)
                .option(ChannelOption.TCP_NODELAY, true)
                .handler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel ch) throws Exception {
                        ChannelPipeline pipeline = ch.pipeline();
                        pipeline.addLast(new StringDecoder());
                        pipeline.addLast(new StringEncoder());
                        pipeline.addLast(clientHandler);
                    }
                });
        try {
            ChannelFuture channelFuture = bootstrap.connect("127.0.0.1", 7777).sync();
            channelFuture.addListener(new ChannelFutureListener() {
                @Override
                public void operationComplete(ChannelFuture future) throws Exception {
                    if (channelFuture.isSuccess()) {
                        System.out.println("连接成功");
                    } else {
                        System.out.println("连接失败");
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

- NettyClientHandler.java

```java
package rpc.netty;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;

import java.util.concurrent.Callable;

public class NettyClientHandler extends ChannelInboundHandlerAdapter implements Callable {

    private ChannelHandlerContext context;
    private String result;  // 返回的结果
    private String para;    // 客户端调用时传入的参数

    // 1
    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        // 其他方法会用到ctx
        context = ctx;
    }

    // 4
    @Override
    public synchronized void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        result = msg.toString();
        // 唤醒等待的线程
        notify();
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        ctx.close();
    }

    // 3
    // 5
    // 被代理对象调用，发送数据给服务器，然后等待被唤醒
    @Override
    public synchronized Object call() throws Exception {
        context.writeAndFlush(para);
        // 等待
        wait();
        return result;
    }

    public String getPara() {
        return para;
    }

    // 2
    public void setPara(String para) {
        this.para = para;
    }
}
```
