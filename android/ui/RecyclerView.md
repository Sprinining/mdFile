---
title: RecyclerView
date: 2022-03-21 03:35:24 +0800
categories: [android, ui]
tags: [Android, UI, RecyclerView]
description: 
---
# RecyclerView刷新方式

## 刷新全部item

- notifyDataSetChanged()  

```java
student.setValue(new Student("二狗"));
studentList.add(student.getValue());
myRecyclerViewAdapter.notifyDataSetChanged();
```

## 刷新指定item

- notifyItemChanged(int)

```java
studentList.get(1).setName("铁蛋");
myRecyclerViewAdapter.notifyItemChanged(1);
```

## 从指定位置开始刷新指定个数的item

- notifyItemRangeChanged(int,int)

```java
Student s = new Student("二狗");
studentList.add(1, s);
myRecyclerViewAdapter.notifyItemInserted(1);
myRecyclerViewAdapter.notifyItemRangeChanged(1, studentList.size() + 1);
```

## 插入、移动指定位置的item并刷新

- notifyItemInserted(int)、notifyItemMoved(int)、notifyItemRemoved(int)

```java
// 先移下标大的
Student s2 = studentList.remove(4);
Student s1 = studentList.remove(1);
// 先添加下标小的
studentList.add(1, s2);
studentList.add(4, s1);
// 带动画的移动
myRecyclerViewAdapter.notifyItemMoved(4,1);
// 受到影响的item都要刷新
myRecyclerViewAdapter.notifyItemRangeChanged(1,4);
```

## 局部刷新指定item

- notifyItemChanged(int, Object)

```java
Student s = new Student("二狗");
studentList.set(1, s);
myRecyclerViewAdapter.notifyItemChanged(1, s);
```



