---
title: 基于BIO的Socket通信
date: 2022-03-21 03:35:24 +0800
categories: [java, network programming]
tags: [Java, Network Programming, BIO]
description: 
---
# 基于BIO的Socket通信

## 告知对方命令发送完毕

- 关闭socket：socket.close()
- 关闭流：socket.shutdownOutput()，ocket.shutdownInput()
- 约定终结符
- 指定数据长度

## 单工通信

- 通过约定终结符的方式关闭连接
- 通过关闭流的方式告诉对方发送完毕

- Server.java

```java
package demo0;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

public class Server {
    public static void main(String[] args) {
        ServerSocket serverSocket = null;
        Socket socket = null;
        InputStream is = null;
        InputStreamReader inputStreamReader = null;
        BufferedReader bufferedReader = null; // 读取客户端

        try {
            // 初始化服务端socket并且绑定9999端口
            serverSocket = new ServerSocket(8888);
            // 等待客户端的连接
            socket = serverSocket.accept();

            // 获取输入流,并且指定统一的编码格式
            is = socket.getInputStream();
            inputStreamReader = new InputStreamReader(is, StandardCharsets.UTF_8);
            bufferedReader = new BufferedReader(inputStreamReader);

            // 读取一行数据
            String str;
            // 通过while循环不断读取信息，读到终结符会去掉终结符并获取这一行内容而不是继续阻塞
            while ((str = bufferedReader.readLine()) != null) {
                // 终止连接，并且此次不返回信息
                if (str.equals("**")) break;

                //输出打印
                System.out.println(str);
            }
            // 关闭输入流
            socket.shutdownInput();

        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            System.out.println("服务器释放资源...");
            if (serverSocket != null) {
                try {
                    serverSocket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (socket != null) {
                try {
                    socket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (is != null) {
                try {
                    is.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (inputStreamReader != null) {
                try {
                    inputStreamReader.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (bufferedReader != null) {
                try {
                    bufferedReader.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
```

- Client.java

```java
package demo0;

import java.io.*;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

public class Client {
    public static void main(String[] args) {
        Socket socket = null;
        OutputStream os = null;
        OutputStreamWriter outputStreamWriter = null;
        BufferedWriter bufferedWriter = null; // 写给服务器
        BufferedReader bufferedReader = null; // 读取控制台输入
        InputStreamReader inputStreamReader = null;

        try {
            // 初始化一个socket
            socket = new Socket("127.0.0.1", 8888);

            // 通过socket获取字符流，先服务器发送信息
            os = socket.getOutputStream();
            outputStreamWriter = new OutputStreamWriter(os, StandardCharsets.UTF_8);
            bufferedWriter = new BufferedWriter(outputStreamWriter);

            // 读取控制台输入
            inputStreamReader = new InputStreamReader(System.in, StandardCharsets.UTF_8);
            bufferedReader = new BufferedReader(inputStreamReader);

            while (true) {
                // 读到终结符\r或者\n会去掉终结符并且返回一行内容
                String str = bufferedReader.readLine();
                bufferedWriter.write(str);
                // 让服务器的readLine能够接收一行，如果发过去的没有终结符，服务器的readLine会一直阻塞
                bufferedWriter.write("\n");
//                bufferedWriter.write("\r666\n"); // 这种情况，相当于两行，服务器第二次读到的就是666\n
                // 清空缓存立刻发出
                bufferedWriter.flush();

                // 终止连接
                if (str.equals("**")) break;
            }
            // 关闭输出流
            socket.shutdownOutput();

        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            System.out.println("客户端释放资源...");
            if (socket != null) {
                try {
                    socket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (outputStreamWriter != null) {
                try {
                    outputStreamWriter.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (os != null) {
                try {
                    os.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (inputStreamReader != null) {
                try {
                    inputStreamReader.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (bufferedReader != null) {
                try {
                    bufferedReader.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (bufferedWriter != null) {
                try {
                    bufferedWriter.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
```

## 客户端单次收发

- MyServer.java

