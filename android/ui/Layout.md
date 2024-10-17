---
title: Layout
date: 2022-03-21 03:35:24 +0800
categories: [android, ui]
tags: [Android, UI, Layout]
description: 
---
# LinearLayout

- layout_gravity：组件在父容器里的对齐方式
- gravity：组件包含的所有子元素的对齐方式
- layout_weight：在原有基础上分配剩余空间，一般把layout_height都设置为0dp再使用此属性
- 设置分割线可以用divider属性，或者插入View

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout android:layout_height="match_parent"
    android:layout_width="match_parent"
    android:orientation="vertical"
    android:gravity="center_horizontal|bottom"
    android:divider="@drawable/ic_baseline_horizontal_rule_24"
    android:showDividers="middle"
    android:dividerPadding="20dp"
    xmlns:android="http://schemas.android.com/apk/res/android">

    <View android:layout_height="1dp"
        android:layout_width="match_parent"
        android:background="#ff0000"/>

    <LinearLayout android:layout_height="100dp"
        android:layout_gravity="left"
        android:layout_width="100dp"
        android:background="#ff0000"/>

    <LinearLayout android:layout_height="100dp"
        android:layout_width="100dp"
        android:background="#00ff00"/>

    <LinearLayout android:layout_height="100dp"
        android:layout_width="100dp"
        android:background="#0000ff"/>

</LinearLayout>
```

# RelativeLayout

- 可以根据父容器定位，也可以根据兄弟组件定位
- margin设置组件与父容器的边距
- padding设置组件内部元素的边距

```xml
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout android:layout_height="match_parent"
    android:layout_width="match_parent"
    android:padding="10dp"
    xmlns:android="http://schemas.android.com/apk/res/android">

    <RelativeLayout
        android:id="@+id/lt1"
        android:layout_width="100dp"
        android:layout_height="100dp"
        android:layout_centerInParent="true"
        android:background="#ff0000"/>

    <RelativeLayout
        android:layout_width="100dp"
        android:layout_height="100dp"
        android:layout_above="@id/lt1"
        android:layout_margin="100dp"
        android:background="#00ff00"/>

</RelativeLayout>
```

# FrameLayout

```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout android:layout_height="match_parent"
    android:layout_width="match_parent"
    xmlns:android="http://schemas.android.com/apk/res/android">

    <FrameLayout android:layout_height="300dp"
        android:layout_width="300dp"
        android:background="#ff0000"/>

    <FrameLayout android:layout_height="200dp"
        android:layout_width="200dp"
        android:foreground="@drawable/ic_baseline_language_24"
        android:foregroundGravity="right|bottom"
        android:background="#0000ff"/>

    <FrameLayout android:layout_height="100dp"
        android:layout_width="100dp"
        android:background="#00ff00"/>


</FrameLayout>
```

# TableLayout

- collapseColumns：隐藏列，从0开始

- stretchColumns：有剩余空间才会拉伸

```xml
android:collapseColumns="1,3"
android:stretchColumns="2"
```

- shrinkColumns：有挤压的时候才能收缩
- layout_column：显示在第几列
- layout_span：横向跨几列

```xml
<?xml version="1.0" encoding="utf-8"?>
<TableLayout android:layout_height="match_parent"
    android:layout_width="match_parent"
    android:shrinkColumns="2"
    xmlns:android="http://schemas.android.com/apk/res/android">

    <TableRow>
        <Button android:layout_height="wrap_content"
            android:layout_width="wrap_content"
            android:layout_span="2"
            android:text="按钮0"/>

        <Button android:layout_height="wrap_content"
            android:layout_width="wrap_content"
            android:layout_column="3"
            android:text="按钮1"/>
    </TableRow>

    <TableRow>
        <Button android:layout_height="wrap_content"
            android:layout_width="wrap_content"
            android:text="按钮0"/>

        <Button android:layout_height="wrap_content"
            android:layout_width="wrap_content"
            android:text="按钮1"/>

        <Button android:layout_height="wrap_content"
            android:layout_width="wrap_content"
            android:text="按钮2"/>

        <Button android:layout_height="wrap_content"
            android:layout_width="wrap_content"
            android:text="按钮3"/>

        <Button android:layout_height="wrap_content"
            android:layout_width="wrap_content"
            android:text="按钮4"/>
    </TableRow>

    <Button android:layout_height="wrap_content"
        android:layout_width="wrap_content"
        android:text="按钮0"/>

    <Button android:layout_height="wrap_content"
        android:layout_width="wrap_content"
        android:text="按钮1"/>

</TableLayout>
```

# GridLayout

- columnCount、rowCount：最大行列数，与orientation配合使用
- layout_row、layout_column：显示所在行列
- layout_columnWeight：横向剩余空间分配方式
- layout_columnSpan：横向跨列，配合layout_gravity使用

```xml
<?xml version="1.0" encoding="utf-8"?>
<GridLayout android:layout_height="match_parent"
    android:layout_width="match_parent"
    xmlns:android="http://schemas.android.com/apk/res/android">

    <Button android:layout_height="wrap_content"
        android:layout_width="wrap_content"
        android:text="按钮0"/>

    <Button android:layout_height="wrap_content"
        android:layout_width="wrap_content"
        android:layout_row="1"
        android:layout_column="0"
        android:layout_columnSpan="3"
        android:layout_gravity="fill"
        android:text="按钮1"/>

    <Button android:layout_height="wrap_content"
        android:layout_width="wrap_content"
        android:layout_row="0"
        android:layout_column="1"
        android:text="按钮2"/>

    <Button android:layout_height="wrap_content"
        android:layout_width="wrap_content"
        android:layout_columnWeight="1"
        android:layout_rowWeight="1"
        android:text="按钮3"/>

    <Button android:layout_height="wrap_content"
        android:layout_width="wrap_content"
        android:text="按钮4"/>
</GridLayout>
```

# ConstraintLayout

......

# 自定义布局

- 创建一个标题布局title.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout android:layout_height="wrap_content"
    android:layout_width="match_parent"
    android:orientation="horizontal"
    android:background="#FFFF00"
    xmlns:android="http://schemas.android.com/apk/res/android">
    <Button
        android:id="@+id/btn_left"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="返回"/>

    <TextView
        android:text="标题"
        android:layout_gravity="center"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:gravity="center"/>
    <Button
        android:id="@+id/btn_right"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="菜单"/>
</LinearLayout>
```

- 在onCreate()中关闭自带的标题栏

```java
// 隐藏标题栏，使用自定义的
ActionBar actionBar = getSupportActionBar();
if (actionBar != null){
    actionBar.hide();
}
```

- 在activity_main.xml中引用布局文件

```xml
<include layout="@layout/title"/>
```
# 自定义控件
- 也可以用控件的方式使用，TitleLayout.java


```java
package com.example.myalterdialog;

import android.content.Context;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.annotation.Nullable;

public class TitleLayout extends LinearLayout {
    public TitleLayout(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);

        LayoutInflater.from(context) // 构建出一个LayoutInflater对象
                .inflate(R.layout.title, this); // 第二个参数是给加载好的布局添加一个父布局
        findViewById(R.id.btn_left).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                Toast.makeText(context, "返回", Toast.LENGTH_SHORT).show();
            }
        });
        findViewById(R.id.btn_right).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                Toast.makeText(context, "菜单", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
```

- activity_main.xml中使用自定义控件

```xml
<com.example.myalterdialog.TitleLayout
    android:layout_width="match_parent"
    android:layout_height="wrap_content"/>
```





