---
title: Stream
date: 2024-06-23 10:15:17 +0800
categories: [java, java advanced]
tags: [Java, Stream]
description: 
---
```java
package newfeature;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class MyStream {
    public static void main(String[] args) {
        List<String> strings = Arrays.asList("abc", "", "dsf", "ghg", "abc");

        List<User> users = new ArrayList<>();
        users.add(new User(1, "a"));
        users.add(new User(1, "a"));
        users.add(new User(1, "a"));

        // 中间操作符返回的是stream
        // filter
        System.out.println(strings.stream()
                .filter(str -> str.contains("d"))
                .collect(Collectors.toList()));

        // distinct
        System.out.println(strings.stream()
                .distinct()
                .collect(Collectors.toList()));

        System.out.println(users.stream()
                .distinct()
                .collect(Collectors.toList()));

        // limit
        System.out.println(strings.stream()
                .limit(2)// 只取前两个
                .collect(Collectors.toList()));

        // skip
        System.out.println(strings.stream()
                .skip(2)// 去掉前两个
                .collect(Collectors.toList()));

        // map
        // 对流中所有元素做统一处理
        System.out.println(strings.stream()
                .map(str -> "haha" + str)
                .collect(Collectors.toList()));

        // flatmap
        // 字符串转为字符流
        System.out.println(strings.stream()
                .flatMap(str -> getCharacterByString(str))
                .collect(Collectors.toList()));

        // sorted
        System.out.println(strings.stream()
                .sorted()
                .collect(Collectors.toList()));


        // 终止操作符
        // anyMath
        System.out.println(strings.stream()
                .anyMatch(str->str.contains("a")));

        // allMatch
        System.out.println(strings.stream()
                .anyMatch(str->str.length()>0));

        // noneMatch
        System.out.println(strings.stream()
                .anyMatch(str->str.length()>100));

        // findAny
        System.out.println(strings.stream()
                .findAny());// 返回Option对象  Optional[abc]
        System.out.println(strings.stream()
                .findAny().get());

        // findFirst
        System.out.println(strings.stream()
                .findFirst());// 返回Option对象  Optional[abc]
        System.out.println(strings.stream()
                .findAny().get());

        // foreach
        strings.stream()
                .forEach(System.out::println);

        // collect
        System.out.println(strings.stream().collect(Collectors.toSet()));
        System.out.println(strings.stream().collect(Collectors.toList()));
        System.out.println(strings.stream()
                .collect(Collectors.toMap(v->v, v->v,(oldvalue, newvalue)->newvalue)));// key value 重复的处理方法

        // reduce
        // 将流中元素反复结合得到一个结果
        System.out.println(strings.stream()
                .reduce((acc, item)->{return acc + item;}));

        // count
        System.out.println(strings.stream()
                .count());

    }

    // 根据字符串获取字符
    public static Stream<Character> getCharacterByString(String str) {
        List<Character> characterList = new ArrayList<>();
        for (Character character : str.toCharArray()) {
            characterList.add(character);
        }
        return characterList.stream();
    }
}

class User {
    private int id;
    private String name;

    public User(int id, String name) {
        this.id = id;
        this.name = name;
    }

    public User() {
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", name='" + name + '\'' +
                '}';
    }
}
```
