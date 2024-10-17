---
title: DataBinding
date: 2022-03-21 03:35:24 +0800
categories: [android, jetpack]
tags: [Android, Jetpack, DataBinding]
description: 
---
# DataBinding

- 添加依赖

```xml
implementation 'androidx.lifecycle:lifecycle-extensions:2.2.0'
```

- 不用再 findViewById 了;

  减少了 Avtivity和Fragment的逻辑处理，使Activity 和Fragment逻辑更加清晰，容易维护;

  提高性能，避免内存泄漏 以及 空指针;

  双向绑定，当View改变的时候会通知Model，当Model改变的时候会通知View

- ==binding.setLifecycleOwner(this)==，要将LiveData对象与绑定类一起使用，需要指定生命周期所有者来定义LiveData对象的范围。必须在绑定类实例化后将Activity指定为生命周期所有者。否者livedata改变不会刷新界面

- build.gradle->android->defaultConfig中添加

```xml
dataBinding{
    enabled true
}
```

- activity_main.xml==点黄色灯泡改成databinding风格==

```xml
<?xml version="1.0" encoding="utf-8"?>
<layout xmlns:android="http://schemas.android.com/apk/res/android">

    <data>
        <variable
            name="data"
            type="com.example.mydatabinding.MyViewModel" />
    </data>

    <LinearLayout
        android:layout_height="match_parent"
        android:layout_width="match_parent"
        android:orientation="vertical">

        <TextView
            android:id="@+id/tv"
            android:text="@{String.valueOf(data.number)}"
            android:layout_width="match_parent"
            android:layout_height="wrap_content" />

        <Button
            android:id="@+id/btn"
            android:text="按钮"
            android:onClick="@{()->data.add()}"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content" />

    </LinearLayout>
</layout>
```

- MyViewModel.java

```java
package com.example.mydatabinding;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

public class MyViewModel extends ViewModel {
    private MutableLiveData<Integer> number;

    public MutableLiveData<Integer> getNumber(){
        if(number == null){
            number = new MutableLiveData<>();
            number.setValue(0);
        }
        return number;
    }

    public void add(){
        number.setValue(number.getValue() + 1);
    }
}
```

- MainActivity.java

```java
package com.example.mydatabinding;

import androidx.appcompat.app.AppCompatActivity;
import androidx.databinding.DataBindingUtil;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModelProvider;
import androidx.lifecycle.ViewModelProviders;

import android.os.Bundle;


import com.example.mydatabinding.databinding.ActivityMainBinding;
import com.example.mydatabinding.databinding.MyLayoutBinding;

import java.util.concurrent.TimeUnit;

public class MainActivity extends AppCompatActivity {

    MyViewModel myViewModel;
    User user;
    ActivityMainBinding binding;
    MyLayoutBinding myLayoutBinding; // 此类名根据xml文件名生成

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

//        binding = DataBindingUtil.setContentView(this, R.layout.activity_main);
//        myViewModel = new ViewModelProvider(this).get(MyViewModel.class);
//        binding.setData(myViewModel);
//        binding.setLifecycleOwner(this);

        myLayoutBinding = DataBindingUtil.setContentView(this, R.layout.my_layout);
        user = new User("哈哈", new MutableLiveData<>(0));
        myLayoutBinding.setUser(user); // 此方法名是根据xml里name="user"生成

        /**
         * 下面这句话如果注释掉，只有name会刷新，liveData类型的age不会；
         * 要将LiveData对象与绑定类binding一起使用，需要指定生命周期所有者来定义LiveData对象的范围。
         * 必须在绑定类实例化后将Activity指定为生命周期所有者。
         */
        myLayoutBinding.setLifecycleOwner(this);

        new Thread(() -> {
            for (int i = 0; i < 10; i++) {
                try {
                    TimeUnit.SECONDS.sleep(1);
                    user.setName("" + i); // 修改数据，页面会自动刷新
                    user.getAge().postValue(i); // setValue()只能用在主线程
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }, "A").start();
    }
}
```

- User.java

```java
package com.example.mydatabinding;

import androidx.databinding.BaseObservable;
import androidx.databinding.Bindable;
import androidx.lifecycle.MutableLiveData;

public class User extends BaseObservable {
    private String name;
    private MutableLiveData<Integer> age;

    public User(String name, MutableLiveData<Integer> age) {
        this.name = name;
        this.age = age;
    }

    public MutableLiveData<Integer> getAge() {
        if (age == null){
            age = new MutableLiveData<>();
            age.setValue(0);
        }
        return age;
    }

    @Bindable
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
        notifyPropertyChanged(BR.name);
    }
}
```

- my_layout.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<layout xmlns:android="http://schemas.android.com/apk/res/android">

    <data>
        <variable
            name="user"
            type="com.example.mydatabinding.User" />

    </data>

    <LinearLayout
        android:layout_height="match_parent"
        android:layout_width="match_parent"
        android:orientation="vertical">

        <TextView
            android:text="@{user.name}"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content" />

        <TextView
            android:text="@{String.valueOf(user.age)}"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content" />

    </LinearLayout>