```java
package demo1;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;

public class MyServer {

    public static void main(String[] args) {
        ServerSocket serverSocket = null; // 新建ServerSocket对象
        Socket socket = null; // 接收客户端连接
        InputStream is = null; // 用于读取客户端消息
        OutputStream os = null;
        ByteArrayOutputStream baos = null;

        try {
            // 1.创建指定端口的连接
            serverSocket = new ServerSocket(8888);

            while (true) {
                // 2.监听 没有连接就阻塞在此
                socket = serverSocket.accept();

                // 3.从socket取出来自客户端的数据
                is = socket.getInputStream();

                // 解析数据
                // 方法一 读到缓冲数组里
                baos = new ByteArrayOutputStream();
                byte[] buff = new byte[1024];
                int len;
                while ((len = is.read(buff)) != -1) {
                    baos.write(buff, 0, len);
                }
                System.out.println("服务器：" + baos);
                // 关闭输入流
                socket.shutdownInput();

                // 方法二
/*                InputStreamReader reader = new InputStreamReader(is);
                BufferedReader bufReader = new BufferedReader(reader);
                String s;
                StringBuffer sb = new StringBuffer();
                while ((s = bufReader.readLine()) != null) {
                    sb.append(s);
                }
                System.out.println("服务器：" + sb);
                // 关闭输入流
                socket.shutdownInput();*/
                
                            // 2.2接受图片
/*
            FileOutputStream fos = new FileOutputStream(new File("receive.jpg"));
            byte[] buffer = new byte[1024];
            int len;
            while ((len = is.read(buffer)) != -1) {
                fos.write(buffer, 0, len);
            }
            socket.shutdownInput();
*/

                // 4.向socket写入数据，发送给客户端
                os = socket.getOutputStream();
                os.write(("服务端返回给客户端的信息").getBytes());
                // 强制将缓冲区中的数据发送出去，不必等到缓冲区满
                os.flush();
                // 关闭输出流，会自动关闭socket
                socket.shutdownOutput();
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            /**
             * 在使用TCP编程的时候，最后需要释放资源，关闭socket(socket.close())；
             * 关闭socket输入输出流（socket.shutdownInput()以及socket.shutdownOutput()）；关闭IO流(is.close() os.close())。
             * 需要注意的是：关闭socket的输入输出流需要放在关闭io流之前。
             * 因为关闭IO流会同时关闭socket，一旦关闭了socket的，就不能再进行socket的相关操作了。
             * 而只关闭socket输入输出流（socket.shutdownInput()以及socket.shutdownOutput()）不会完全关闭socket，此时任然可以进行socket方面的操作。
             * 所以要先调用socket.shutdownXXX，然后再调用io.close();
             */
            if (baos != null) {
                try {
                    baos.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (is != null) {
                try {
                    is.close(); // 关闭IO流会同时关闭socket
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (os != null) {
                try {
                    socket.shutdownOutput();
                    os.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (socket != null) {
                try {
                    // 关闭socket
                    socket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (serverSocket != null) {
                try {
                    // 关闭serverSocket
                    serverSocket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}

```

- MyClient2.java

```java
package demo1;

import java.io.*;
import java.net.Socket;

public class MyClient2 {

    public static void main(String[] args) {
        Socket socket = null;
        OutputStream os = null;

        try {
            // 1.创建socket连接
            socket = new Socket("127.0.0.1", 8888);

            // 2.向socket写入数据，发送给服务端
            // 2.1发送文字
            os = socket.getOutputStream();
            os.write(("主机客户端" + Thread.currentThread() + "--->服务器ing...").getBytes());
            os.flush();
            // 关闭输出流
            socket.shutdownOutput();

            // 2.2发送图片
/*            os = socket.getOutputStream();
            // 读取文件
            FileInputStream fis = new FileInputStream(new File("haha.jpg"));
            // 写出文件到输出流中
            byte[] buffer = new byte[1024];
            int len;
            while ((len=fis.read(buffer))!=-1){
                os.write(buffer,0,len);
            }
            os.flush();
            socket.shutdownOutput();*/

            // 3.从socket取出来自服务端的数据
            InputStream is = socket.getInputStream();
            // 解析服务器返回的数据
            InputStreamReader reader = new InputStreamReader(is);
            BufferedReader bufReader = new BufferedReader(reader);
            String s;
            final StringBuffer sb = new StringBuffer();
            while ((s = bufReader.readLine()) != null) {
                sb.append(s);
            }
            System.out.println("主机客户端接收到：" + sb);
            // 关闭输入流
            socket.shutdownInput();

        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            // 4.释放所有资源
            if (os != null) {
                try {
                    os.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (socket != null) {
                try {
                    socket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}

```

