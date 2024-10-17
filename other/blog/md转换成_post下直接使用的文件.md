---
title: md转换成_post下直接使用的文件
date: 2024-09-22 09:29:12 +0800
categories: [other, blog]
tags: [Blog, Script, Chripy]
description: 
---
## md转换成_post下直接使用的文件

```java
package org.example;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

public class Main {
    enum FileTime {
        CREATE, MODIFY, ACCESS;
    }

    /*
            ---
            title: 排序
            date: 2023-09-03 13:14:22 +0800
            categories: [algorithm, summary]
            tags: [自定义标签1, 自定义标签2]
            media_subpath: /assets/media/pictures/
            description: haha
            ---
    */
    public static final String FILE_PATH = "C:\\Users\\Spring\\Downloads\\algorithm";
    public static final String DATE_PATTERN = "yyyy-MM-dd hh:mm:ss";
    // md 文档中所有图片路径的父路径
    public static final String MEDIA_SUB_PATH = "/assets/media/pictures/";

    public static void main(String[] args) throws Exception {
        File file = new File(FILE_PATH);
        traverseDirectory(file);
    }

    public static void main2(String[] args) throws IOException {
        String s = "C:\\Users\\Spring\\Downloads\\algorithm\\summary\\链表反转.md";
        File file = new File(s);
        if (isMdFile(file.getName()))
            System.out.println(getFileTime(new File(s), FileTime.MODIFY));
    }

    // 将 markdown 文件转换成可以直接放在 _posts 文件夹下发布的文件
    public static void convert(File file) throws Exception {
        String dateStr = getFileTime(file, FileTime.MODIFY);
        String originFileName = file.getName();
        // 插入前页
        insertFrontMatter(file, dateStr, originFileName);
        // 加前缀
        addDatePrefix(file, dateStr);
    }

    public static void insertFrontMatter(File file, String dateStr, String originFileName) throws Exception {
        String inserted = "---\n" +
                "title: " + getName(originFileName) + "\n" +
                "date: " + dateStr + " +0800\n" +
                "categories: " + "[" +
                "]\n" +
                "tags: " + "[" +
                "]\n" +
                "media_subpath: " + MEDIA_SUB_PATH + "\n" +
                "description: " +
                "\n" +
                "---\n";
        insertFileHeader(inserted.getBytes(StandardCharsets.UTF_8), file);
    }

    // 给文件增加日期前缀
    public static void addDatePrefix(File file, String dateStr) {
        String newName = file.getParent() + "\\" + dateStr.split(" ")[0] + "-" + file.getName();
        File newFile = new File(newName);
        if (!file.renameTo(newFile))
            System.out.println("rename error");
    }


    private static void insertFileHeader(byte[] header, File file) throws Exception {
        RandomAccessFile src = new RandomAccessFile(file, "rw");
        int srcLength = (int) src.length();
        byte[] buff = new byte[srcLength];
        src.read(buff, 0, srcLength);
        src.seek(0);
        src.write(header);
        src.seek(header.length);
        src.write(buff);
        src.close();
    }


    private static String getFileTime(File file, FileTime fileTime) throws IOException {
        if (file == null) return null;
        Path path = file.toPath();
        BasicFileAttributes attr = Files.readAttributes(path, BasicFileAttributes.class);
        if (attr == null) return null;

        Instant instant = null;
        switch (fileTime) {
            // 创建时间
            case CREATE:
                instant = attr.creationTime().toInstant();
                break;
            // 更新时间
            case MODIFY:
                instant = attr.lastModifiedTime().toInstant();
                break;
            // 上次访问时间
            case ACCESS:
                attr.lastAccessTime().toInstant();
                break;
            default:
        }
        if (instant == null) return null;
        return DateTimeFormatter.ofPattern(DATE_PATTERN).withZone(ZoneId.systemDefault()).format(instant);
    }

    private static void traverseDirectory(File directory) throws Exception {
        // 列出目录下的所有文件和子目录
        File[] filesAndDirs = directory.listFiles();
        if (filesAndDirs == null) return;
        // 遍历每个文件和子目录
        for (File fileOrDir : filesAndDirs) {
            if (fileOrDir.isFile()) {
                // 是 markdown 文件才处理
                if (isMdFile(fileOrDir.getName())) {
                    convert(fileOrDir);
                }
            } else if (fileOrDir.isDirectory()) {
                // 如果是目录，递归遍历子目录
                traverseDirectory(fileOrDir);
            }
        }
    }

    // 去除扩展名
    private static String getName(String fileName) {
        return fileName.substring(0, fileName.lastIndexOf('.'));
    }

    // 判断是否是 markdown 文件
    private static boolean isMdFile(String fileName) {
        String extension = fileName.substring(fileName.lastIndexOf('.'));
        return ".md".equals(extension) || ".markdown".equals(extension);
    }

}
```
