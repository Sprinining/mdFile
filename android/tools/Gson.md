---
title: Gson
date: 2022-03-21 03:35:24 +0800
categories: [android, tools]
tags: [Android, Gson]
description: 
---
# Gson

- 添加依赖： implementation 'com.google.code.gson:gson:2.8.6'

## 对象的序列化与反序列化

```java
User user = new User("xxx", "666", 24, false);
Job teacher = new Job("teacher", 10000);
user.setJob(teacher);

Gson gson = new Gson();

// 序列化
String json = gson.toJson(user);
System.out.println(json);

// 反序列化
User user1 = gson.fromJson(json, User.class);
System.out.println(user1.getJob().getName());
```

## Array的序列化

- User[] users1 = gson.fromJson(json, ==User[].class==);

```java
User[] users = new User[3];
users[0] = new User("xxx", "666", 24, false);
users[0].setJob(teacher);
users[2] = new User("xxx", "666", 24, false);
users[2].setJob(new Job());

json = gson.toJson(users);
Log.d("xxx", "onCreate: " + json);

User[] users1 = gson.fromJson(json, User[].class);
Log.d("xxx", "onCreate: " + users1[0].getJob().getSalary());
```

## List的序列化

- ==Type type = new TypeToken<List<User>>(){}.getType();==

```java
List<User> list = new ArrayList<>();
list.add(users[0]);
list.add(users[1]);
list.add(users[2]);

// 序列化
json = gson.toJson(list);
Log.d("xxx", "onCreate: " + json);

// 反序列化
Type type = new TypeToken<List<User>>(){}.getType();
List<User> list1 = gson.fromJson(json, type);
Log.d("xxx", "onCreate: " + list1.get(0).getJob().getSalary());
```

## Map的序列化

```java
Map<String, User> map = new HashMap<>();
map.put("1", users[0]);
map.put("2", users[1]);
map.put("3", users[2]);
map.put(null, null);

json = gson.toJson(map);
Log.d("xxx", "onCreate: " + json);

Type type = new TypeToken<Map<String, User>>(){}.getType();
Map<String, User> map1 = gson.fromJson(json, type);
Log.d("xxx", "onCreate: " + map1.get("1").getJob().getSalary());
```

## Set的序列化

```java
Set<User> set = new HashSet<>();
set.add(users[0]);
set.add(users[1]);
set.add(users[2]);

json = gson.toJson(set);
Log.d("xxx", "onCreate: " + json);

Type type = new TypeToken<List<User>>(){}.getType();
List<User> list = gson.fromJson(json, type);
Log.d("xxx", "onCreate: " + list.get(1).getJob().getSalary());

Type type1 = new TypeToken<Set<User>>(){}.getType();
Set<User> set1 = gson.fromJson(json, type1);
Iterator<User> iterator = set1.iterator();
while (iterator.hasNext()){
    User next = iterator.next();
    Log.d("xxx", "onCreate: " + next);
}
```

## 值为null的序列化

- 集合里有数据为null，gson不忽略
- 对象的属性为null，会被忽略

## 控制序列化反序列化变量名称

- 控制json中key的命名

```java
@SerializedName("class")
private int cls;
```

- @Expose注解

```
// 一旦使用这个注解，其他没使用这个注解的成员都不参加
@Expose(serialize = false, deserialize = false)
private String password;
```

- transient关键字

```java
// 不参加序列化和反序列化
private transient int age;
```