## 约定数据长度

- 指定前两个字节表示数据长度
- 或者第一个字节表示后面几个字节是用来表示数据长度，实现==变长方式表示长度==

- SocketServer.java

```java
package demo4;

import java.io.InputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

public class SocketServer {
    public static void main(String[] args) throws Exception {
        // 监听指定的端口
        int port = 8888;
        ServerSocket server = new ServerSocket(port);

        // server将一直等待连接的到来
        System.out.println("监听ing...");
        Socket socket = server.accept();

        // 建立好连接后，从socket中获取输入流，并建立缓冲区进行读取
        InputStream inputStream = socket.getInputStream();

        byte[] bytes;
        // 因为可以复用Socket且能判断长度，所以可以一个Socket用到底
        while (true) {
            // 首先读取两个字节表示的长度
            // int四字节
            int first = inputStream.read();
            System.out.println("first:" + first);
            // 如果读取的值为-1 说明到了流的末尾，Socket已经被关闭了，此时将不能再去读取
            if (first == -1) {
                break;
            }

            int second = inputStream.read();
            System.out.println("second:" + second);
            int length = (first << 8) + second;
            System.out.println("(first << 8) + second：" + length);
            // 然后构造一个指定长的byte数组
            bytes = new byte[length];

            // 然后读取指定长度的消息即可
            inputStream.read(bytes);
            System.out.println("get message from client: " + new String(bytes, StandardCharsets.UTF_8));
        }
        inputStream.close();
        socket.close();
        server.close();
    }
}
```

- SocketClient.java

```java
package demo4;

import java.io.OutputStream;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

public class SocketClient {
    public static void main(String[] args) throws Exception {
        // 与服务端建立连接
        Socket socket = new Socket("127.0.0.1", 8888);

        // 建立连接后获得输出流
        OutputStream outputStream = socket.getOutputStream();

        // UTF-8编码：一个英文字符等于一个字节，一个中文（含繁体）等于三个字节。中文标点占三个字节，英文标点占一个字节。
        String message = "abcdefg";
        // 首先需要计算得知消息的长度
        byte[] sendBytes = message.getBytes(StandardCharsets.UTF_8);
        System.out.println("长度：" + sendBytes.length);
        socket.shutdownOutput();

        // 然后将消息的长度优先发送出去
        // 用，只取int的低16位
        // 先有符号右移8位，发送高八位表示的字节
        outputStream.write(sendBytes.length >> 8);
        // 在
        outputStream.write(sendBytes.length);

        // 然后将消息再次发送出去
        outputStream.write(sendBytes);
        outputStream.flush();

        //==========此处重复发送一次，实际项目中为多个命名，此处只为展示用法
        message = "第二条消息";
        sendBytes = message.getBytes(StandardCharsets.UTF_8);
        outputStream.write(sendBytes.length >> 8);
        outputStream.write(sendBytes.length);
        outputStream.write(sendBytes);
        outputStream.flush();


        outputStream.close();
        socket.close();
    }
}
```

## 全双工通信

- 客户端服务器都是通过控制台发送信息
- 每个socket连接都放在子线程中处理
- ==原文链接：==https://www.cnblogs.com/panther1942/p/8873766.html

- MyServer.java

