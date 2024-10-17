---
title: Fragment
date: 2022-03-21 03:35:24 +0800
categories: [android, ui]
tags: [Android, UI, Fragment]
description: 
---
# Fragment

- Fragment表示应用界面中可重复使用的一部分。Fragment 定义和管理自己的布局，具有自己的生命周期，并且可以处理自己的输入事件。Fragment 不能独立存在，而是必须由 Activity 或另一个 Fragment 托管。Fragment 的视图层次结构会成为宿主的视图层次结构的一部分，或附加到宿主的视图层次结构。
- activity_main.xml中的fragment必须有id
- 当 Activity 处于 `STARTED` 生命周期状态或更高的状态时，可以添加、替换或移除 Fragment。
- 可以在同一 Activity 或多个 Activity 中使用同一 Fragment 类的多个实例。

## 多个fragment

- fragment1.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    tools:context=".BlankFragment1">

    <!-- TODO: Update blank fragment layout -->
    <TextView
        android:id="@+id/tv"
        android:layout_width="match_parent"
        android:layout_height="40dp"
        android:text="@string/hello_blank_fragment" />

    <Button
        android:layout_width="match_parent"
        android:layout_height="40dp"
        android:id="@+id/btn"
        android:text="按钮"/>

</LinearLayout>
```

- activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout android:layout_height="match_parent"
    android:layout_width="match_parent"
    xmlns:tools="http://schemas.android.com/tools"
    android:orientation="vertical"
    tools:context=".MainActivity"
    xmlns:android="http://schemas.android.com/apk/res/android">

    <fragment
        android:id="@+id/fragment1"
        android:name="com.example.myfragment1.BlankFragment1"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_weight="1"/>

    <fragment
        android:id="@+id/fragment2"
        android:name="com.example.myfragment1.BlankFragment2"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_weight="2"/>

</LinearLayout>
```

- BlankFragment1.java

```java
package com.example.myfragment1;

import android.os.Build;
import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

public class BlankFragment1 extends Fragment {

    private View root;
    private TextView textView;
    private Button button;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        if(root == null){
            root = inflater.inflate(R.layout.fragment_blank1, null);
        }
        textView = root.findViewById(R.id.tv);
        button = root.findViewById(R.id.btn);

        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                textView.setText("被点击了");
            }
        });

        return root;
    }
}
```

## 动态添加fragment

1. 创建一个待处理的fragment

2. 获取FragmentManager，通常用getSupportFragmentManager()

3. 开启一个事务transaction，一般调用fragmentManager的beginTransaction()

4. 使用transaction进行fragment替换

5. 提交事务

6. ```java
   Transaction
   #将一个fragment实例添加到Activity里面指定id的容器中
   add(Fragment fragment, String tag)
   add(int containerViewId, Fragment fragment)
   add(int containerViewId, Fragment fragment, String tag);
    #将一个fragment实例从FragmentManager的FragmentList中移除
   remove(Fragment fragment);
   #只控制Fragment的隐藏
   hide(Fragment fragment)
   #只控制Fragment的显示
   show(Fragment fragment)
   #清除视图，从containerid指定的Added列表移除，FragmentList依然保留
   detach(Fragment fragment)
   #创建视图，添加到containerid指定的Added列表，FragmentList依然保留
   attach(Fragment fragment)
   #替换containerViewId中的fragment，它会把containerViewId中所有fragment删除，然后添加当前的fragment
   replace(int containerViewId, Fragment fragment)
   replace(int containerViewId, Fragment fragment, String tag)
   ```

- activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    tools:context=".MainActivity">

    <Button
        android:id="@+id/btn1"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="change"/>

    <Button
        android:id="@+id/btn2"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="replace"/>

    <FrameLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:background="#ffff00"
        android:id="@+id/fl"/>


</LinearLayout>
```

- MainActivity.java

```java
package com.example.myfragment2;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

