---
title: 启动另一个包里的activity
date: 2022-03-21 03:35:24 +0800
categories: [android, demo]
tags: [Android, Activity]
description: 
---
- a包ActivityA启动b包的ActivityB
- a的清单文件要注册ActivityB
- b的清单文件中，ActivityB要设置android:exported="true"


```java
Intent intent = new Intent(Intent.ACTION_VIEW);
String packageName = "com.example.myapplication"; // 另一个app的包名
String className = "com.example.myapplication.MainActivity"; // 另一个app要启动的组件的全路径名
intent.setClassName(packageName, className);
startActivity(intent);
```

```java
ComponentName componetName = new ComponentName(
        "com.example.myapplication",  // 这个参数是另外一个app的包名
        "com.example.myapplication.MainActivity");   // 这个是要启动的Service的全路径名

Intent intent = new Intent();
intent.setComponent(componetName);
startActivity(intent);
```

