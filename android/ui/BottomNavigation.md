---
title: BottomNavigation
date: 2022-03-21 03:35:24 +0800
categories: [android, ui]
tags: [Android, UI, BottomNavigation]
description: 
---
# BottomNavigation

- 导航布局navigation.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<navigation xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:id="@+id/navigation"
    app:startDestination="@id/firstFragment">

    <fragment
        android:id="@+id/firstFragment"
        android:name="com.example.mybottomnavigation.fragment.FirstFragment"
        android:label="旋转"
        tools:layout="@layout/first_fragment" />
    <fragment
        android:id="@+id/thirdFragment"
        android:name="com.example.mybottomnavigation.fragment.ThirdFragment"
        android:label="移动"
        tools:layout="@layout/third_fragment" />
    <fragment
        android:id="@+id/secondFragment"
        android:name="com.example.mybottomnavigation.fragment.SecondFragment"
        android:label="缩放"
        tools:layout="@layout/second_fragment" />
</navigation>
```

- 菜单布局menu.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/firstFragment"
        android:icon="@drawable/ic_baseline_looks_one_24"
        android:title="旋转" />
    <item
        android:id="@+id/secondFragment"
        android:icon="@drawable/ic_baseline_looks_two_24"
        android:title="缩放" />
    <item
        android:id="@+id/thirdFragment"
        android:icon="@drawable/ic_baseline_looks_3_24"
        android:title="移动" />
</menu>
```

- activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context=".activity.MainActivity">

    <fragment
        android:id="@+id/fragment"
        android:name="androidx.navigation.fragment.NavHostFragment"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:defaultNavHost="true"
        app:layout_constraintBottom_toTopOf="@+id/bottomNavigationView"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:navGraph="@navigation/navigation" />

    <com.google.android.material.bottomnavigation.BottomNavigationView
        android:id="@+id/bottomNavigationView"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:menu="@menu/menu" />
</androidx.constraintlayout.widget.ConstraintLayout>
```

- first_fragment.xml（另外两个类似）

```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context=".fragment.FirstFragment">

    <ImageView
        android:id="@+id/imageView1"
        android:layout_width="100dp"
        android:layout_height="100dp"
        android:layout_gravity="center"
        android:src="@drawable/ic_baseline_pedal_bike_24" />
</FrameLayout>
```

- MainActivity.java

```java
package com.example.mybottomnavigation.activity;

import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.navigation.NavController;
import androidx.navigation.Navigation;
import androidx.navigation.ui.AppBarConfiguration;
import androidx.navigation.ui.NavigationUI;

import com.example.mybottomnavigation.R;
import com.google.android.material.bottomnavigation.BottomNavigationView;

public class MainActivity extends AppCompatActivity {



    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        BottomNavigationView bottomNavigationView = findViewById(R.id.bottomNavigationView);
        NavController navController = Navigation.findNavController(this, R.id.fragment);

//        AppBarConfiguration configuration = new AppBarConfiguration.Builder(navController.getGraph()).build(); // 向上按钮会显示
//        AppBarConfiguration configuration = new AppBarConfiguration.Builder(R.id.firstFragment, R.id.secondFragment, R.id.thirdFragment).build();
        AppBarConfiguration configuration = new AppBarConfiguration.Builder(bottomNavigationView.getMenu()).build();
        NavigationUI.setupActionBarWithNavController(this, navController, configuration);
        NavigationUI.setupWithNavController(bottomNavigationView, navController);

    }
}
```

- FirstFragment.java

```java
package com.example.mybottomnavigation.fragment;

import androidx.lifecycle.ViewModelProvider;

import android.animation.ObjectAnimator;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import com.example.mybottomnavigation.viewmodel.FirstViewModel;
import com.example.mybottomnavigation.R;

public class FirstFragment extends Fragment {

    private FirstViewModel mViewModel;
    private View root;
    private ImageView imageView;

    public static FirstFragment newInstance() {
        return new FirstFragment();
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        root = inflater.inflate(R.layout.first_fragment, container, false);
        imageView = root.findViewById(R.id.imageView1);
        return root;
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);

//        mViewModel = new ViewModelProvider(this).get(FirstViewModel.class); // 范围是fragment，切换到别的fragment再回来数据就没了
        mViewModel = new ViewModelProvider(requireActivity()).get(FirstViewModel.class);