public class MainActivity extends AppCompatActivity implements View.OnClickListener{

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button button1 = findViewById(R.id.btn1);
        Button button2 = findViewById(R.id.btn2);
        button1.setOnClickListener(this);
        button2.setOnClickListener(this);
    }

    @Override
    public void onClick(View view) {
        switch (view.getId()){
            case R.id.btn1:

                // activity 与 fragment通信
                // 原生方法：Bundle
                Bundle bundle = new Bundle();
                bundle.putString("haha", "xixi");
                BlankFragment1 blankFragment1 = new BlankFragment1();
                blankFragment1.setArguments(bundle);

                // 使用接口通信
                blankFragment1.setFragmentCallback(new IFragmentCallback() {
                    @Override
                    public void sendMsgToActivity(String str) {
                        Toast.makeText(MainActivity.this, str, Toast.LENGTH_SHORT).show();
                    }

                    @Override
                    public String getMsgFromActivity() {
                        return "发送给Fragment的";
                    }
                });

                replaceFragment(blankFragment1);
                break;
            case R.id.btn2:
                replaceFragment(new ItemFragment());
                break;
            default:
                break;
        }
    }

    // 动态切换fragment
    private void replaceFragment(Fragment fragment) {
        FragmentManager fragmentManager = getSupportFragmentManager();
        // 开启一个事务
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        // 替换containerViewId中的fragment，它会把containerViewId中所有fragment删除，然后添加当前的fragment
        fragmentTransaction.replace(R.id.fl, fragment);

        // 放到同一个栈里，点返回时显示上一个fragment
        fragmentTransaction.addToBackStack(null);

        fragmentTransaction.commit();
    }
}
```

## activity与fragment通信

### 原生方法：Bundle

```java
case R.id.btn1:

    // activity 与 fragment通信
    // 原生方法：Bundle
    Bundle bundle = new Bundle();
    bundle.putString("haha", "xixi");
    BlankFragment1 blankFragment1 = new BlankFragment1();
    blankFragment1.setArguments(bundle);

    replaceFragment(blankFragment1);
    break;
```

```java
// 在fragment中获取当前fragment的arguments
Bundle bundle = this.getArguments();
String str = bundle.getString("haha");
Log.e("xxx", "value=" + str);
```

### 接口方案

- IFragmentCallback.java

```java
package com.example.myfragment2;

public interface IFragmentCallback {
    void sendMsgToActivity(String str);
    String getMsgFromActivity();
}
```

- MainActivity.java

```java
case R.id.btn1:

    // activity 与 fragment通信
    // 原生方法：Bundle
    Bundle bundle = new Bundle();
    bundle.putString("haha", "xixi");
    BlankFragment1 blankFragment1 = new BlankFragment1();
    blankFragment1.setArguments(bundle);

    // 使用接口通信
    blankFragment1.setFragmentCallback(new IFragmentCallback() {
        @Override
        public void sendMsgToActivity(String str) {
            Toast.makeText(MainActivity.this, str, Toast.LENGTH_SHORT).show();
        }

        @Override
        public String getMsgFromActivity() {
            return "发送给Fragment的";
        }
    });

    replaceFragment(blankFragment1);
    break;
```

- BlankFragment1.java

```java
package com.example.myfragment2;

import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.Toast;


public class BlankFragment1 extends Fragment {

    private View rootview;

    private IFragmentCallback fragmentCallback;// 用来接收activity中的接口型对象

