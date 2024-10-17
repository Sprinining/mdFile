---
title: Paths和Files
date: 2024-08-17 01:17:24 +0800
categories: [java, network programming]
tags: [Java, Network Programming, NIO, Paths, Files]
description: 
---
## Paths 类

Paths 类主要用于操作文件和目录路径。它提供了一些静态方法，用于创建`java.nio.file.Path`实例，代表文件系统中的路径。

```java
// 创建一个Path实例，表示当前目录下的一个文件
Path path = Paths.get("example.txt");

// 创建一个绝对路径
Path absolutePath = Paths.get("/home/user/example.txt");
```

`java.nio.file.Path` 接口代表一个文件系统中的路径。它提供了一系列方法来操作和查询路径。

```java
Path path = Paths.get("docs/xx.md");

// 获取文件名
System.out.println("File name: " + path.getFileName());

// 获取父目录
System.out.println("Parent: " + path.getParent());

// 获取根目录
System.out.println("Root: " + path.getRoot());

// 将路径与另一个路径结合
Path newPath = path.resolve("config/app.properties");
System.out.println("Resolved path: " + newPath);

// 简化路径
Path normalizedPath = newPath.normalize();
System.out.println("Normalized path: " + normalizedPath);

// 将相对路径转换为绝对路径
Path absolutePath = path.toAbsolutePath();
System.out.println("Absolute path: " + absolutePath);

// 计算两个路径之间的相对路径
Path basePath = Paths.get("/docs/");
Path targetPath = Paths.get("/docs/imgs/xxx");
Path relativePath = basePath.relativize(targetPath);
System.out.println("Relative path: " + relativePath);
```

## Files 类

`java.nio.file.Files`类提供了大量静态方法，用于处理文件系统中的文件和目录。这些方法包括文件的创建、删除、复制、移动等操作，以及读取和设置文件属性。

```java
// 创建一个Path实例
Path path = Paths.get("logs/xx.txt");

// 创建一个新文件
Files.createFile(path);

// 检查文件是否存在
boolean exists = Files.exists(path);
System.out.println("File exists: " + exists);

// 删除文件
Files.delete(path);
```

1、`exists(Path path, LinkOption... options)`：检查文件或目录是否存在。

```java
Path path = Paths.get("file.txt");
boolean exists = Files.exists(path);
System.out.println("File exists: " + exists);
```

LinkOption 是一个枚举类，它定义了如何处理文件系统链接的选项。它位于 java.nio.file 包中。LinkOption 主要在与文件或目录的路径操作相关的方法中使用，以控制这些方法如何处理符号链接。符号链接是一种特殊类型的文件，它在 Unix 和类 Unix 系统（如 Linux 和 macOS）上很常见。在 Windows 上，类似的概念被称为快捷方式。

2、`createFile(Path path, FileAttribute<?>... attrs)`：创建一个新的空文件。

```java
Path newPath = Paths.get("newFile.txt");
Files.createFile(newPath);
```

FileAttribute 是一个泛型接口，用于处理各种不同类型的属性。在使用 FileAttribute 时，你需要为其提供一个特定的实现。`java.nio.file.attribute` 包中的 PosixFileAttributes 类提供了 POSIX（Portable Operating System Interface，定义了许多与文件系统相关的操作，包括文件和目录的创建、删除、读取和修改。）文件属性的实现。

```java
Path path = Paths.get("fileWithPermissions.txt");

Set<PosixFilePermission> permissions = PosixFilePermissions.fromString("rw-r-----");
FileAttribute<Set<PosixFilePermission>> fileAttribute = PosixFilePermissions.asFileAttribute(permissions);

Files.createFile(path, fileAttribute);
```

PosixFileAttributes 接口提供了获取 POSIX 文件属性的方法，如文件所有者、文件所属的组以及文件的访问权限。以上示例会创建一个读写属性的文件。

3、`createDirectory(Path dir, FileAttribute<?>... attrs)`：创建一个新的目录。