        imageView.setRotation(mViewModel.rotationPosition);

        // 属性动画
        ObjectAnimator objectAnimator = ObjectAnimator.ofFloat(imageView, "rotation", 0, 0);
        objectAnimator.setDuration(500);
        imageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!objectAnimator.isRunning()) {
                    objectAnimator.setFloatValues(imageView.getRotation(), imageView.getRotation() + 100);
                    mViewModel.rotationPosition += 100;
                    objectAnimator.start();
                }
            }
        });
    }

}
```

- SecondFragment.java

```java
package com.example.mybottomnavigation.fragment;

import androidx.lifecycle.ViewModelProvider;

import android.animation.AnimatorSet;
import android.animation.ObjectAnimator;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import com.example.mybottomnavigation.R;
import com.example.mybottomnavigation.viewmodel.SecondViewModel;

public class SecondFragment extends Fragment {

    private ImageView imageView;
    private View root;
    private SecondViewModel mViewModel;

    public static SecondFragment newInstance() {
        return new SecondFragment();
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        root = inflater.inflate(R.layout.second_fragment, container, false);
        imageView = root.findViewById(R.id.imageView2);
        return root;
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        mViewModel = new ViewModelProvider(requireActivity()).get(SecondViewModel.class);
        // 初始化
        imageView.setScaleX(mViewModel.scaleFactor);
        imageView.setScaleY(mViewModel.scaleFactor);

        ObjectAnimator objectAnimatorX = ObjectAnimator.ofFloat(imageView, "scaleX", 0);
        ObjectAnimator objectAnimatorY = ObjectAnimator.ofFloat(imageView, "scaleY", 0);
        // 一起操作
        AnimatorSet animatorSet = new AnimatorSet();
        animatorSet.playTogether(objectAnimatorX, objectAnimatorY);
        animatorSet.setDuration(500);
//        objectAnimatorX.setDuration(500);
//        objectAnimatorY.setDuration(500);

        imageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!animatorSet.isRunning()){
                    objectAnimatorX.setFloatValues(imageView.getScaleX() + 0.1f);
                    objectAnimatorY.setFloatValues(imageView.getScaleY() + 0.1f);

                    mViewModel.scaleFactor += 0.1;
                    animatorSet.start();
                }
            }
        });
    }

}
```

- ThirdFragment.java

```java
package com.example.mybottomnavigation.fragment;

import androidx.lifecycle.ViewModelProvider;

import android.animation.ObjectAnimator;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import com.example.mybottomnavigation.R;
import com.example.mybottomnavigation.viewmodel.ThirdViewModel;

import java.util.Random;

public class ThirdFragment extends Fragment {

    private ImageView imageView;
    private View root;
    private ThirdViewModel mViewModel;

    public static ThirdFragment newInstance() {
        return new ThirdFragment();
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        root = inflater.inflate(R.layout.third_fragment, container, false);
        imageView = root.findViewById(R.id.imageView3);
        return root;
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        mViewModel = new ViewModelProvider(requireActivity()).get(ThirdViewModel.class);
        // 初始化
        imageView.setX(mViewModel.dx);

        ObjectAnimator objectAnimator = ObjectAnimator.ofFloat(imageView, "x", 0, 0);
        objectAnimator.setDuration(500);

        imageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!objectAnimator.isRunning()) {
                    float dx = new Random().nextBoolean() ? 100 : -100;
                    objectAnimator.setFloatValues(imageView.getX(), imageView.getX() + dx);
                    objectAnimator.start();
                    mViewModel.dx += dx;
                }
            }
        });
    }

}
```

- FirstViewModel.java

```java
package com.example.mybottomnavigation.viewmodel;

import androidx.lifecycle.ViewModel;

public class FirstViewModel extends ViewModel {
    public float rotationPosition = 0;
}
```

- SecondViewModel.java

```java
package com.example.mybottomnavigation.viewmodel;

import androidx.lifecycle.ViewModel;

public class SecondViewModel extends ViewModel {
    public float scaleFactor = 1;
}
```

- ThirdViewModel.java

```java
package com.example.mybottomnavigation.viewmodel;

import androidx.lifecycle.ViewModel;

public class ThirdViewModel extends ViewModel {
    public float dx;
}
```

