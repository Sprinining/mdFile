---
title: IO流
date: 2022-03-21 03:35:24 +0800
categories: [java, io]
tags: [Java, IO]
description: 
---
# Stream

- 字节流操作的基本单元为字节；字符流操作的基本单元为Unicode码元。
- 字节流默认不使用缓冲区；字符流使用缓冲区。
- 字节流通常用于处理二进制数据，实际上它可以处理任意类型的数据，但它不支持直接写入或读取Unicode码元；字符流通常处理文本数据，它支持写入及读取Unicode码元。

![iostream2xx](./IO流.assets/iostream2xx.png)

## BufferedReader

- BufferedReader br = new BufferedReader(new InputStreamReader(System.in));

- int read( ) throws IOException
- String readLine( ) throws IOException
- void write(int byteval)

### 从控制台读取多字符输入

```java
char c;
// 使用System.in创建BufferedReader
BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
System.out.println("输入字符, 按下 'q' 键退出。");
// 读取字符
do {
    // 一个一个读
    c = (char) br.read();
    System.out.println(c);
} while (c != 'q');
```

### 从控制台读取字符串

```java
// 使用System.in创建BufferedReader
BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
String str;
System.out.println("Enter lines of text.");
System.out.println("Enter 'end' to quit.");
do {
    str = br.readLine();
    System.out.println(str);
} while (!str.equals("end"));
```

## File类

```java
// 通过给定的父抽象路径名和子路径名字符串创建一个新的File实例
File(File parent, String child);
// 通过将给定路径名字符串转换成抽象路径名来创建一个新 File 实例
File(String pathname)
// 根据 parent 路径名字符串和 child 路径名字符串创建一个新 File 实例
File(String parent, String child)
// 通过将给定的 file: URI 转换成一个抽象路径名来创建一个新的 File 实例
File(URI uri)
```

## FileInputStream

```java
// 读取文件的两种方式
InputStream f = new FileInputStream("C:\\Users\\Administrator\\Downloads\\myfile.txt");

File file = new File("C:\\Users\\Administrator\\Downloads\\myfile.txt");
InputStream in = new FileInputStream(file);

// 关闭此文件输入流并释放与此流有关的所有系统资源。抛出IOException异常
public void close() throws IOException{}
// 这个方法清除与该文件的连接。确保在不再引用文件输入流时调用其 close 方法。抛出IOException异常
protected void finalize()throws IOException {}
// 这个方法从 InputStream 对象读取指定字节的数据。返回为整数值。返回下一字节数据，如果已经到结尾则返回-1
public int read(int r)throws IOException{}
// 这个方法从输入流读取r.length长度的字节。返回读取的字节数。如果是文件结尾则返回-1
public int read(byte[] r) throws IOException{}
// 返回下一次对此输入流调用的方法可以不受阻塞地从此输入流读取的字节数。返回一个整数值
public int available() throws IOException{}
```

- int read()

```java
// 创建一个FileInputStream对象:
InputStream input = new FileInputStream("file.txt");
for (;;) {
    //
    /**
     * 读取输入流的下一个字节，并返回字节表示的int值（0~255）。如果已读到末尾，返回-1表示不能继续读取了。
     * 如：abc哈1
     * 返回的是97 98 99 229 147 136 49
     * 中文对应三个字节
     */
    int n = input.read(); // 反复调用read()方法，直到返回-1
    if (n == -1) {
        break;
    }
    System.out.println(n); // 打印byte的值
}
input.close(); // 关闭流
```

`InputStream`也有缓冲区。例如，从`FileInputStream`读取一个字节时，操作系统往往会一次性读取若干字节到缓冲区，并维护一个指针指向未读的缓冲区。然后，每次我们调用`int read()`读取下一个字节时，可以直接返回缓冲区的下一个字节，避免每次读一个字节都导致IO操作。当缓冲区全部读完后继续调用`read()`，则会触发操作系统的下一次读取并再次填满缓冲区。

- 确保流被关闭

```java
InputStream input = null;
try {
    input = new FileInputStream("file.txt");
    int n;
    while ((n = input.read()) != -1) { // 利用while同时读取并判断
        System.out.println(n);
    }
} finally {
    if (input != null) {
        input.close();
    }
}
```

- java7新特性try()