```java
package demo5;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;
import java.util.Set;

public class MyServer {
    // 区分不同的服务线程，一个线程处理一个socket
    private static int id = 0;
    // 监听端口
    private ServerSocket serverSocket;
    // 管理所有的服务线程
    private final HashMap<Integer, ServerThread> hashMap = new HashMap<>();

    // 传入监听的端口
    public MyServer(int port) {
        try {
            serverSocket = new ServerSocket(port);
            System.out.println("服务器已启动");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 启动服务器
    public void start() {

        // 启动服务器，先让Writer对象启动等待键盘输入
        new Writer().start();

        // 不停的监听端口
        try {
            while (true) {
                // 等待客户端接入
                Socket socket = serverSocket.accept();
                System.out.println("客户端" + ++id + "连接成功： intentAddress=" + socket.getInetAddress() + " port=" + socket.getPort());
                // 放到线程里执行
                ServerThread serverThread = new ServerThread(id, socket);
                serverThread.start();
                // 放入hashmap管理线程
                hashMap.put(id, serverThread);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 关闭服务器的资源
    public void close() {
        // 发送广播，告诉所有客户端关闭连接
        sendAll("exit");

        try {
            if (serverSocket != null) {
                serverSocket.close();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 单播
    private void send(int id, String data) {
        // 找到对应的服务线程
        ServerThread thread = hashMap.get(id);
        // 发送信息
        thread.send(data);
        // 让连接关闭
        if ("exit".equals(data)) {
            thread.close();
        }
    }

    // 广播

    /**
     * 遍历存放连接的Map，把他们的id全部取出来，注意这里不能直接遍历Map，不然可能报错
     * 报错的情况是，当试图发送 `*:exit` 时，这段代码会遍历Map中所有的连接对象，关闭并从Map中移除
     * java的集合类在遍历的过程中进行修改会抛出异常
     */
    public void sendAll(String data) {
        LinkedList<Integer> list = new LinkedList<>();
        Set<Map.Entry<Integer, ServerThread>> set = hashMap.entrySet();
        for (Map.Entry<Integer, ServerThread> entry : set) {
            list.add(entry.getKey());
        }
        for (Integer id : list) {
            send(id, data);
        }
    }

    // 每次接收一个客户端就放到一个服务进程处理读写
    private class ServerThread extends Thread {
        private int id;
        private Socket socket;
        private InputStream inputStream;
        private OutputStream outputStream;
        private PrintWriter printWriter;

        public ServerThread(int id, Socket socket) {
            try {
                this.id = id;
                this.socket = socket;
                this.inputStream = socket.getInputStream();
                this.outputStream = socket.getOutputStream();
                printWriter = new PrintWriter(outputStream);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        // 向客户端发送信息
        // 同时只能有一个键盘输入，所以输入交给服务器管理而不是服务线程
        // 服务器负责选择socket连接和发送的消息内容，然后调用服务线程的write方法发送数据
        public void send(String data) {
            if (!socket.isClosed() && data != null && !"exit".equals(data)) {
                printWriter.println(data);
                printWriter.flush();
            }
        }

        // 读写不能阻塞，新开线程进行读操作
        @Override
        public void run() {
            new Reader().run();
        }

        public void close() {
            try {
                if (inputStream != null) {
                    inputStream.close();
                }
                if (outputStream != null) {
                    outputStream.close();
                }
                if (printWriter != null) {
                    printWriter.close();
                }
                if (socket != null) {
                    socket.close();
                }
                // 移除服务线程
                hashMap.remove(id);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        private class Reader extends Thread {
            // 获取这个客户端的输入
            private final InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
            private final BufferedReader bufferedReader = new BufferedReader(inputStreamReader);

            @Override
            public void run() {
                try {
                    String line = "";
                    while (!socket.isClosed() && line != null && !line.equals("exit")) {
                        line = bufferedReader.readLine();
                        if (line != null) {
                            System.out.println("客户端" + id + "：" + line);
                        }
                    }

                    System.out.println("客户端" + id + "主动断开连接");
                    close();
                } catch (IOException e) {
                    e.printStackTrace();
                    System.out.println(id + "连接已关闭");
                } finally {
                    try {
                        if (inputStreamReader != null) {
                            inputStreamReader.close();
                        }
                        if (bufferedReader != null) {
                            bufferedReader.close();
                        }
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }

    private class Writer extends Thread {
        // 从键盘获取要发送给客户端的消息
        private final BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(System.in));

        @Override
        public void run() {
            String line = "";
            // 不停的接收键盘发送的命令
            while (true) {
                // 服务器控制台输入exit退出服务器
                try {
                    line = bufferedReader.readLine();
                    // 变量放前面不用做空指针异常处理
                    if ("exit".equals(line))
                        break;
                } catch (IOException e) {
                    e.printStackTrace();
                }

                // 否则就解析命令
                if (line != null) {
                    try {
                        // [连接id]:[要发送的内容]
                        String[] data = line.split(":");
                        if ("*".equals(data[0])) {
                            // 广播
                            sendAll(data[1]);
                        } else {
                            // 单播
                            send(Integer.parseInt(data[0]), data[1]);
                        }
                        // 有可能发生的异常
                    } catch (NumberFormatException e) {
                        System.out.print("必须输入连接id号");
                    } catch (ArrayIndexOutOfBoundsException e) {
                        System.out.print("发送的消息不能为空");
                    } catch (NullPointerException e) {
                        System.out.print("连接不存在或已经断开");
                    }
                }
            }
            System.out.println("服务器关闭");
            close();
        }
    }

    public static void main(String[] args) {
        new MyServer(8888).start();
    }
}
```

