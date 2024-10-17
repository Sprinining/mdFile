---
title: WorkManager
date: 2022-03-21 03:35:24 +0800
categories: [android, jetpack]
tags: [Android, Jetpack, WorkManager]
description: 
---
# WorkManger

## 工作状态

- 一次性工作的状态

![](./WorkManager.assets/one-time-work-flow.png)

- 定期工作的状态

![](./WorkManager.assets/periodic-work-states.png)

- activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout android:layout_height="match_parent"
    android:layout_width="match_parent"
    android:orientation="vertical"
    xmlns:android="http://schemas.android.com/apk/res/android">

    <Button
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="一次性任务"
        android:onClick="testBackgroundWork1"/>

    <Button
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="一次性任务传递数据"
        android:onClick="testBackgroundWork2"/>

    <Button
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="多个任务"
        android:onClick="testBackgroundWork3"/>

    <Button
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="定期任务"
        android:onClick="testBackgroundWork4"/>

    <Button
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="约束条件"
        android:onClick="testBackgroundWork5"/>

    <Button
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="管理工作"
        android:onClick="testBackgroundWork6"/>


</LinearLayout>
```

- MainActivity.java

```java
package com.example.myworkmanager;

import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.Observer;
import androidx.work.Constraints;
import androidx.work.Data;
import androidx.work.ExistingPeriodicWorkPolicy;
import androidx.work.NetworkType;
import androidx.work.OneTimeWorkRequest;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkInfo;
import androidx.work.WorkManager;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;

import java.net.NetworkInterface;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

public class MainActivity extends AppCompatActivity {
    public static final String TAG = MainActivity.class.getSimpleName();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }

    // btn1:一次性任务
    public void testBackgroundWork1(View view) {
        // 对简单任务进行包装
        OneTimeWorkRequest oneTimeWorkRequest = OneTimeWorkRequest.from(MyWorker1.class); // 简单的用静态方法
        WorkManager.getInstance(getApplicationContext()).enqueue(oneTimeWorkRequest);
    }

    // btn2:一次性任务传递数据
    public void testBackgroundWork2(View view) {
        Data sendData = new Data.Builder().putString("haha", "哈哈").build();

        // 请求对象初始化
        OneTimeWorkRequest oneTimeWorkRequest = new OneTimeWorkRequest.Builder(MyWorker2.class) // 复杂的用构建器
                .setInputData(sendData)
                .build();

        // 获取任务的回馈数据
        WorkManager.getInstance(this).getWorkInfoByIdLiveData(oneTimeWorkRequest.getId())
                .observe(this, new Observer<WorkInfo>() {
                    @Override
                    public void onChanged(WorkInfo workInfo) {
                        // 状态机
                        Log.d(TAG, "状态: " + workInfo.getState().name());

                        if (workInfo.getState().isFinished()) {
                            Log.d(TAG, "后台任务已完成");
                            Log.d(TAG, "回馈数据: " + workInfo.getOutputData().getString("xixi"));
                        }
                    }
                });

        // 请求对象加入到队列
        // 用room保存任务
        WorkManager.getInstance(getApplicationContext()).enqueue(oneTimeWorkRequest);
    }

    // btn3:多个任务
    public void testBackgroundWork3(View view) {
        OneTimeWorkRequest oneTimeWorkRequest3 = new OneTimeWorkRequest.Builder(MyWorker3.class).build();
        OneTimeWorkRequest oneTimeWorkRequest4 = new OneTimeWorkRequest.Builder(MyWorker4.class).build();
        OneTimeWorkRequest oneTimeWorkRequest5 = new OneTimeWorkRequest.Builder(MyWorker5.class).build();

        List<OneTimeWorkRequest> oneTimeWorkRequestList = new ArrayList<>();
        oneTimeWorkRequestList.add(oneTimeWorkRequest3);
        oneTimeWorkRequestList.add(oneTimeWorkRequest5);

        WorkManager.getInstance(this)
                .beginWith(oneTimeWorkRequestList)
                .then(oneTimeWorkRequest4)
                .enqueue();
    }

    // btn4:定期任务
    public void testBackgroundWork4(View view) {
        PeriodicWorkRequest periodicWorkRequest = new PeriodicWorkRequest
//                .Builder(MyWorker1.class, 15, TimeUnit.MINUTES) // 可以定义的最短重复间隔是 15 分钟
                .Builder(MyWorker1.class, // 在每个时间间隔的灵活时间段内运行(每个小时的最后十五分钟运行)
                15, TimeUnit.HOURS,
                1, TimeUnit.MINUTES)
                .setInitialDelay(1, TimeUnit.SECONDS) // 定期任务只有第一次执行会被延迟
                .build();

        WorkManager.getInstance(this).enqueue(periodicWorkRequest);
    }

    // btn5:约束条件
    @RequiresApi(api = Build.VERSION_CODES.M)
    public void testBackgroundWork5(View view) {
        Constraints constraints = new Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED) // 网络连接中
                .setRequiresCharging(true) // 充电中
