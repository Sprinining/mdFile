---
title: NIO聊天室
date: 2024-08-17 02:32:48 +0800
categories: [java, network programming]
tags: [Java, Network Programming, NIO]
description: 
---
## SocketChannel 和 ServerSocketChannel

ServerSocketChannel 用于创建服务器端套接字，而 SocketChannel 用于创建客户端套接字。它们都支持阻塞和非阻塞模式，通过设置其 blocking 属性来切换。阻塞模式下，读/写操作会一直阻塞直到完成，而非阻塞模式下，读/写操作会立即返回。

阻塞模式：

- 优点：编程简单，适合低并发场景。
- 缺点：性能较差，不适合高并发场景。

```java
class BlockingServer {
    public static void main(String[] args) throws IOException {
        // 创建服务器套接字
        ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();
        // 绑定端口
        serverSocketChannel.socket().bind(new InetSocketAddress(8080));
        // 设置为阻塞模式（默认为阻塞模式）
        serverSocketChannel.configureBlocking(true);

        while (true) {
            // 接收客户端连接
            SocketChannel socketChannel = serverSocketChannel.accept();
            // 分配缓冲区
            ByteBuffer buffer = ByteBuffer.allocate(1024);

            // 读取数据
            int bytesRead = socketChannel.read(buffer);
            while (bytesRead != -1) {
                buffer.flip();
                System.out.println(StandardCharsets.UTF_8.decode(buffer));
                buffer.clear();
                bytesRead = socketChannel.read(buffer);
            }
            // 关闭套接字
            socketChannel.close();
        }
    }
}

class BlockingClient {
    public static void main(String[] args) throws IOException {
        // 创建客户端套接字
        SocketChannel socketChannel = SocketChannel.open();
        // 连接服务器
        socketChannel.connect(new InetSocketAddress("localhost", 8080));
        // 分配缓冲区
        ByteBuffer buffer = ByteBuffer.allocate(1024);

        // 向服务器发送数据
        buffer.put("这是来自客户端的消息。".getBytes(StandardCharsets.UTF_8));
        buffer.flip();
        socketChannel.write(buffer);
        // 清空缓冲区
        buffer.clear();

        // 关闭套接字
        socketChannel.close();
    }
}
```

非阻塞模式：

- 优点：性能更好，适合高并发场景。
- 缺点：编程相对复杂。

```java
class NonBlockingServer {
    public static void main(String[] args) throws IOException {
        // 创建服务器套接字
        ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();
        // 绑定端口
        serverSocketChannel.socket().bind(new InetSocketAddress(8080));
        // 设置为非阻塞模式
        serverSocketChannel.configureBlocking(false);

        // 创建选择器用于处理多个通道的事件
        Selector selector = Selector.open();
        // 注册服务器套接字到选择器
        serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);

        while (true) {
            // 调用 selector.select() 方法来等待感兴趣的事件发生。这个方法会阻塞，直到至少有一个感兴趣的事件发生。
            selector.select();
            // 当 selector.select() 返回时，我们可以通过 selector.selectedKeys() 获取所有已就绪的事件，并对其进行迭代处理。
            // 在处理事件时，根据 SelectionKey 的类型来执行相应的操作。
            Set<SelectionKey> selectedKeys = selector.selectedKeys();
            Iterator<SelectionKey> iterator = selectedKeys.iterator();

            while (iterator.hasNext()) {
                SelectionKey key = iterator.next();
                iterator.remove();

                // 当 SelectionKey 的类型为 OP_ACCEPT 时，说明有新的客户端连接请求
                if (key.isAcceptable()) {
                    // 接收客户端连接
                    SocketChannel socketChannel = serverSocketChannel.accept();
                    socketChannel.configureBlocking(false);
                    // 将该 SocketChannel 注册到 Selector 上，并设置感兴趣的事件为 OP_READ。
                    socketChannel.register(selector, SelectionKey.OP_READ);
                }

                // 当 SelectionKey 的类型为 OP_READ 时，说明有客户端发送了数据。我们需要从 SocketChannel 中读取数据，并进行相应的处理。
                if (key.isReadable()) {
                    // 读取数据
                    SocketChannel socketChannel = (SocketChannel) key.channel();
                    ByteBuffer buffer = ByteBuffer.allocate(1024);
                    int bytesRead = socketChannel.read(buffer);

                    if (bytesRead != -1) {
                        buffer.flip();
                        System.out.print(StandardCharsets.UTF_8.decode(buffer));
                        buffer.clear();
                    } else {
                        // 客户端已断开连接，取消选择键并关闭通道
                        key.cancel();
                        socketChannel.close();
                    }
                }

                // 当 SelectionKey 的类型为 OP_WRITE 时，说明可以向客户端发送数据。我们可以将要发送的数据写入 SocketChannel。
            }
        }
    }
}

class NonBlockingClient {
    public static void main(String[] args) throws IOException {
        // 创建客户端套接字
        SocketChannel socketChannel = SocketChannel.open();
        // 设置为非阻塞模式
        socketChannel.configureBlocking(false);
        // 连接服务器
        socketChannel.connect(new InetSocketAddress("localhost", 8080));

        while (!socketChannel.finishConnect()) {
            // 等待连接完成
        }

        // 分配缓冲区
        ByteBuffer buffer = ByteBuffer.allocate(1024);

        // 向服务器发送数据
        String message = "这是来自客户端的消息。";
        buffer.put(message.getBytes(StandardCharsets.UTF_8));
        buffer.flip();
        socketChannel.write(buffer);
        // 清空缓冲区
        buffer.clear();

        // 关闭套接字
        socketChannel.close();
    }
}
```

