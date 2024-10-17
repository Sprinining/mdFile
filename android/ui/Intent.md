---
title: Intent
date: 2022-03-21 03:35:24 +0800
categories: [android, ui]
tags: [Android, UI, Intent]
description: 
---
# Intent

- 用于启动Activity，启动Service，发送广播

## 显式Intent

- `Intent(Context, Class)` 构造函数分别为应用和组件提供 `Context` 和 `Class` 对象。因此，此 Intent 将显式启动该应用中的 `DownloadService` 类。

```java
Intent downloadIntent = new Intent(this, DownloadService.class);
downloadIntent.setData(Uri.parse(fileUrl));
startService(downloadIntent);
```

```java
startActivity(new Intent(this, MyActivity.class));
```

## 隐式Intent

- 隐式 Intent 指定能够在可以执行相应操作的设备上调用任何应用的操作。如果您的应用无法执行该操作而其他应用可以，且您希望用户选取要使用的应用，则使用隐式 Intent 非常有用。
- 在第二个Activity的注册信息中添加Intent过滤器，表明此Activity可以响应哪些Intent

```xml
<activity android:name=".MyActivity">
    <intent-filter>
        <!--表明可以响应的action，名字是自定义的，不过要匹配-->
        <action android:name="com.example.ACTION_START"/>
        <!--更精确的指明了当前活动能响应的Intent中还可能带有的categroy-->
        <category android:name="android.intent.category.DEFAULT"/>
    </intent-filter>
</activity>
```

- 在第一个Activity中创建Intent用于启动第二个Activity

```java
// 只有<action>和<category>中的内同能够同时匹配Intent中指定的action和category时，这个活动才能响应该Intent
// android.intent.category.DEFAULT是默认的category，在执行startActivity时会自动把这个category添加到Intent中
Intent intent = new Intent("com.example.ACTION_START");
startActivity(intent);
```

- 可以继续添加一个category信息

```java
// Intent中只能指定一个action，但可以指定多个category
intent.addCategory("com.example.MY_CATEGORY");
```

此时会报错：

> Caused by: android.content.ActivityNotFoundException: No Activity found to handle Intent { act=com.example.ACTION_START cat=[com.example.MY_CATEGORY] }

因为第二个Activity的intentfilter中并没有声明可以响应这个category，添加上就能正常跳转界面。

```xml
<activity android:name=".MyActivity">
    <intent-filter>
        <!--表明可以响应的action，名字是自定义的，不过要匹配-->
        <action android:name="com.example.ACTION_START"/>
        <!--更精确的指明了当前活动能响应的Intent中还可能带有的categroy-->
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="com.example.MY_CATEGORY"/>
    </intent-filter>
</activity>
```

- 第一个Activity中创建可以访问浏览器的Intent

```java
Intent intent = new Intent(Intent.ACTION_VIEW);
intent.setData(Uri.parse("http://www.baidu.com"));
startActivity(intent);
```

- 修改第三个Activity的intent过滤器，使他也能响应一个打开网页的Intent

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <data android:scheme="http"/>
</intent-filter>
```

点击按钮后会弹出列表显示所有可以响应该Intent的Activity

## 基本类型传值

- A页面

```java
Intent intent = new Intent(this, MainActivity2.class);
intent.putExtra("name", "xxx");
intent.putExtra("sex", "female");
startActivity(intent);
```

- B页面

```java
Intent intent = getIntent();
Log.d("xxx", "onCreate: " + intent.getStringExtra("name") + intent.getStringExtra("sex"));
```

## 返回数据给上一个Activity

- A传给B

```java
Intent intent = new Intent(MainActivity.this, MyActivity.class);
// 参数2是请求码，用于在之后的回调中判断数据的来源，唯一即可
startActivityForResult(intent, 1);
```

- A中重写onActivityResult()用于接收返回的数据

```java
/**
 *
 * @param requestCode 启动活动时传入的请求码
 * @param resultCode  返回数据时传入的处理结果
 * @param data        携带返回数据的Intent
 */