//                .setRequiresDeviceIdle(false) // 空闲时
                .build();

        // 请求对象
        OneTimeWorkRequest request = new OneTimeWorkRequest.Builder(MyWorker3.class)
                .setConstraints(constraints)
                .addTag("myTag") // 标记
                .build();

        // 加入队列
        WorkManager.getInstance(this).enqueue(request);
    }


    // 判断是否有网络连接
    public static boolean isNetworkConnected(Context context) {
        if (context != null) {
            // 获取手机所有连接管理对象(包括对wi-fi,net等连接的管理)
            ConnectivityManager manager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            // 获取NetworkInfo对象
            NetworkInfo networkInfo = manager.getActiveNetworkInfo();
            //判断NetworkInfo对象是否为空
            if (networkInfo != null)
                return networkInfo.isAvailable();
        }
        return false;
    }

    // btn6:管理工作
    public void testBackgroundWork6(View view) {
        Constraints constraints = new Constraints.Builder().setRequiresCharging(true).build();

        PeriodicWorkRequest request = new
                PeriodicWorkRequest.Builder(MyWorker3.class, 24, TimeUnit.HOURS)
                .setConstraints(constraints)
                .build();
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                "request", // 用于唯一标识工作请求
                ExistingPeriodicWorkPolicy.KEEP, // 冲突解决政策
                request);
    }
}
```

- MyWorker1.java

```java
package com.example.myworkmanager;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import java.util.concurrent.TimeUnit;

public class MyWorker1 extends Worker{
    private static final String TAG = MyWorker1.class.getSimpleName();

    public MyWorker1(@NonNull Context context, @NonNull WorkerParameters workerParams) {
        super(context, workerParams);
    }

    // 后台的异步任务
    @NonNull
    @Override
    public Result doWork() {

        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
            return Result.failure();
        } finally {
            Log.d(TAG, "doWork1: ");
        }
        return Result.success(); // 任务成功
    }
}
```

- MyWorker2.java

```java
package com.example.myworkmanager;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.work.Data;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

public class MyWorker2 extends Worker {
    private static final String TAG = MyWorker2.class.getSimpleName();
    private Context mContext;
    private WorkerParameters workerParameters;

    public MyWorker2(@NonNull Context context, @NonNull WorkerParameters workerParams) {
        super(context, workerParams);
        this.mContext = context;
        this.workerParameters = workerParams;
    }

    @NonNull
    @Override
    public Result doWork() {
        // 接收Activity传递过来的数据
        final String dataString = workerParameters.getInputData().getString("haha");
        Log.d(TAG, "doWork2: " + dataString);

        // 反馈数据给Activity
        Data outputData = new Data.Builder().putString("xixi", "嘻嘻").build();
        @SuppressLint("RestrictedApi") Result.Success success = new Result.Success(outputData);
        return success;

//        return Result.success();
    }
}
```