- MyClient.java

```java
package demo5;

import java.io.*;
import java.net.Socket;

public class MyClient {
    private Socket socket;
    private InputStream inputStream;
    private OutputStream outputStream;

    public MyClient(String address, int port) {
        try {
            socket = new Socket(address, port);
            inputStream = socket.getInputStream();
            outputStream = socket.getOutputStream();
        } catch (IOException e) {
            e.printStackTrace();
        }
        System.out.println("客户端启动成功");
    }

    public void start(){
        new Reader().start();
        new Writer().start();
    }

    private class Reader extends Thread {
        private final InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
        private final BufferedReader bufferedReader = new BufferedReader(inputStreamReader);

        @Override
        public void run() {

            try {
                String line = "";
                while (!socket.isClosed() && line != null && !line.equals("exit")) {
                    line = bufferedReader.readLine();
                    System.out.println("服务器发来：" + line);
                }

                System.out.println("服务器关闭了连接");
                close();
            } catch (IOException e) {
                e.printStackTrace();
                System.out.println("连接已关闭");
            } finally {
                try {
                    if (inputStreamReader != null) {
                        inputStreamReader.close();
                    }
                    if (bufferedReader != null) {
                        bufferedReader.close();
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private class Writer extends Thread {
        // 发给服务器
        private final PrintWriter printWriter = new PrintWriter(outputStream);
        // 从键盘获取要发送给服务器的消息
        private final BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(System.in));

        @Override
        public void run() {
            try {
                String line = "";
                while (!socket.isClosed() && line != null && !"exit".equals(line)) {
                    line = bufferedReader.readLine();
                    if (!"".equals(line)) {
                        // 写出
                        printWriter.println(line);
                        printWriter.flush();
                    } else {
                        System.out.println("不能发送给服务器空的数据");
                    }
                }

                System.out.println("客户端关闭了连接");
                close();
            } catch (IOException e) {
                e.printStackTrace();
                System.out.println("连接已关闭");
            } finally {
                try {
                    if (printWriter != null) {
                        printWriter.close();
                    }
                    if (bufferedReader != null) {
                            bufferedReader.close();
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    // 关闭资源
    private void close() {
        try {
            if (inputStream != null) {
                inputStream.close();
            }
            if (outputStream != null) {
                outputStream.close();
            }
            if (socket != null) {
                socket.close();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        new MyClient("127.0.0.1", 8888).start();
    }
}
```

## 生产者消费者模式版

- 为每个socket连接创建一个服务线程
- 服务线程启动一个读线程和一个写线程
- 客户端先写后读，交替进行；服务端先读后写，交替进行
- 用Lock锁精准唤醒实现生产者消费者模型
- 加上了简单的头尾校验
- MyServer.java