    public void setFragmentCallback(IFragmentCallback fragmentCallback) {
        this.fragmentCallback = fragmentCallback;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 在fragment中获取当前fragment的arguments
        Bundle bundle = this.getArguments();
        String str = bundle.getString("haha");
        Log.e("xxx", "value=" + str);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        if(rootview == null){
            rootview = inflater.inflate(R.layout.fragment_blank1, container, false);
        }
        Button button = rootview.findViewById(R.id.btn3);
        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
//                fragmentCallback.sendMsgToActivity("发送给Activity");
                String str = fragmentCallback.getMsgFromActivity();
                Toast.makeText(BlankFragment1.this.getContext(), str, Toast.LENGTH_SHORT).show();
            }
        });
        return rootview;
    }

    @Override
    public void onResume() {

        super.onResume();
    }
}
```

### 其他方案：eventBus，LiveData

- 使用了观察者模式

## Fragment生命周期

![fragment_lifecycle](./Fragment.assets/fragment_lifecycle.png)

![image-20210906103322308](./Fragment.assets/image-20210906103322308.png)

1. 创建：onAttach() -> onCreate() -> onCreateView() -> onActivityCreated() -> onStart() -> onResume()
2. 按下主屏键：onPause() -> onStop()
3. 重新打开：onStart() -> onResume()
4. 按下后退键：onPause() -> onStop() -> onDestroyView() -> onDestroy() -> onDetach()

## Fragment和ViewPager滑动效果

- buttom_layout.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:orientation="horizontal"
    android:layout_width="match_parent"
    android:layout_height="55dp"
    android:background="#B0C4DE">

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="match_parent"
        android:layout_weight="1"
        android:layout_gravity="center"
        android:gravity="center"
        android:orientation="vertical"
        android:id="@+id/tab_weixin">

        <ImageView
            android:layout_width="32dp"
            android:layout_height="32dp"
            android:background="@drawable/tab_weixin"
            android:id="@+id/iv_weixin"/>
        <TextView
            android:layout_width="32dp"
            android:layout_height="wrap_content"
            android:gravity="center"
            android:text="微信"
            android:id="@+id/tv_weixin"/>

    </LinearLayout>

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="match_parent"
        android:layout_weight="1"
        android:layout_gravity="center"
        android:gravity="center"
        android:orientation="vertical"
        android:id="@+id/tab_pay">

        <ImageView
            android:layout_width="32dp"
            android:layout_height="32dp"
            android:background="@drawable/tab_pay"
            android:id="@+id/iv_pay"/>
        <TextView
            android:layout_width="32dp"
            android:layout_height="wrap_content"
            android:gravity="center"
            android:text="支付"
            android:id="@+id/tv_pay"/>

    </LinearLayout>

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="match_parent"
        android:layout_weight="1"
        android:layout_gravity="center"
        android:gravity="center"
        android:orientation="vertical"
        android:id="@+id/tab_weixin1">

        <ImageView
            android:layout_width="32dp"
            android:layout_height="32dp"
            android:background="@drawable/tab_weixin1"
            android:id="@+id/iv_weixin1"/>
        <TextView
            android:layout_width="32dp"
            android:layout_height="wrap_content"
            android:gravity="center"
            android:text="微"
            android:id="@+id/tv_weixin1"/>

    </LinearLayout>

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="match_parent"
        android:layout_weight="1"
        android:layout_gravity="center"
        android:gravity="center"
        android:orientation="vertical"
        android:id="@+id/tab_weixin2">

        <ImageView
            android:layout_width="32dp"
            android:layout_height="32dp"
            android:background="@drawable/tab_weixin2"
            android:id="@+id/iv_weixin2"/>
        <TextView
            android:layout_width="32dp"
            android:layout_height="wrap_content"
            android:gravity="center"
            android:text="信"
            android:id="@+id/tv_weixin2"/>

    </LinearLayout>

</LinearLayout>
```

- fragment_blank.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context=".BlankFragment">

    <!-- TODO: Update blank fragment layout -->
    <TextView
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:gravity="center"
        android:textSize="36sp"
        android:id="@+id/tv"
        android:text="@string/hello_blank_fragment" />

</FrameLayout>
```

- activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout android:layout_height="match_parent"
    android:layout_width="match_parent"
    android:orientation="vertical"
    xmlns:android="http://schemas.android.com/apk/res/android">

    <androidx.viewpager2.widget.ViewPager2
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:id="@+id/vp"/>

    <include layout="@layout/bottom_layout"></include>

</LinearLayout>
```

- tab_weixin.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@drawable/weixin2" android:state_selected="true"/>
    <item android:drawable="@drawable/weixin1"/>
</selector>
```

- BlankFragment.java

```java
package com.example.mywechat;

import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

public class BlankFragment extends Fragment {

    private static final String ARG_TEXT = "param1";
    private View rootView;
    private String mTextString;

    public BlankFragment() {
        // Required empty public constructor
    }

    public static BlankFragment newInstance(String param1) {
        BlankFragment fragment = new BlankFragment();
        Bundle args = new Bundle();
        args.putString(ARG_TEXT, param1);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mTextString = getArguments().getString(ARG_TEXT);
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        if(rootView == null){
            rootView = inflater.inflate(R.layout.fragment_blank, container, false);
        }
        initView();
        return rootView;
    }