```java
Path newDir = Paths.get("newDirectory");
Files.createDirectory(newDir);
```

4、`delete(Path path)`：删除文件或目录。

```java
Path pathToDelete = Paths.get("fileToDelete.txt");
Files.delete(pathToDelete);
```

5、`copy(Path source, Path target, CopyOption... options)`：复制文件或目录。

```java
Path sourcePath = Paths.get("sourceFile.txt");
Path targetPath = Paths.get("targetFile.txt");
Files.copy(sourcePath, targetPath, StandardCopyOption.REPLACE_EXISTING);
```

在 Java NIO 中，有两个实现了 CopyOption 接口的枚举类：StandardCopyOption 和 LinkOption。

StandardCopyOption 枚举类提供了以下两个选项：

- REPLACE_EXISTING：如果目标文件已经存在，该选项会使 `Files.copy()` 方法替换目标文件。如果不指定此选项，`Files.copy()` 方法在目标文件已存在时将抛出 FileAlreadyExistsException。
- COPY_ATTRIBUTES：此选项表示在复制文件时，尽可能地复制文件的属性（如文件时间戳、权限等）。如果不指定此选项，那么目标文件将具有默认的属性。

6、`move(Path source, Path target, CopyOption... options)`：移动或重命名文件或目录。

```java
Path sourcePath = Paths.get("sourceFile.txt");
Path targetPath = Paths.get("targetFile.txt");
Files.move(sourcePath, targetPath, StandardCopyOption.REPLACE_EXISTING);
```

7、`readAllLines(Path path, Charset cs)`：读取文件的所有行到一个字符串列表。

```java
Path path = Paths.get("file.txt");
List<String> lines = Files.readAllLines(path, StandardCharsets.UTF_8);
lines.forEach(System.out::println);
```

8、`write(Path path, Iterable<? extends CharSequence> lines, Charset cs, OpenOption... options)`：将字符串列表写入文件。

```java
Path path = Paths.get("file.txt");
List<String> lines = Arrays.asList("1", "2", "3");
Files.write(path, lines, StandardCharsets.UTF_8);
```

OpenOption 是 Java NIO 中一个用于配置文件操作的接口。它提供了在使用 `Files.newByteChannel()`、`Files.newInputStream()`、`Files.newOutputStream()`、`AsynchronousFileChannel.open()` 和 `FileChannel.open()` 方法时定制行为的选项。

在 Java NIO 中，有两个实现了 OpenOption 接口的枚举类：StandardOpenOption 和 LinkOption。

StandardOpenOption 枚举类提供了以下几个选项：

- READ：以读取模式打开文件。
- WRITE：以写入模式打开文件。
- APPEND：以追加模式打开文件。
- TRUNCATE_EXISTING：在打开文件时，截断文件的内容，使其长度为 0。仅适用于 WRITE 或 APPEND 模式。
- CREATE：当文件不存在时创建文件。如果文件已存在，则打开文件。
- CREATE_NEW：当文件不存在时创建文件。如果文件已存在，抛出 FileAlreadyExistsException。
- DELETE_ON_CLOSE：在关闭通道时删除文件。
- SPARSE：提示文件系统创建一个稀疏文件。
- SYNC：要求每次更新文件的内容或元数据时都进行同步。
- DSYNC：要求每次更新文件内容时都进行同步。

8、`newBufferedReader(Path path, Charset cs) 和 newBufferedWriter(Path path, Charset cs, OpenOption... options)`：创建 BufferedReader 和 BufferedWriter 对象以读取和写入文件。

```java
Path path = Paths.get("file.txt");

// Read file
try (BufferedReader reader = Files.newBufferedReader(path, StandardCharsets.UTF_8)) {
    String line;
    while ((line = reader.readLine()) != null) {
        System.out.println(line);
    }
}

// Write file
Path outputPath = Paths.get("outputFile.txt");
try (BufferedWriter writer = Files.newBufferedWriter(outputPath, StandardCharsets.UTF_8)) {
    writer.write("xx");
}
```

