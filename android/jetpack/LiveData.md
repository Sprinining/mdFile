---
title: LiveData
date: 2022-03-21 03:35:24 +0800
categories: [android, jetpack]
tags: [Android, Jetpack, LiveData]
description: 
---
# LiveData

是一种可观察的数据存储器类。与常规的可观察类不同，LiveData 具有生命周期感知能力，意指它遵循其他应用组件（如 Activity、Fragment 或 Service）的生命周期。这种感知能力可确保 LiveData 仅更新处于活跃生命周期状态的应用组件观察者。

## 生命周期感知型组件的最佳做法

- 使界面控制器（Activity 和 Fragment）尽可能保持精简。它们==不应试图获取自己的数据，而应使用 ViewModel 执行此操作==，并==观察 LiveData 对象以将更改体现到视图中==。
- 设法编写数据驱动型界面，对于此类界面，界面控制器的责任是随着数据更改而更新视图，或者将用户操作通知给 ViewModel。
- 将数据逻辑放在 ViewModel类中。ViewModel==应充当界面控制器与应用其余部分之间的连接器==。不过要注意，==ViewModel 不负责获取数据==（例如，从网络获取）。但是，ViewModel 应调用相应的组件来获取数据，然后将结果提供给界面控制器。
- 使用数据绑定在视图与界面控制器之间维持干净的接口。这样一来，您可以使视图更具声明性，并==尽量减少需要在 Activity 和 Fragment 中编写的更新代码==。如果您更愿意使用 Java 编程语言执行此操作，请使用诸如 Butter Knife 之类的库，以避免样板代码并实现更好的抽象化。
- 如果界面很复杂，不妨考虑创建 presenter 类来处理界面的修改。这可能是一项艰巨的任务，但这样做可使界面组件更易于测试。
- ==避免在 ViewModel 中引用 View 或 Activity 上下文==。如果 ViewModel 存在的时间比 activity 更长（在配置更改的情况下），activity 将泄露并且不会得到垃圾回收器的妥善处置。

## LiveData与ViewModel

- **LiveData** 是一个可以感知 Activity 、Fragment生命周期的数据容器。当 LiveData 所持有的数据改变时，它会通知相应的界面代码进行更新。同时，LiveData 持有界面代码 Lifecycle 的引用，这意味着它会在界面代码（LifecycleOwner）的生命周期处于 started 或 resumed 时作出相应更新，而在 LifecycleOwner 被销毁时停止更新。不用手动控制生命周期，不用担心内存泄露，数据变化时会收到通知。

- **ViewModel** 将视图的数据和逻辑从具有生命周期特性的实体（如 Activity 和 Fragment）中剥离开来。直到关联的 Activity 或 Fragment 完全销毁时，ViewModel 才会随之消失，也就是说，即使在旋转屏幕导致 Fragment 被重新创建等事件中，视图数据依旧会被保留。ViewModels 不仅消除了常见的生命周期问题，而且可以帮助构建更为模块化、更方便测试的用户界面。ViewModel的优点也很明显，为Activity 、Fragment存储数据，直到完全销毁。尤其是屏幕旋转的场景，常用的方法都是通过onSaveInstanceState()保存数据，再在onCreate()中恢复。

- ViewModel存储了数据，所以ViewModel可以在当前Activity的Fragment中实现**数据共享**。

## ViewModel生命周期

  ![viewmodel-lifecycle](./LiveData.assets/viewmodel-lifecycle.png)

## 实现

- 添加依赖

```xml
implementation 'androidx.lifecycle:lifecycle-extensions:2.2.0'
```

- activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context=".MainActivity">

    <TextView
        android:id="@+id/tv"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Hello World!"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <ImageButton
        android:id="@+id/ib1"
        android:layout_width="48dp"
        android:layout_height="48dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintHorizontal_bias="0.168"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:srcCompat="@drawable/ic_baseline_thumb_up_24"
        tools:ignore="SpeakableTextPresentCheck" />

    <ImageButton
        android:id="@+id/ib2"
        android:layout_width="48dp"
        android:layout_height="48dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintHorizontal_bias="0.84"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:srcCompat="@drawable/ic_baseline_thumb_down_24"
        tools:ignore="SpeakableTextPresentCheck" />

</androidx.constraintlayout.widget.ConstraintLayout>
```

- ViewModelWithLiveData.java

```java
package com.example.mylivedata;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

public class ViewModelWithLiveData extends ViewModel {

    private MutableLiveData<Integer> LikedNumber;

    public MutableLiveData<Integer> getLikedNumber() {
        if(LikedNumber == null){
            LikedNumber = new MutableLiveData<>();
            LikedNumber.setValue(0);
        }
        return LikedNumber;
    }

    public void addLikedNumber(int n){
        LikedNumber.setValue(LikedNumber.getValue() + n);
    }
}
```

- MainActivity.java

```java
package com.example.mylivedata;

import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleObserver;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.Observer;
import androidx.lifecycle.OnLifecycleEvent;
import androidx.lifecycle.ViewModelProvider;
import androidx.lifecycle.ViewModelProviders;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageButton;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {

    ImageButton ib_like, ib_dislike;
    TextView tv;
    ViewModelWithLiveData viewModelWithLiveData;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // 添加观察者
        getLifecycle().addObserver(new MyObserver());

        ib_like = findViewById(R.id.ib1);
        ib_dislike = findViewById(R.id.ib2);
        tv = findViewById(R.id.tv);

        // 参数1：LifeCycleOwner表示此类具有lifecycle，MainActivity -> AppCompatActivity -> FragmentActivity -> ComponentActivity implements LifecycleOwner
        viewModelWithLiveData = new ViewModelProvider(this).get(ViewModelWithLiveData.class);
        viewModelWithLiveData.getLikedNumber().observe(this, new Observer<Integer>() {
            @Override
            public void onChanged(Integer integer) {
                tv.setText(String.valueOf(integer));
            }
        });

        ib_like.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                viewModelWithLiveData.addLikedNumber(1);
            }
        });

        ib_dislike.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                viewModelWithLiveData.addLikedNumber(-1);
            }
        });
    }

    // 自定义观察者
    static class MyObserver implements LifecycleObserver {
        @OnLifecycleEvent(Lifecycle.Event.ON_RESUME)
        public void fun(){
            Log.d("xxx", "fun: ");
        }
    }
}
```