## Scatter 和 Gather

Scatter 和 Gather 是 Java NIO 中两种高效的 I/O 操作，用于将数据分散到多个缓冲区或从多个缓冲区中收集数据。

Scatter（分散）：它将从 Channel 读取的数据分散（写入）到多个缓冲区。这种操作可以在读取数据时将其分散到不同的缓冲区，有助于处理结构化数据。例如，我们可以将消息头、消息体和消息尾分别写入不同的缓冲区。

Gather（聚集）：与 Scatter 相反，它将多个缓冲区中的数据聚集（读取）并写入到一个 Channel。这种操作允许我们在发送数据时从多个缓冲区中聚集数据。例如，我们可以将消息头、消息体和消息尾从不同的缓冲区中聚集到一起并写入到同一个 Channel。

Sever：

```java
// 创建一个ServerSocketChannel
ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();
serverSocketChannel.socket().bind(new InetSocketAddress(9000));

// 接受连接
SocketChannel socketChannel = serverSocketChannel.accept();

// Scatter：分散读取数据到多个缓冲区
ByteBuffer headerBuffer = ByteBuffer.allocate(128);
ByteBuffer bodyBuffer = ByteBuffer.allocate(1024);

ByteBuffer[] buffers = {headerBuffer, bodyBuffer};

long bytesRead = socketChannel.read(buffers);

// 输出缓冲区数据
headerBuffer.flip();
while (headerBuffer.hasRemaining()) {
    System.out.print((char) headerBuffer.get());
}

System.out.println();

bodyBuffer.flip();
while (bodyBuffer.hasRemaining()) {
    System.out.print((char) bodyBuffer.get());
}

// Gather：聚集数据从多个缓冲区写入到Channel
ByteBuffer headerResponse = ByteBuffer.wrap("Header Response".getBytes());
ByteBuffer bodyResponse = ByteBuffer.wrap("Body Response".getBytes());

ByteBuffer[] responseBuffers = {headerResponse, bodyResponse};

long bytesWritten = socketChannel.write(responseBuffers);

// 关闭连接
socketChannel.close();
serverSocketChannel.close();
```

Client:

```java
// 创建一个SocketChannel
SocketChannel socketChannel = SocketChannel.open();
socketChannel.connect(new InetSocketAddress("localhost", 9000));

// 发送数据到服务器
String header = "Header Content";
String body = "Body Content";

ByteBuffer headerBuffer = ByteBuffer.wrap(header.getBytes());
ByteBuffer bodyBuffer = ByteBuffer.wrap(body.getBytes());

ByteBuffer[] buffers = {headerBuffer, bodyBuffer};
socketChannel.write(buffers);

// 从服务器接收数据
ByteBuffer headerResponseBuffer = ByteBuffer.allocate(128);
ByteBuffer bodyResponseBuffer = ByteBuffer.allocate(1024);

ByteBuffer[] responseBuffers = {headerResponseBuffer, bodyResponseBuffer};

long bytesRead = socketChannel.read(responseBuffers);

// 输出接收到的数据
headerResponseBuffer.flip();
while (headerResponseBuffer.hasRemaining()) {
    System.out.print((char) headerResponseBuffer.get());
}

bodyResponseBuffer.flip();
while (bodyResponseBuffer.hasRemaining()) {
    System.out.print((char) bodyResponseBuffer.get());
}

// 关闭连接
socketChannel.close();
```

## 异步套接字通道

AsynchronousSocketChannel 和 AsynchronousServerSocketChannel 是 Java 7 引入的异步 I/O 类，分别用于处理异步客户端 Socket 和服务器端 ServerSocket。异步 I/O 允许在 I/O 操作进行时执行其他任务，并在操作完成时接收通知，提高了并发处理能力。