```java
try (InputStream input = new FileInputStream("file.txt")) {
    int n;
    while ((n = input.read()) != -1) {
        System.out.println(n);
    }
} // 编译器在此自动为我们写入finally并调用close()
/**
 * 编译器只看try(resource = ...)中的对象是否实现了java.lang.AutoCloseable接口，
 * 如果实现了，就自动加上finally语句并调用close()方法。
 * InputStream和OutputStream都实现了这个接口，因此，都可以用在try(resource)中。
 */
/**
 * ab
 *
 * c
 * 97 98 13 10 13 10 99
 * 13代表CR，10代表LF
 * windows 采用“回车+换行，CR/LF”表示下一行
 */
```

- 缓冲int read(byte[])和int read(byte[] b, int off, int len)

```java
try (InputStream input = new FileInputStream("file.txt")) {
    // 定义1000个字节大小的缓冲区:
    byte[] buffer = new byte[1000];
    int n;
    // 返回值不再是字节的int值，而是返回实际读取了多少个字节
    while ((n = input.read(buffer)) != -1) { // 读取到缓冲区
        System.out.println("字节数为：" + n);
    }
}
// int read(byte[] b, int off, int len)：指定byte[]数组的偏移量和最大填充数
// 将输入流中最多 len 个数据字节读入字节数组。
```

- 阻塞

```java
int n;
n = input.read(); // 必须等待read()方法返回才能执行下一行代码
int m = n;
```

- ByteArrayInputStream

```java
byte[] data = {97, 98, 13, 10, 99};
// ByteArrayInputStream实际上是把一个byte[]数组在内存中变成一个InputStream
try (InputStream input = new ByteArrayInputStream(data)) {
    int n;
    while ((n = input.read()) != -1) {
        System.out.print((char) n);
    }
}
```

## FileOutputStream

```java
// 写入
OutputStream f = new FileOutputStream("C:\\Users\\Administrator\\Downloads\\myfile.txt");

File file = new File("C:\\Users\\Administrator\\Downloads\\myfile.txt");
OutputStream fOut = new FileOutputStream(file);

// 关闭此文件输入流并释放与此流有关的所有系统资源。抛出IOException异常
public void close() throws IOException{}
// 这个方法清除与该文件的连接。确保在不再引用文件输入流时调用其 close 方法。抛出IOException异常
protected void finalize()throws IOException {}
// 这个方法把指定的字节写到输出流中
public void write(int w)throws IOException{}
// 把指定数组中w.length长度的字节写到OutputStream中
public void write(byte[] w)
```

- void  write(int)

```java
public abstract void write(int b) throws IOException;
```

写入一个字节到输出流。要注意的是，虽然传入的是`int`参数，但只会写入一个字节，即只写入`int`最低8位表示字节的部分（相当于`b & 0xff`）。

```java
OutputStream output = new FileOutputStream("file.txt");
output.write(72); // H
// 十进制72的二进制：1001000
// 101001000二进制的十进制328
output.write(328); // 取的是低八位，1001000，对应的还是H
output.write(101); // e
output.write(108); // l
output.write(108); // l
output.write(111); // o

output.close();
```

- void write(byte[])

```java
try (OutputStream output = new FileOutputStream("file.txt")) {
    output.write("Hello".getBytes("UTF-8")); // Hello
} // 编译器在此自动为我们写入finally并调用close()
```

- flush()

为什么要有`flush()`？因为向磁盘、网络写入数据的时候，出于效率的考虑，操作系统并不是输出一个字节就立刻写入到文件或者发送到网络，而是把输出的字节先放到内存的一个缓冲区里（本质上就是一个`byte[]`数组），等到缓冲区写满了，再一次性写入文件或者网络。对于很多IO设备来说，一次写一个字节和一次写1000个字节，花费的时间几乎是完全一样的，所以`OutputStream`有个`flush()`方法，能强制把缓冲区内容输出。

通常情况下，我们不需要调用这个`flush()`方法，因为缓冲区写满了`OutputStream`会自动调用它，并且，在调用`close()`方法关闭`OutputStream`之前，也会自动调用`flush()`方法。

- 阻塞

- ByteArrayOutputStream

```java
byte[] data;
try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
    output.write("Hello ".getBytes(StandardCharsets.UTF_8));
    output.write("world!".getBytes(StandardCharsets.UTF_8));
    data = output.toByteArray();
}
System.out.println(new String(data, StandardCharsets.UTF_8));
```

