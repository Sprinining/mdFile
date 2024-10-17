---
title: Animation
date: 2022-03-21 03:35:24 +0800
categories: [android, ui]
tags: [Android, UI, Animation]
description: 
---
# 动画

## 帧动画

- 在drawable文件夹下添加图片，并新建frame.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<animation-list xmlns:android="http://schemas.android.com/apk/res/android">

    <item android:drawable="@drawable/frame1" android:duration="120"/>
    <item android:drawable="@drawable/frame2" android:duration="120"/>
    <item android:drawable="@drawable/frame3" android:duration="120"/>
    <item android:drawable="@drawable/frame4" android:duration="120"/>
    <item android:drawable="@drawable/frame5" android:duration="120"/>
    <item android:drawable="@drawable/frame6" android:duration="120"/>

</animation-list>
```

- activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout android:layout_height="match_parent"
    android:layout_width="match_parent"
    android:background="@drawable/frame"
    android:id="@+id/rl"
    xmlns:android="http://schemas.android.com/apk/res/android">
</RelativeLayout>
```

- MainActivity.java

```java
package com.example.myanim1;

import androidx.appcompat.app.AppCompatActivity;

import android.graphics.drawable.AnimationDrawable;
import android.os.Bundle;
import android.view.View;
import android.widget.RelativeLayout;

public class MainActivity extends AppCompatActivity {

    private boolean flag = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        RelativeLayout relativeLayout = findViewById(R.id.rl);

        AnimationDrawable anim = (AnimationDrawable) relativeLayout.getBackground();
        relativeLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if(flag){
                    anim.start();
                    flag = false;
                }else {
                    anim.stop();
                    flag = true;
                }
            }
        });
    }
}
```

## 补间动画

- 在res文件夹下新建anim
- activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout android:layout_height="match_parent"
    android:layout_width="match_parent"
    xmlns:android="http://schemas.android.com/apk/res/android">

    <ImageView
        android:id="@+id/iv"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:maxWidth="300dp"
        android:maxHeight="300dp"
        android:layout_centerInParent="true"
        android:adjustViewBounds="true"
        android:src="@drawable/pic"/>

</RelativeLayout>
```

- MainActivity.java

```java
package com.example.myanim2;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.ImageView;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        ImageView imageView = findViewById(R.id.iv);
        imageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                // 加载xml动画设置文件创建一个animation对象
//                Animation animation = AnimationUtils.loadAnimation(MainActivity.this, R.anim.alpha);
//                Animation animation = AnimationUtils.loadAnimation(MainActivity.this, R.anim.rotate);
//                Animation animation = AnimationUtils.loadAnimation(MainActivity.this, R.anim.scale);
                Animation animation = AnimationUtils.loadAnimation(MainActivity.this, R.anim.translate);

                imageView.startAnimation(animation);
            }
        });
    }
}
```

### 透明度

```xml
<?xml version="1.0" encoding="utf-8"?>
<set xmlns:android="http://schemas.android.com/apk/res/android">
    <alpha android:fromAlpha="0"
        android:toAlpha="1"
        android:duration="2000"/>
</set>
```

### 旋转

```xml
<?xml version="1.0" encoding="utf-8"?>
<set xmlns:android="http://schemas.android.com/apk/res/android">
    <rotate android:fromDegrees="0"
        android:toDegrees="360"
        android:pivotX="50%"
        android:pivotY="50%"
        android:duration="2000"/>
</set>
```

### 缩放

```xml
<?xml version="1.0" encoding="utf-8"?>
<set xmlns:android="http://schemas.android.com/apk/res/android">
    <scale android:fromXScale="1"
        android:fromYScale="1"
        android:toXScale="0.5"
        android:toYScale="0.5"
        android:pivotX="50%"
        android:pivotY="50%"
        android:duration="2000"/>
</set>
```

### 平移

```xml
<?xml version="1.0" encoding="utf-8"?>
<set xmlns:android="http://schemas.android.com/apk/res/android">
    <translate android:fromXDelta="0"
        android:fromYDelta="0"
        android:toXDelta="200"
        android:toYDelta="200"
        android:duration="2000"/>
</set>
```

## 属性动画

```java
package com.example.myanim3;

import androidx.appcompat.app.AppCompatActivity;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        ValueAnimator animator = ValueAnimator.ofFloat(0f, 1f);
        animator.setDuration(2000);
        animator.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
            @Override
            public void onAnimationUpdate(ValueAnimator valueAnimator) {
                float value = (float) valueAnimator.getAnimatedValue();
                Log.e("xxx", String.valueOf(value));
            }
        });
        animator.start();

        // 透明度变化
        TextView textView = findViewById(R.id.tv);
        ObjectAnimator objectAnimator = ObjectAnimator.ofFloat(textView, "alpha", 0f, 1f);
        objectAnimator.setDuration(4000);
        objectAnimator.start();

        // 监听器
        objectAnimator.addListener(new Animator.AnimatorListener() {
            @Override
            public void onAnimationStart(Animator animator) {

            }

            @Override
            public void onAnimationEnd(Animator animator) {

            }

            @Override
            public void onAnimationCancel(Animator animator) {

            }

            @Override
            public void onAnimationRepeat(Animator animator) {

            }
        });

        objectAnimator.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationStart(Animator animation) {
                super.onAnimationStart(animation);
            }
        });
    }
}
```