```java
class AsynchronousServer {

    public static void main(String[] args) throws IOException, InterruptedException {
        // 创建了一个 AsynchronousServerSocketChannel 实例并将其打开。这个通道将用于监听客户端连接。
        AsynchronousServerSocketChannel server = AsynchronousServerSocketChannel.open();
        server.bind(new InetSocketAddress("localhost", 5000));

        System.out.println("服务器端启动");

        // 这个方法需要一个 CompletionHandler 实例，当客户端连接成功时，completed() 方法会被调用。
        server.accept(null, new CompletionHandler<AsynchronousSocketChannel, Void>() {
            // 每当收到一个新的连接时，会调用 completed() 方法，然后读取客户端发送的数据并将其打印到控制台
            @Override
            public void completed(AsynchronousSocketChannel client, Void attachment) {
                // 接收下一个连接请求
                server.accept(null, this);

                ByteBuffer buffer = ByteBuffer.allocate(1024);
                Future<Integer> readResult = client.read(buffer);

                try {
                    readResult.get();
                    buffer.flip();
                    String message = new String(buffer.array(), 0, buffer.remaining());
                    System.out.println("接收到的消息: " + message);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void failed(Throwable exc, Void attachment) {
                exc.printStackTrace();
            }
        });

        // 为了让服务器继续运行，我们需要阻止 main 线程退出
        Thread.currentThread().join();
    }
}

class AsynchronousClient {

    public static void main(String[] args) {
        try {
            AsynchronousSocketChannel client = AsynchronousSocketChannel.open();
            Future<Void> connectResult = client.connect(new InetSocketAddress("localhost", 5000));
            connectResult.get(); // 等待连接完成

            String message = "在吗？";
            ByteBuffer buffer = ByteBuffer.wrap(message.getBytes(StandardCharsets.UTF_8));
            Future<Integer> writeResult = client.write(buffer);
            writeResult.get(); // 等待发送完成

            System.out.println("消息发送完毕");

            client.close();
        } catch (IOException | InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
    }
}
```

## 简单聊天室

服务端启动监听客户端请求，当客户端向服务器端发送信息后，服务器端接收到后把客户端消息回显给客户端：

```java
class ChatServer {
    private Selector selector;
    private ServerSocketChannel serverSocketChannel;
    private static final int PORT = 8080;

    public ChatServer() {
        try {
            selector = Selector.open();
            serverSocketChannel = ServerSocketChannel.open();
            serverSocketChannel.socket().bind(new InetSocketAddress(PORT));
            serverSocketChannel.configureBlocking(false);
            serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);
            System.out.println("聊天室服务端启动了 " + PORT);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void start() {
        try {
            while (true) {
                if (selector.select() > 0) {
                    Iterator<SelectionKey> iterator = selector.selectedKeys().iterator();
                    while (iterator.hasNext()) {
                        SelectionKey key = iterator.next();
                        iterator.remove();
                        handleKey(key);
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void handleKey(SelectionKey key) throws IOException {
        if (key.isAcceptable()) {
            SocketChannel socketChannel = serverSocketChannel.accept();
            socketChannel.configureBlocking(false);
            socketChannel.register(selector, SelectionKey.OP_READ);
            System.out.println("客户端连接上了: " + socketChannel.getRemoteAddress());
        } else if (key.isReadable()) {
            SocketChannel socketChannel = (SocketChannel) key.channel();
            ByteBuffer buffer = ByteBuffer.allocate(1024);
            int read = socketChannel.read(buffer);
            if (read > 0) {
                buffer.flip();
                String msg = new String(buffer.array(), 0, read);
                System.out.println("客户端说: " + msg);
                socketChannel.write(ByteBuffer.wrap(("服务端回复: " + msg).getBytes()));
            }
        }
    }

    public static void main(String[] args) {
        new ChatServer().start();
    }
}

class ChatClient {
    private Selector selector;
    private SocketChannel socketChannel;
    private static final String HOST = "localhost";
    private static final int PORT = 8080;

    public ChatClient() {
        try {
            selector = Selector.open();
            socketChannel = SocketChannel.open(new InetSocketAddress(HOST, PORT));
            socketChannel.configureBlocking(false);
            socketChannel.register(selector, SelectionKey.OP_READ);
            System.out.println("连接到聊天室了");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void start() {
        new Thread(() -> {
            try {
                while (true) {
                    if (selector.select() > 0) {
                        for (SelectionKey key : selector.selectedKeys()) {
                            selector.selectedKeys().remove(key);
                            if (key.isReadable()) {
                                readMessage();
                            }
                        }
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }).start();

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(System.in
        ))) {
            String input;
            while ((input = reader.readLine()) != null) {
                sendMessage(input);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    private void sendMessage(String message) throws IOException {
        if (message != null && !message.trim().isEmpty()) {
            ByteBuffer buffer = ByteBuffer.wrap(message.getBytes());
            socketChannel.write(buffer);
        }
    }

    private void readMessage() throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        int read = socketChannel.read(buffer);
        if (read > 0) {
            buffer.flip();
            String msg = new String(buffer.array(), 0, read);
            System.out.println(msg);
        }
    }

    public static void main(String[] args) {
        new ChatClient().start();
    }
}
```