```java
package demo9;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Objects;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class MyServer {
    // 区分不同的服务线程，一个线程处理一个socket
    private static int id = 0;
    // 监听端口
    private ServerSocket serverSocket;
    // 管理所有的服务线程
    private HashMap<Integer, ServerThread> hashMap = new HashMap<>();

    /**
     * 传入监听的端口
     *
     * @param port
     */
    public MyServer(int port) {
        try {
            serverSocket = new ServerSocket(port);
            System.out.println("服务器已启动");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 启动服务器
     */
    public void start() {
        // 不停的监听端口
        try {
            while (true) {
                // 等待客户端接入
                Socket socket = serverSocket.accept();
                System.out.println("客户端" + ++id + "连接成功： intentAddress=" + socket.getInetAddress() + " port=" + socket.getPort());
                // 放到线程里执行
                ServerThread serverThread = new ServerThread(id, socket);
                serverThread.start();
                // 放入hashmap管理线程
                hashMap.put(id, serverThread);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 关闭服务器的资源
     */
    public void closeMyServer() {
        // 关闭serverSocket
        try {
            if (serverSocket != null) {
                serverSocket.close();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 每次接收一个客户端就放到一个服务线程处理读写
     * 一个服务线程有一个写线程读线程
     */
    private class ServerThread extends Thread {
        private int id;
        private Socket socket;
        private InputStream inputStream;
        private OutputStream outputStream;
        private PrintWriter printWriter;
        public static final String CHECK_ERROR = "数据校验错误";
        // 待返回的处理结果
        private String message = "";
        // 1是轮到读线程读，2是轮到写线程写（读线程先执行）
        private int num = 1;
        // 锁
        private Lock lock = new ReentrantLock();
        // 更新返回的处理结果
        private Condition condition_reader = lock.newCondition();
        // 发送返回的处理结果
        private Condition condition_writer = lock.newCondition();
        // 是不是已经关闭socket
        private boolean flag = false;


        /**
         * 初始化serverThread的资源
         *
         * @param id
         * @param socket
         */
        public ServerThread(int id, Socket socket) {
            try {
                this.id = id;
                this.socket = socket;
                this.inputStream = socket.getInputStream();
                this.outputStream = socket.getOutputStream();
                printWriter = new PrintWriter(outputStream);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        /**
         * 开启读写线程
         */
        @Override
        public void run() {
            new Reader().start();
            new Writer().start();
        }

        /**
         * 释放serverThread的资源
         */
        public void closeServerThread() {
            try {
                if (inputStream != null) {
                    inputStream.close();
                }
                if (outputStream != null) {
                    outputStream.close();
                }
                if (printWriter != null) {
                    printWriter.close();
                }
                if (socket != null) {
                    socket.close();
                }
                // 移除服务线程
                hashMap.remove(id);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        /**
         * 去除头尾
         *
         * @param str
         * @return
         */
        public String removeHeadAndTail(String str) {
            // 检验头尾是否是0x55 0xAA
            int head = str.charAt(0);
            int tail = str.charAt(str.length() - 1);
            if (head != 85 || tail != 170) {
                // 数据接收不对的处理
                return CHECK_ERROR;
            } else {
                // 去掉头尾后的json字符串
                return str.substring(1, str.length() - 1);
            }
        }

        /**
         * 加上头尾
         *
         * @param str
         * @return
         */
        public String addHeadAndTail(String str) {
            return ((char) 85) + str + ((char) 170);
        }

        /**
         * 读线程
         */
        private class Reader extends Thread {
            // 获取这个客户端的输入
            private InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
            private BufferedReader bufferedReader = new BufferedReader(inputStreamReader);

            @Override
            public void run() {
                // 加锁
                lock.lock();

                /**
                 * 与写线程交替读写
                 */
                try {
                    String line = "";

                    while (!socket.isClosed() && line != null && !"exit".equals(line)) {

                        /**
                         * 如果没轮到自己读，就阻塞自己
                         */
                        while (num != 1) {
                            condition_reader.await();
                        }

                        /**
                         * 一次读
                         * 去除头尾才是json字符串
                         */
                        System.out.println("等着读呢");
                        // TODO: 2021/10/15 客户端直接断开，此处会抛异常 Connection reset
                        line = bufferedReader.readLine();

                        if (line != null) {
                            // 去头尾
                            String cmd = removeHeadAndTail(line);

                            if (Objects.equals(CHECK_ERROR, cmd)) {
                                // 校验错误
                                message = CHECK_ERROR;
                                System.out.println(CHECK_ERROR);
                            } else {
                                // 校验成功并去除了头尾
                                System.out.println("客户端" + id + "发来：" + cmd);
                                // 处理客户端发来的命令，并获得处理结果
                                message = new CallbackUtil().getMessage(cmd);
                                // 将处理结果返回给客户端
                                System.out.println("处理结果：" + message);
                            }
                        }

                        /**
                         * 读完一次并执行相应操作并设置完返回结果
                         * 就把执行权交给写线程
                         * 然后唤醒writer，让他把返回信息发给客户端
                         */
                        num = 2;
                        condition_writer.signalAll();
                    }

                    /**
                     * 特例：客户端的指令是exit
                     * 必须唤醒一下writer，不然会阻塞
                     */
                    flag = true;
                    condition_writer.signalAll();
                    System.out.println("客户端" + id + "主动断开连接");
                    closeServerThread();
                } catch (IOException | InterruptedException e) {
                    e.printStackTrace();
                    System.out.println(id + "连接已关闭");
                } finally {
                    // 解锁
                    lock.unlock();
                    // 释放Reader的资源
                    try {
                        if (inputStreamReader != null) {
                            inputStreamReader.close();
                        }
                        if (bufferedReader != null) {
                            bufferedReader.close();
                        }
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }

        /**
         * 写线程
         */
        private class Writer extends Thread {
            // 发给客户端
            private PrintWriter printWriter = new PrintWriter(outputStream);
            private InputStream is;
            private BufferedReader buf;

            @Override
            public void run() {
                // 加锁
                lock.lock();

                /**
                 * 与读线程交替读写
                 */
                try {
                    String str; // 接收输入内容
                    byte[] data;
                    OUT:
                    while (!socket.isClosed() && !"exit".equals(message)) {
                        /**
                         * 如果没轮到自己写，就阻塞自己
                         */
                        while (num != 2) {
                            condition_writer.await();
                            // 客户端已关闭连接，最后一次的处理结果不用返回
                            if (flag) {
                                break OUT;
                            }
                        }

                        /**
                         * 一次写
                         * 返回的是加上头尾的json字符串
                         */
                        String result = addHeadAndTail(message);
                        data = result.getBytes(StandardCharsets.UTF_8);
                        is = new ByteArrayInputStream(data);
                        buf = new BufferedReader(new InputStreamReader(is));
                        str = buf.readLine();
                        // 写入输出流
                        printWriter.println(str);
                        // 清空缓存立刻发出
                        printWriter.flush();

                        /**
                         * 发送完就把执行权交给读线程
                         * 然后唤醒reader
                         */
                        num = 1;
                        condition_reader.signalAll();
                    }

                    closeServerThread();
                } catch (InterruptedException | IOException e) {
                    e.printStackTrace();
                } finally {
                    // 解锁
                    lock.unlock();
                    // 释放资源
                    try {
                        if (is != null) {
                            printWriter.close();
                        }
                        if (buf != null) {
                            buf.close();
                        }
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }

    public static void main(String[] args) {
        new MyServer(9999).start();
    }
}
```