@Override
protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
    super.onActivityResult(requestCode, resultCode, data);
    switch (requestCode) {
        case 1:
            if (resultCode == RESULT_OK) {
                String returnedData = data.getStringExtra("data_return");
                Log.d(TAG, "onActivityResult: " + returnedData);
            }
            break;
        default:
    }
}
```

- B中重写onBackPressed()通过点返回键，销毁B，并把数据返回给A

```java
@Override
public void onBackPressed() {
    Intent intent = new Intent();
    intent.putExtra("data_return", "返回给上个界面的值");
    setResult(RESULT_OK, intent);
    // 销毁Activity
    finish(); // 此处也可以调用super.onBackPressed()会自动销毁Activity
}
```



## Bundle

- A页面

```java
Intent intent = new Intent(this, MainActivity2.class);

Bundle bundle = new Bundle();
bundle.putString("name", "xxx");
bundle.putString("sex", "female");
intent.putExtras(bundle);

startActivity(intent);
```

- B页面

```java
Intent intent = getIntent();
Log.d("xxx", "onCreate: " + intent.getStringExtra("name") + intent.getStringExtra("sex"));
```

## Serializable

- ==必须实现Serializable接口==
- 更适合jvm
- A页面

```java
Intent intent = new Intent(this, MainActivity2.class);

// 必须实现Serializable接口
Student student = new Student("xxx", 7, 24);
intent.putExtra("student", student);

startActivity(intent);
```

- B页面

```java
Intent intent = getIntent();

// 强制转换
Student student = (Student) intent.getSerializableExtra("student");
Toast.makeText(this, student.name, Toast.LENGTH_SHORT).show();
```

## Parcelable

- ==必须实现Parcelable接口==
- 更适合安卓
- A页面

```java
Intent intent = new Intent(this, MainActivity2.class);

Teacher teacher = new Teacher("xxx", 24);
intent.putExtra("teac", teacher);

startActivity(intent);
```

- B页面

```java
Teacher teacher = intent.getParcelableExtra("teac");
Toast.makeText(this, teacher.name, Toast.LENGTH_SHORT).show();
```

- Teacher.java

```java
package com.example.myintent;

import android.os.Parcel;
import android.os.Parcelable;

public class Teacher implements Parcelable {
    public String name;
    public int age;

    public Teacher(String name, int age) {
        this.name = name;
        this.age = age;
    }

    // 页面B后读取
    protected Teacher(Parcel in) {
        // 从Parcel对象里面读取成员赋给name，age
        name = in.readString();
        age = in.readInt();
    }

    // 页面A先写入
    // 把属性写入到Parcel对象里
    @Override
    public void writeToParcel(Parcel dest, int flags) {
        // 写的顺序和下面读的顺序必须一致
        dest.writeString(name);
        dest.writeInt(age);
    }

    @Override
    public int describeContents() {
        return 0;
    }

    public static final Creator<Teacher> CREATOR = new Creator<Teacher>() {

        // 创建Teacher对象，并且构建好Parcel对象，传递给Teacher
        @Override
        public Teacher createFromParcel(Parcel in) {
            return new Teacher(in);
        }

        @Override
        public Teacher[] newArray(int size) {
            return new Teacher[size];
        }
    };
}

```

## this和MainActivity.this的区别

```java
protected void onCreate(Bundle savedInstenceState){
    super.onCreate(savedInstenceState);

    // 此处this所在范围是Activity类，相当于MainActivity.this
    Intent intent = new Intent(this,Another.class);
    startActivity(intent);

}
```

```java
button.setOnClickListener(new View.OnClickListener() {
    @Override
    public void onClick(View view) {
        // 将this改成MainActivity.this，此处this指向匿名内部类View.OnClickListener()
        Intent intent  = new Intent(this,LoginActivity.class);
        startActivity(intent);
    }
});
```

## PendingIntent

```java
//获得一个用于启动特定Activity的PendingIntent

public static PendingIntent getActivity(Context context, int requestCode,Intent intent, int flags)

//获得一个用于启动特定Service的PendingIntent

public static PendingIntent getService(Context context, int requestCode,Intent intent, int flags)

//获得一个用于发送特定Broadcast的PendingIntent

public static PendingIntent getBroadcast(Context context, int requestCode,Intent intent, int flags)

```