要求服务器端也能从控制台敲入信息主动发送给客户端：

```java
class Chat2Server {

    public static void main(String[] args) throws IOException {
        // 创建一个 ServerSocketChannel
        ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();
        serverSocketChannel.configureBlocking(false);
        serverSocketChannel.bind(new InetSocketAddress(8080));

        // 创建一个 Selector
        Selector selector = Selector.open();
        serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);
        System.out.println("聊天室服务端启动了");

        // 客户端连接
        AtomicReference<SocketChannel> clientRef = new AtomicReference<>();

        // 从控制台读取输入并发送给客户端
        Thread sendMessageThread = new Thread(() -> {
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(System.in))) {
                while (true) {
                    System.out.println("输入服务器端消息: ");
                    String message = reader.readLine();
                    SocketChannel client = clientRef.get();
                    if (client != null && client.isConnected()) {
                        ByteBuffer buffer = ByteBuffer.wrap((message + "\n").getBytes());
                        client.write(buffer);
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
        sendMessageThread.start();

        while (true) {
            int readyChannels = selector.select();

            if (readyChannels == 0) {
                continue;
            }

            Set<SelectionKey> selectedKeys = selector.selectedKeys();
            Iterator<SelectionKey> keyIterator = selectedKeys.iterator();

            while (keyIterator.hasNext()) {
                SelectionKey key = keyIterator.next();

                if (key.isAcceptable()) {
                    // 接受客户端连接
                    SocketChannel client = serverSocketChannel.accept();
                    System.out.println("客户端已连接");
                    client.configureBlocking(false);
                    client.register(selector, SelectionKey.OP_READ);
                    clientRef.set(client);
                } else if (key.isReadable()) {
                    // 读取客户端消息
                    SocketChannel channel = (SocketChannel) key.channel();
                    ByteBuffer buffer = ByteBuffer.allocate(1024);
                    int bytesRead = channel.read(buffer);

                    if (bytesRead > 0) {
                        buffer.flip();
                        byte[] bytes = new byte[buffer.remaining()];
                        buffer.get(bytes);
                        String message = new String(bytes).trim();
                        System.out.println("客户端消息: " + message);
                    }
                }
                keyIterator.remove();
            }
        }
    }
}

class Chat2Client {

    public static void main(String[] args) throws IOException {
        // 创建一个 SocketChannel
        SocketChannel socketChannel = SocketChannel.open();
        socketChannel.configureBlocking(false);
        socketChannel.connect(new InetSocketAddress("localhost", 8080));

        // 创建一个 Selector
        Selector selector = Selector.open();
        socketChannel.register(selector, SelectionKey.OP_CONNECT);

        // 从控制台读取输入并发送给服务器端
        Thread sendMessageThread = new Thread(() -> {
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(System.in))) {
                while (true) {
                    System.out.println("输入客户端消息: ");
                    String message = reader.readLine();
                    if (socketChannel.isConnected()) {
                        ByteBuffer buffer = ByteBuffer.wrap((message + "\n").getBytes());
                        socketChannel.write(buffer);
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
        sendMessageThread.start();

        while (true) {
            int readyChannels = selector.select();

            if (readyChannels == 0) {
                continue;
            }

            Set<SelectionKey> selectedKeys = selector.selectedKeys();
            Iterator<SelectionKey> keyIterator = selectedKeys.iterator();

            while (keyIterator.hasNext()) {
                SelectionKey key = keyIterator.next();

                if (key.isConnectable()) {
                    // 连接到服务器
                    socketChannel.finishConnect();
                    socketChannel.register(selector, SelectionKey.OP_READ);
                    System.out.println("已连接到服务器");
                } else if (key.isReadable()) {
                    // 读取服务器端消息
                    ByteBuffer buffer = ByteBuffer.allocate(1024);
                    int bytesRead = socketChannel.read(buffer);

                    if (bytesRead > 0) {
                        buffer.flip();
                        byte[] bytes = new byte[buffer.remaining()];
                        buffer.get(bytes);
                        String message = new String(bytes).trim();
                        System.out.println("服务器端消息: " + message);
                    }
                }
                keyIterator.remove();
            }
        }
    }
}
```