## Reader

- `Reader`本质上是一个基于`InputStream`的`byte`到`char`的转换器

- 区别

| InputStream                         | Reader                                |
| :---------------------------------- | :------------------------------------ |
| 字节流，以`byte`为单位              | 字符流，以`char`为单位                |
| 读取字节（-1，0~255）：`int read()` | 读取字符（-1，0~65535）：`int read()` |
| 读到字节数组：`int read(byte[] b)`  | 读到字符数组：`int read(char[] c)`    |

- FileReader

```java
// 字符编码是???
try (Reader reader = new FileReader("file.txt", StandardCharsets.UTF_8);) {
    while (true) {
        int n = reader.read(); // 反复调用read()方法，直到返回-1
        if (n == -1) {
            break;
        }
        System.out.print((char) n); // 打印char
    }
}
```

```java
try (Reader reader = new FileReader("file.txt", StandardCharsets.UTF_8)) {
    char[] buffer = new char[1000];
    int n;
    // 一次性读取若干字符并填充到char[]数组
    while ((n = reader.read(buffer)) != -1) {
        System.out.println("read " + n + " chars.");
    }
}
```

- FileInputStream

```java
// 当关闭Reader时，它会在内部自动调用InputStream的close()方法
try (Reader reader = new InputStreamReader(new FileInputStream("file.txt"), StandardCharsets.UTF_8)) {

}
```

## Writer

| OutputStream                           | Writer                                   |
| :------------------------------------- | :--------------------------------------- |
| 字节流，以`byte`为单位                 | 字符流，以`char`为单位                   |
| 写入字节（0~255）：`void write(int b)` | 写入字符（0~65535）：`void write(int c)` |
| 写入字节数组：`void write(byte[] b)`   | 写入字符数组：`void write(char[] c)`     |
| 无对应方法                             | 写入String：`void write(String s)`       |

- 写入一个字符（0~65535）：`void write(int c)`；
- 写入字符数组的所有字符：`void write(char[] c)`；
- 写入String表示的所有字符：`void write(String s)`。

- FileWriter

```java
try (Writer writer = new FileWriter("file.txt", StandardCharsets.UTF_8)) {
    writer.write('H'); // 写入单个字符
    writer.write("Hello".toCharArray()); // 写入char[]
    writer.write("Hello"); // 写入String
}
```

- OutputStreamWriter

```java
try (Writer writer = new OutputStreamWriter(new FileOutputStream("readme.txt"), "UTF-8")) {
    // TODO:
}
```



## 目录

### 创建

```java
String dirname = "C:\\Users\\Administrator\\Downloads\\myDir\\childDir";
File d = new File(dirname);
// 创建一个文件夹和它的所有父文件夹
d.mkdirs();

dirname = "C:\\Users\\Administrator\\Downloads\\myDir\\childDir\\childDir2";
d = new File(dirname);
// 创建一个文件夹，成功则返回true，失败则返回false。
// 失败表明File对象指定的路径已经存在，或者由于整个路径还不存在，该文件夹不能被创建
d.mkdir();
```

### 读取

```java
String dirname = "F:\\一级目录";
File f1 = new File(dirname);
// 判断是否是目录
if (f1.isDirectory()) {
    System.out.println("目录 " + dirname);
    // 调用该对象上的 list() 方法，来提取它包含的文件和文件夹的列表
    String s[] = f1.list();
    for (int i = 0; i < s.length; i++) {
        File f = new File(dirname + "/" + s[i]);
        if (f.isDirectory()) {
            System.out.println(s[i] + " 是一个目录");
        } else {
            System.out.println(s[i] + " 是一个文件");
        }
    }
} else {
    System.out.println(dirname + " 不是一个目录");
}
/**
 * 目录 F:\一级目录
 * 一级目录下的文件.txt 是一个文件
 * 二级目录 是一个目录
 */
```

### 删除

```java
public static void main(String[] args) throws IOException {

    File folder = new File("F:\\一级目录");
    deleteFolder(folder);
}

// 删除文件及目录
public static void deleteFolder(File folder) {
    File[] files = folder.listFiles();
    if (files != null) {
        for (File f : files) {
            if (f.isDirectory()) {
                // 递归删除
                deleteFolder(f);
            } else {
                f.delete();
            }
        }
    }
    folder.delete();
}
```