    private void initView() {
        TextView textView = rootView.findViewById(R.id.tv);
        textView.setText(mTextString);
    }
}
```

- MainActivity.java

```java
package com.example.mywechat;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.viewpager2.widget.ViewPager2;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends AppCompatActivity implements View.OnClickListener{

    private ViewPager2 viewPager;
    private LinearLayout llweixin, llweixin1, llweixin2, llpay;
    private ImageView ivweixin, ivweixin1, ivweixin2, ivpay, ivCurrent;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        initPager();
        initTabView();
    }

    private void initPager() {
        List<Fragment> fragments = new ArrayList<>();
        fragments.add(BlankFragment.newInstance("微信"));
        fragments.add(BlankFragment.newInstance("通讯录"));
        fragments.add(BlankFragment.newInstance("发现"));
        fragments.add(BlankFragment.newInstance("我"));

        viewPager = findViewById(R.id.vp);
        MyFragmentPagerAdapter myFragmentPagerAdapter = new MyFragmentPagerAdapter(getSupportFragmentManager(), getLifecycle(), fragments);
        viewPager.setAdapter(myFragmentPagerAdapter);
        viewPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
                super.onPageScrolled(position, positionOffset, positionOffsetPixels);
            }

            @Override
            public void onPageSelected(int position) {
                super.onPageSelected(position);
                changeTab(position);
            }

            @Override
            public void onPageScrollStateChanged(int state) {
                super.onPageScrollStateChanged(state);
            }
        });
    }

    private void changeTab(int position) {
        ivCurrent.setSelected(false); // 当前的按钮先复位
        switch (position){
            case R.id.tab_weixin:
                viewPager.setCurrentItem(0);
            case 0:
                ivweixin.setSelected(true);
                ivCurrent = ivweixin;
                break;
            case R.id.tab_pay:
                viewPager.setCurrentItem(1);
            case 1:
                ivpay.setSelected(true);
                ivCurrent = ivpay;
                break;
            case R.id.tab_weixin1:
                viewPager.setCurrentItem(2);
            case 2:
                ivweixin1.setSelected(true);
                ivCurrent = ivweixin1;
                break;
            case R.id.tab_weixin2:
                viewPager.setCurrentItem(3);
            case 3:
                ivweixin2.setSelected(true);
                ivCurrent = ivweixin2;
                break;
        }
    }

    private void initTabView(){
        llweixin = findViewById(R.id.tab_weixin);
        llweixin.setOnClickListener(this);
        llweixin1 = findViewById(R.id.tab_weixin1);
        llweixin1.setOnClickListener(this);
        llweixin2 = findViewById(R.id.tab_weixin2);
        llweixin2.setOnClickListener(this);
        llpay = findViewById(R.id.tab_pay);
        llpay.setOnClickListener(this);
        ivweixin = findViewById(R.id.iv_weixin);
        ivweixin1 = findViewById(R.id.iv_weixin1);
        ivweixin2 = findViewById(R.id.iv_weixin2);
        ivpay = findViewById(R.id.iv_pay);

        llweixin.setSelected(true);
        ivCurrent = ivweixin;
    }

    @Override
    public void onClick(View view) {
        changeTab(view.getId());
    }
}
```

- MyFragmentPagerAdapter.java

```java
package com.example.mywechat;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.lifecycle.Lifecycle;
import androidx.viewpager2.adapter.FragmentStateAdapter;

import java.util.ArrayList;
import java.util.List;

public class MyFragmentPagerAdapter extends FragmentStateAdapter {

    private List<Fragment> fragmentList = new ArrayList<>();

    public MyFragmentPagerAdapter(@NonNull FragmentManager fragmentManager, @NonNull Lifecycle lifecycle, List<Fragment> fragments) {
        super(fragmentManager, lifecycle);
        fragmentList = fragments;
    }

    @NonNull
    @Override
    public Fragment createFragment(int position) {
        return fragmentList.get(position);
    }

    @Override
    public int getItemCount() {
        return fragmentList.size();
    }
}
```

## 与fragment通信

### 使用ViewModel

#### fragment和activity

- Activity中

```java
viewModel = new ViewModelProvider(this).get(CityViewModel.class);
```

- Fragment中

```java
/**
 * MainActivity用作MainActivity和WeatherDetailFragment中的范围，因此为它们提供了相同的 ViewModel。
 * 如果WeatherDetailFragment将自身用作范围，即viewModel = new ViewModelProvider(this).get(CityViewModel.class);
 * 会为其提供与MainActivity不同的ViewModel。
 */
// viewModel = new ViewModelProvider(this).get(CityViewModel.class); // 不同的viewmodel
viewModel = new ViewModelProvider(requireActivity()).get(CityViewModel.class);
```
