---
title: Thread Dump分析
date: 2024-07-19 12:59:24 +0800
categories: [java, concurrent programming]
tags: [Java, Concurrent Programming, Thread]
description: 
---
## 使用

```bash
jps 或 ps –ef | grep java （获取PID）
jstack [-l ] <pid> | tee -a jstack.log（获取ThreadDump）
```

## 分析

- 头部信息：时间，JVM信息

```sh
2024-07-19 12:45:51
Full thread dump Java HotSpot(TM) 64-Bit Server VM (25.321-b07 mixed mode):
```

- 线程INFO信息块：

```java
"Monitor Ctrl-Break" #6 daemon prio=5 os_prio=0 tid=0x000002c7f3e15800 nid=0x8d8 runnable [0x000000c91b9ff000]
// 线程名称：Monitor Ctrl-Break；线程类型：daemon；优先级: 5，默认是5
// JVM线程id：tid=0x000002c7f3e15800，JVM内部线程的唯一标识（通过java.lang.Thread.getId()获取，通常用自增方式实现）。
// 对应系统线程id（NativeThread ID）：nid=0x8d8，和top命令查看的线程pid对应，不过一个是10进制，一个是16进制。（通过命令：top -H -p pid，可以查看该进程的所有线程信息）
// 线程状态：runnable
// 起始栈地址：[0x000000c91b9ff000]，对象的内存地址
   java.lang.Thread.State: RUNNABLE
        at java.net.SocketInputStream.socketRead0(Native Method)
        at java.net.SocketInputStream.socketRead(SocketInputStream.java:116)
        at java.net.SocketInputStream.read(SocketInputStream.java:171)
        at java.net.SocketInputStream.read(SocketInputStream.java:141)
        at sun.nio.cs.StreamDecoder.readBytes(StreamDecoder.java:284)
        at sun.nio.cs.StreamDecoder.implRead(StreamDecoder.java:326)
        at sun.nio.cs.StreamDecoder.read(StreamDecoder.java:178)
        - locked <0x0000000716ad97f8> (a java.io.InputStreamReader)
        at java.io.InputStreamReader.read(InputStreamReader.java:184)
        at java.io.BufferedReader.fill(BufferedReader.java:161)
        at java.io.BufferedReader.readLine(BufferedReader.java:324)
        - locked <0x0000000716ad97f8> (a java.io.InputStreamReader)
        at java.io.BufferedReader.readLine(BufferedReader.java:389)
        at com.intellij.rt.execution.application.AppMainV2$1.run(AppMainV2.java:54)

   Locked ownable synchronizers:
        - None
```