- MyClient.java

```java
package demo9;

import java.io.*;
import java.net.Socket;
import java.util.Objects;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class MyClient {

    private Socket socket;
    private InputStream inputStream;
    private OutputStream outputStream;
    // 1是轮到写线程写，2是轮到读线程读 （写线程先执行）
    private int num = 1;
    // 锁
    private Lock lock = new ReentrantLock();
    // 写线程运行条件
    private Condition condition_writer = lock.newCondition();
    // 读线程运行条件
    private Condition condition_reader = lock.newCondition();
    // 是不是已经关闭socket
    private boolean flag = false;
    public static final String CHECK_ERROR = "数据校验错误";

    /**
     * 初始化客户端的资源
     */
    public MyClient(String address, int port) {
        try {
            socket = new Socket(address, port);
            inputStream = socket.getInputStream();
            outputStream = socket.getOutputStream();
        } catch (IOException e) {
            e.printStackTrace();
        }
        System.out.println("客户端启动成功");
    }

    /**
     * 启动读、写线程，读写交替进行
     */
    public void start() {
        new Reader().start();
        new Writer().start();
    }

    /**
     * 去除头尾
     *
     * @param str
     * @return
     */
    public String removeHeadAndTail(String str) {
        // 检验头尾是否是0x55 0xAA
        int head = str.charAt(0);
        int tail = str.charAt(str.length() - 1);
        if (head != 85 || tail != 170) {
            // 数据接收不对的处理
            return CHECK_ERROR;
        } else {
            // 去掉头尾后的json字符串
            return str.substring(1, str.length() - 1);
        }
    }

    /**
     * 加上头尾
     *
     * @param str
     * @return
     */
    public String addHeadAndTail(String str) {
        return ((char) 85) + str + ((char) 170);
    }

    /**
     * 读线程
     */
    private class Reader extends Thread {
        // 获取服务器发来的信息
        private InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
        private BufferedReader bufferedReader = new BufferedReader(inputStreamReader);

        @Override
        public void run() {
            // 加锁
            lock.lock();

            /**
             * 与写线程交替读写
             * 直到服务器返回exit命令
             * 或者是由客户端发出的exit命令
             * 然后关闭连接释放资源
             */
            try {
                String line = "";
                OUT:
                while (!socket.isClosed() && line != null && !"exit".equals(line)) {
                    /**
                     * 如果没轮到自己读，就阻塞自己
                     */
                    while (num != 2) {
                        condition_reader.await();
                        // 连接关闭后跳出两层循环，不执行bufferedReader.readLine();
                        if (flag) {
                            break OUT;
                        }
                    }

                    /**
                     * 一次读
                     */
                    // TODO: 2021/10/15 服务器直接断开，此处会抛异常  Connection reset
                    line = bufferedReader.readLine();

                    if (line != null) {
                        // 去头尾
                        String result = removeHeadAndTail(line);

                        if (Objects.equals(CHECK_ERROR, result)) {
                            // 校验错误
                            System.out.println(CHECK_ERROR);
                        } else {
                            // 校验成功并去除了头尾
                            System.out.println("服务器发来：" + result);
                        }
                    }

                    /**
                     * 读完一次就把执行权交给写线程
                     * 然后唤醒writer
                     */
                    num = 1;
                    condition_writer.signalAll();
                }

                closeMyClient();
                System.out.println("关闭了连接");
            } catch (InterruptedException | IOException e) {
                e.printStackTrace();
                System.out.println("连接已关闭");
            } finally {
                // 解锁
                lock.unlock();
                // 释放Reader的资源
                try {
                    if (inputStreamReader != null) {
                        inputStreamReader.close();
                    }
                    if (bufferedReader != null) {
                        bufferedReader.close();
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    /**
     * 写线程
     */
    private class Writer extends Thread {
        // 发给服务器
        private PrintWriter printWriter = new PrintWriter(outputStream);
        // 从键盘获取要发送给服务器的消息
        private BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(System.in));

        @Override
        public void run() {
            // 加锁
            lock.lock();

            /**
             * 与读线程交替读写
             * 直到客户端自己发出exit命令
             * 然后关闭连接释放资源
             */
            try {
                String line = "";
                // 连接没关闭且数据不为空且指令不是exit退出指令，就发送数据
                while (!socket.isClosed() && line != null && !"exit".equals(line)) {
                    /**
                     * 如果没轮到自己写，就阻塞自己
                     */
                    while (num != 1) {
                        condition_writer.await();
                    }

                    /**
                     * 一次写
                     */
                    line = bufferedReader.readLine();
                    String cmd = addHeadAndTail(line);
                    if (!"".equals(cmd)) {
                        // 写出
                        printWriter.println(cmd);
                        printWriter.flush();
                        System.out.println("发送了" + line);

                        /**
                         * 发送完就把执行权交给读线程
                         * 然后唤醒reader
                         */
                        num = 2;
                        condition_reader.signalAll();
                    } else {
                        System.out.println("不能发送给服务器空的数据");
                    }
                }
                // 关闭连接
                closeMyClient();
                System.out.println("客户端主动关闭了连接");

                /**
                 * 特例：客户端的指令是exit
                 * 直接就关闭资源，不用发送给服务器信息
                 * 必须唤醒一下reader，不然会阻塞
                 */
                flag = true;
                condition_reader.signalAll();
            } catch (InterruptedException | IOException e) {
                e.printStackTrace();
                System.out.println("连接已关闭");
            } finally {
                // 解锁
                lock.unlock();
                // 释放Writer的资源
                try {
                    if (printWriter != null) {
                        printWriter.close();
                    }
                    if (bufferedReader != null) {
                        bufferedReader.close();
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    /**
     * 关闭资源
     */
    private void closeMyClient() {
        try {
            if (inputStream != null) {
                inputStream.close();
            }
            if (outputStream != null) {
                outputStream.close();
            }
            if (socket != null) {
                socket.close();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        new MyClient("127.0.0.1", 9999).start();
    }
}
```

- 截图

![image-20211025122317370](./基于BIO的Socket通信.assets/image-20211025122317370.png)

![image-20211025122333613](./基于BIO的Socket通信.assets/image-20211025122333613.png)

