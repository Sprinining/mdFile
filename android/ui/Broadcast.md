---
title: Broadcast
date: 2022-03-21 03:35:24 +0800
categories: [android, ui]
tags: [Android, UI, Broadcast]
description: 
---


# Broadcast

## 静态注册

- 在清单文件中静态注册

```xml
<!-- 静态注册广播接收者-->
<receiver android:name=".CustomReceiver">
    <!--设置有序广播的优先级，越大优先级越高-->
    <intent-filter android:priority="100">
            <action android:name="com.example.receiver_flag" />
    </intent-filter>
</receiver>
```

- 静态发送

```java
// 静态发送广播
public void sendAction1(View view) {
    Intent intent = new Intent();
    intent.setAction(ActionUtils.ACTION_FLAG);
    // 必须指定包名
    intent.setPackage("com.example.myactivity1");
    sendBroadcast(intent);
    // 发送有序广播
//  sendOrderedBroadcast(intent, null);
}
```

- CustomReceiver.java

```java
package com.example.myactivity1.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.widget.Toast;

public class CustomReceiver extends BroadcastReceiver {
    
    @Override
    public void onReceive(Context context, Intent intent) {
        Toast.makeText(context, "静态接收者", Toast.LENGTH_SHORT).show();
//        abortBroadcast(); // 在发送有序广播时，可以截断广播
    }
}
```

## 动态注册

- 在代码中动态注册

```java
// 动态注册自定义广播2
CustomReceiver2 customReceiver2 = new CustomReceiver2();
IntentFilter intentFilter = new IntentFilter();
intentFilter.addAction(ActionUtils.ACTION_FLAG2);
registerReceiver(customReceiver2, intentFilter);

// 注册网络状态变化接受者
// 要在注册清单中申请权限<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
intentFilter = new IntentFilter();       intentFilter.addAction("android.net.conn.CONNECTIVITY_CHANGE");
registerReceiver(networkChangeReceiver, intentFilter);
```

- 动态发送

```java
// 动态发送自定义广播2
public void sendAction2(View view) {
    Intent intent = new Intent();
    intent.setAction(ActionUtils.ACTION_FLAG2);
    sendBroadcast(intent);
}
```

- CustomReveiver2.java

```java
package com.example.myactivity1.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.widget.Toast;

public class CustomReceiver2 extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        Toast.makeText(context, "动态接收者", Toast.LENGTH_SHORT).show();
    }
}
```

- NetworkChangeReceiver.java

```java
package com.example.myactivity1.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.widget.Toast;

public class NetworkChangeReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = connectivityManager.getActiveNetworkInfo();
        if (networkInfo != null && networkInfo.isAvailable()) {
            Toast.makeText(context, "network is working", Toast.LENGTH_SHORT).show();
        } else {
            Toast.makeText(context, "network is unavailable", Toast.LENGTH_SHORT).show();
        }
    }
}
```