</layout>
```

## 积分器

- activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<layout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools">

    <data>
        <variable
            name="data"
            type="com.example.myscore.MyViewModel" />

    </data>

    <androidx.constraintlayout.widget.ConstraintLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        tools:context=".MainActivity">

        <androidx.constraintlayout.widget.Guideline
            android:id="@+id/guideline2"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            app:layout_constraintGuide_percent="0.50121653" />

        <androidx.constraintlayout.widget.Guideline
            android:id="@+id/guideline3"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            app:layout_constraintGuide_percent="0.15" />

        <androidx.constraintlayout.widget.Guideline
            android:id="@+id/guideline4"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            app:layout_constraintGuide_percent="0.45" />

        <androidx.constraintlayout.widget.Guideline
            android:id="@+id/guideline5"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            app:layout_constraintGuide_percent="0.75" />

        <androidx.constraintlayout.widget.Guideline
            android:id="@+id/guideline6"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            app:layout_constraintGuide_percent="0.051983584" />

        <androidx.constraintlayout.widget.Guideline
            android:id="@+id/guideline7"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            app:layout_constraintGuide_percent="0.2995896" />

        <androidx.constraintlayout.widget.Guideline
            android:id="@+id/guideline8"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            app:layout_constraintGuide_percent="0.6" />

        <androidx.constraintlayout.widget.Guideline
            android:id="@+id/guideline9"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            app:layout_constraintGuide_percent="0.9" />

        <TextView
            android:id="@+id/textView1"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/teama"
            android:textSize="@dimen/teamTextSize"
            app:layout_constraintBottom_toTopOf="@+id/guideline3"
            app:layout_constraintEnd_toStartOf="@+id/guideline2"
            app:layout_constraintStart_toStartOf="parent"
            app:layout_constraintTop_toTopOf="@+id/guideline6" />

        <TextView
            android:id="@+id/textView2"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/teamb"
            android:textSize="@dimen/teamTextSize"
            app:layout_constraintBottom_toTopOf="@+id/guideline3"
            app:layout_constraintEnd_toEndOf="parent"
            app:layout_constraintStart_toStartOf="@+id/guideline2"
            app:layout_constraintTop_toTopOf="@+id/guideline6" />

        <TextView
            android:id="@+id/textView4"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@{String.valueOf(data.getaTeamScore())}"
            android:textColor="#F44336"
            android:textSize="@dimen/scoreTextSize"
            app:layout_constraintBottom_toTopOf="@+id/guideline7"
            app:layout_constraintEnd_toStartOf="@+id/guideline2"
            app:layout_constraintStart_toStartOf="parent"
            app:layout_constraintTop_toTopOf="@+id/guideline3"
            tools:text="120" />

        <TextView
            android:id="@+id/textView5"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@{String.valueOf(data.getbTeamScore())}"
            android:textColor="#4CAF50"
            android:textSize="@dimen/scoreTextSize"
            app:layout_constraintBottom_toTopOf="@+id/guideline7"
            app:layout_constraintEnd_toEndOf="parent"
            app:layout_constraintStart_toStartOf="@+id/guideline2"
            app:layout_constraintTop_toTopOf="@+id/guideline3"
            tools:text="100" />

        <Button
            android:id="@+id/btn1"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:background="#F44336"
            android:text="@string/add1"
            android:textColor="#F3EEEE"
            android:textSize="@dimen/btntextsize"
            android:onClick="@{()->data.aTeamAdd(1)}"
            app:layout_constraintBottom_toTopOf="@+id/guideline4"
            app:layout_constraintEnd_toStartOf="@+id/guideline2"
            app:layout_constraintStart_toStartOf="@+id/guideline11"
            app:layout_constraintTop_toTopOf="@+id/guideline7" />

        <androidx.constraintlayout.widget.Guideline
            android:id="@+id/guideline10"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            app:layout_constraintGuide_percent="0.94" />

        <androidx.constraintlayout.widget.Guideline
            android:id="@+id/guideline11"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            app:layout_constraintGuide_percent="0.06" />

        <Button
            android:id="@+id/btn2"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:background="#4CAF50"
            android:text="@string/add1"
            android:textColor="#F3EEEE"
            android:textSize="@dimen/btntextsize"
            android:onClick="@{()->data.bTeamAdd(1)}"
            app:layout_constraintBottom_toTopOf="@+id/guideline4"
            app:layout_constraintEnd_toStartOf="@+id/guideline10"
            app:layout_constraintStart_toStartOf="@+id/guideline2"
            app:layout_constraintTop_toTopOf="@+id/guideline7"
            tools:ignore="TextContrastCheck" />

        <Button
            android:id="@+id/btn3"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:background="#F44336"
            android:text="@string/add2"
            android:textColor="#F3EEEE"
            android:textSize="@dimen/btntextsize"
            android:onClick="@{()->data.aTeamAdd(2)}"
            app:layout_constraintBottom_toTopOf="@+id/guideline8"
            app:layout_constraintEnd_toStartOf="@+id/guideline2"
            app:layout_constraintStart_toStartOf="@+id/guideline11"
            app:layout_constraintTop_toTopOf="@+id/guideline4" />

        <Button
            android:id="@+id/btn4"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:background="#4CAF50"
            android:text="@string/add2"
            android:textColor="#F3EEEE"
            android:textSize="@dimen/btntextsize"
            android:onClick="@{()->data.bTeamAdd(2)}"
            app:layout_constraintBottom_toTopOf="@+id/guideline8"
            app:layout_constraintEnd_toStartOf="@+id/guideline10"
            app:layout_constraintStart_toStartOf="@+id/guideline2"
            app:layout_constraintTop_toTopOf="@+id/guideline4"
            tools:ignore="TextContrastCheck" />

        <Button
            android:id="@+id/btn5"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:background="#F44336"
            android:text="@string/add3"
            android:textColor="#F3EEEE"
            android:textSize="@dimen/btntextsize"
            android:onClick="@{()->data.aTeamAdd(3)}"
            app:layout_constraintBottom_toTopOf="@+id/guideline5"
            app:layout_constraintEnd_toStartOf="@+id/guideline2"
            app:layout_constraintStart_toStartOf="@+id/guideline11"
            app:layout_constraintTop_toTopOf="@+id/guideline8" />

        <Button
            android:id="@+id/btn6"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:background="#4CAF50"
            android:text="@string/add3"
            android:textColor="#F3EEEE"
            android:textSize="@dimen/btntextsize"
            android:onClick="@{()->data.bTeamAdd(3)}"
            app:layout_constraintBottom_toTopOf="@+id/guideline5"
            app:layout_constraintEnd_toStartOf="@+id/guideline10"
            app:layout_constraintStart_toStartOf="@+id/guideline2"
            app:layout_constraintTop_toTopOf="@+id/guideline8"
            tools:ignore="TextContrastCheck" />

        <ImageButton
            android:id="@+id/ib_undo"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:minHeight="48dp"
            android:onClick="@{()->data.undo()}"
            app:layout_constraintBottom_toTopOf="@+id/guideline9"
            app:layout_constraintEnd_toStartOf="@+id/guideline2"
            app:layout_constraintStart_toStartOf="@+id/guideline11"
            app:layout_constraintTop_toTopOf="@+id/guideline5"
            app:srcCompat="@drawable/ic_baseline_undo_24"
            tools:ignore="SpeakableTextPresentCheck" />

        <ImageButton
            android:id="@+id/ib_reset"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:minHeight="48dp"
            android:onClick="@{()->data.reset()}"
            app:layout_constraintBottom_toTopOf="@+id/guideline9"
            app:layout_constraintEnd_toStartOf="@+id/guideline10"
            app:layout_constraintStart_toStartOf="@+id/guideline2"
            app:layout_constraintTop_toTopOf="@+id/guideline5"
            app:srcCompat="@drawable/ic_baseline_loop_24"
            tools:ignore="SpeakableTextPresentCheck" />

    </androidx.constraintlayout.widget.ConstraintLayout>
</layout>
```