### Files.walkFileTree() 静态方法

这个方法可以递归地访问目录结构中的所有文件和目录，并允许您对这些文件和目录执行自定义操作。使用 walkFileTree 方法时，需要提供一个起始路径（起始目录）和一个实现了 FileVisitor 接口的对象。FileVisitor 接口包含四个方法，它们在遍历过程中的不同阶段被调用：

- `preVisitDirectory`：在访问目录之前调用。
- `postVisitDirectory`：在访问目录之后调用。
- `visitFile`：在访问文件时调用。
- `visitFileFailed`：在访问文件失败时调用。

```java
public static void main(String[] args) {
    Path startingDir = Paths.get("docs");
    MyFileVisitor fileVisitor = new MyFileVisitor();

    try {
        Files.walkFileTree(startingDir, fileVisitor);
    } catch (IOException e) {
        e.printStackTrace();
    }
}

private static class MyFileVisitor extends SimpleFileVisitor<Path> {
    @Override
    public FileVisitResult preVisitDirectory(Path dir, BasicFileAttributes attrs) throws IOException {
        System.out.println("准备访问目录: " + dir);
        return FileVisitResult.CONTINUE;
    }

    @Override
    public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException {
        System.out.println("正在访问目录: " + dir);
        return FileVisitResult.CONTINUE;
    }

    @Override
    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
        System.out.println("访问文件: " + file);
        return FileVisitResult.CONTINUE;
    }

    @Override
    public FileVisitResult visitFileFailed(Path file, IOException exc) throws IOException {
        System.err.println("访问文件失败: " + file);
        return FileVisitResult.CONTINUE;
    }
}
```

其中，FileVisitResult 枚举包含以下四个选项：

- CONTINUE ： 继续
- TERMINATE ： 终止
- SKIP_SIBLINGS ： 跳过兄弟节点，然后继续
- SKIP_SUBTREE ： 跳过子树（不访问此目录的条目），然后继续，仅在 preVisitDirectory 方法返回时才有意义，除此以外和 CONTINUE 相同。

#### 搜索文件

```java
public static void main(String[] args) {
    Path startingDir = Paths.get("./");
    String targetFileName = "hello.txt";
    FindFileVisitor findFileVisitor = new FindFileVisitor(targetFileName);

    try {
        Files.walkFileTree(startingDir, findFileVisitor);
        if (findFileVisitor.isFileFound()) {
            System.out.println("找到文件了: " + findFileVisitor.getFoundFilePath());
        } else {
            System.out.println("ooh，文件没找到");
        }
    } catch (IOException e) {
        e.printStackTrace();
    }
}

private static class FindFileVisitor extends SimpleFileVisitor<Path> {
    private final String targetFileName;
    private Path foundFilePath;

    public FindFileVisitor(String targetFileName) {
        this.targetFileName = targetFileName;
    }

    public boolean isFileFound() {
        return foundFilePath != null;
    }

    public Path getFoundFilePath() {
        return foundFilePath;
    }

    @Override
    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
        String fileName = file.getFileName().toString();
        if (fileName.equals(targetFileName)) {
            foundFilePath = file;
            return FileVisitResult.TERMINATE;
        }
        return FileVisitResult.CONTINUE;
    }
}
```

Paths 和 Files 是 Java NIO 中的两个核心类。Paths 提供了一系列静态方法，用于操作路径（Path 对象）。它可以将字符串或 URI 转换为 Path 对象，方便后续操作。Files 类提供了丰富的文件操作方法，如文件的创建、删除、移动、复制、读取和写入等。这些方法支持各种选项和属性，如覆盖、保留属性和符号链接处理。Files 还支持文件遍历（如 walkFileTree 方法），可以处理文件目录树。总之，Paths 和 Files 为文件和目录操作提供了简洁、高效的方法。