- MyViewModel.java

```java
package com.example.myscore;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

public class MyViewModel extends ViewModel {
    private MutableLiveData<Integer> aTeamScore;
    private MutableLiveData<Integer> bTeamScore;
    private int aBack, bBack;

    public MutableLiveData<Integer> getaTeamScore() {
        if(aTeamScore == null){
            aTeamScore = new MutableLiveData<>();
            aTeamScore.setValue(0);
        }
        return aTeamScore;
    }

    public MutableLiveData<Integer> getbTeamScore() {
        if(bTeamScore == null){
            bTeamScore = new MutableLiveData<>();
            bTeamScore.setValue(0);
        }
        return bTeamScore;
    }

    public void aTeamAdd(int n){
        aBack = aTeamScore.getValue();
        bBack = bTeamScore.getValue();
        aTeamScore.setValue(aTeamScore.getValue() + n);
    }

    public void bTeamAdd(int n){
        aBack = aTeamScore.getValue();
        bBack = bTeamScore.getValue();
        bTeamScore.setValue(bTeamScore.getValue() + n);
    }

    public void reset(){
        aBack = aTeamScore.getValue();
        bBack = bTeamScore.getValue();
        aTeamScore.setValue(0);
        bTeamScore.setValue(0);
    }

    public void undo(){
        aTeamScore.setValue(aBack);
        bTeamScore.setValue(bBack);
    }
}
```

- MainActivity.java

```java
package com.example.myscore;

import androidx.appcompat.app.AppCompatActivity;
import androidx.databinding.DataBindingUtil;
import androidx.lifecycle.ViewModelProviders;
import android.os.Bundle;
import com.example.myscore.databinding.ActivityMainBinding;

public class MainActivity extends AppCompatActivity {

    MyViewModel myViewModel;
    ActivityMainBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        binding = DataBindingUtil.setContentView(this, R.layout.activity_main);
        myViewModel = new ViewModelProvider(this).get(MyViewModel.class);
        binding.setData(myViewModel);
        binding.setLifecycleOwner(this);
    }
}
```

