---
title: Rx
date: 2022-03-21 03:35:24 +0800
categories: [android, tools]
tags: [Android, Rxjava]
description: 
---
# Rxjava

- 添加依赖

```java
implementation 'io.rectivex.rxjava2:rxandroid:2.0.1'
implementation 'io.rectivex.rxjava2:rxjava:2.0.7'
```

## Rx思维下载图片

- 添加网络权限

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

- activity_main.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    xmlns:android="http://schemas.android.com/apk/res/android">

    <ImageView
        android:layout_width="100dp"
        android:layout_height="100dp"
        android:id="@+id/iv"/>

    <Button
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="显示图片下载"
        android:onClick="showImageAction"/>

    <Button
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="常用操作符"
        android:onClick="action"/>

</LinearLayout>
```

- MainActivity.java

```java
package com.example.rxjava;

import androidx.appcompat.app.AppCompatActivity;

import android.annotation.SuppressLint;
import android.app.ProgressDialog;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.ProgressBar;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

import io.reactivex.Observable;
import io.reactivex.Observer;
import io.reactivex.Scheduler;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.disposables.Disposable;
import io.reactivex.functions.Consumer;
import io.reactivex.functions.Function;
import io.reactivex.schedulers.Schedulers;

public class MainActivity extends AppCompatActivity {

    // 网络图片地址
    private final static String PATH = "https://i1.hdslb.com/bfs/face/2eac165893715bfa5a35f76a0f94e5a3a99c16d1.jpg@160w_160h_1c.webp";

    // 弹出加载框
    private ProgressDialog progressDialog;

    private ImageView imageView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        imageView = findViewById(R.id.iv);
    }

    public void showImageAction(View view) {
        // TODO 第二步
        // 起点
        Observable.just(PATH)

                // TODO 第三步
                // 需求001：下载图片
                .map(new Function<String, Bitmap>() {
                    @Override
                    public Bitmap apply(String s) throws Exception {
                        try {
                            URL url = new URL(s);
                            HttpURLConnection httpURLConnection = (HttpURLConnection) url.openConnection();
                            httpURLConnection.setConnectTimeout(5000); // 设置请求连接时常
                            int responseCode = httpURLConnection.getResponseCode();
                            if(responseCode == HttpURLConnection.HTTP_OK){
                                InputStream inputStream = httpURLConnection.getInputStream();
                                Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
                                return bitmap;
                            }
                        } catch (MalformedURLException e) {
                            e.printStackTrace();
                        } finally {
                        }
                        return null;
                    }
                })

                // 需求002：加水印
                .map(new Function<Bitmap, Bitmap>() {
                    @Override
                    public Bitmap apply(Bitmap bitmap) throws Exception {
                        Paint paint = new Paint();
                        paint.setColor(Color.RED);
                        paint.setTextSize(80);
                        Bitmap bitmap1 = drawTextToBitmap(bitmap, "哈哈", paint, 80, 80);
                        return bitmap1;
                    }
                })

                // 需求003：......

                // 给上面的操作分配异步线程
                .subscribeOn(Schedulers.io())

                // 给下面的UI分配安卓主线程
                .observeOn(AndroidSchedulers.mainThread())

                // 订阅：观察者模式 关联起点和终点
                .subscribe(
                        // 终点
                        new Observer<Bitmap>() {
                    // TODO 第一步
                    // 订阅成功
                    @Override
                    public void onSubscribe(Disposable d) {
                        // 加载框
                        progressDialog = new ProgressDialog(MainActivity.this);
                        progressDialog.setTitle("正在加载图片");
                        progressDialog.show();
                    }

                    // TODO 第四步
                    // 上一层的响应
                    @Override
                    public void onNext(Bitmap bitmap) {
                        imageView.setImageBitmap(bitmap);
                    }

                    // 链条发送异常
                    @Override
                    public void onError(Throwable e) {

                    }

                    // TODO 第五步
                    // 链条全部结束
                    @Override
                    public void onComplete() {
                        progressDialog.dismiss();
                    }
                });

    }

    @SuppressLint("CheckResult")
    public void action(View view) {
        String[] strings = {"aaa", "bbb", "ccc"};
        Observable.fromArray(strings)
                .subscribe(new Consumer<String>() {
                    @Override
                    public void accept(String s) throws Exception {
                        Log.d("xxx", "accept: " + s);
                    }
                });

    }

    private final Bitmap drawTextToBitmap(Bitmap bitmap, String text, Paint paint, int paddingLeft, int paddingTop){
        Bitmap.Config bitmapConfig = bitmap.getConfig();

        paint.setDither(true); // 获取清晰的图片采样
        paint.setFilterBitmap(true); // 过滤一些
        if(bitmapConfig == null){
            bitmapConfig = Bitmap.Config.ARGB_8888;
        }
        bitmap = bitmap.copy(bitmapConfig, true);
        Canvas canvas = new Canvas(bitmap);

        canvas.drawText(text, paddingLeft, paddingTop, paint);
        return bitmap;
    }
}
```

## 解决服务器响应问题

- SuccessBean

```java
private int id;
private String name;
```

- ResponseResult

```java
private SuccessBean data;
private int code;
private String message;
```

- CustomObserver.java

```java
package com.example.rxjava2;

import io.reactivex.Observer;
import io.reactivex.disposables.Disposable;

public abstract class CustomObserver implements Observer<ResponseResult> {

    public abstract void success(SuccessBean successBean);
    public abstract void error(String message);

    @Override
    public void onSubscribe(Disposable d) {

    }

    @Override
    public void onNext(ResponseResult responseResult) {
        if(responseResult.getData() == null){
            error(responseResult.getMessage() + "请求失败");
        }else{
            success(responseResult.getData());
        }
    }

    @Override
    public void onError(Throwable e) {
        error(e.getMessage() + "错误详情");
    }

    @Override
    public void onComplete() {

    }
}
```

- LoginEngine.java

```java
package com.example.rxjava2;

import io.reactivex.Observable;

public class LoginEngine {

    public static Observable<ResponseResult> login(String name, String pwd){
        ResponseResult responseResult = new ResponseResult();
        if("xxx".equals(name) && "666".equals(pwd)){
            // 成功Bean
            SuccessBean successBean = new SuccessBean();
            successBean.setId(11111);
            successBean.setName("xxx登录成功");

            responseResult.setData(successBean);
            responseResult.setCode(200);
            responseResult.setMessage("登录成功");
        }else{
            responseResult.setData(null);
            responseResult.setCode(404);
            responseResult.setMessage("登录失败");
        }

        // 返回被观察者
        return Observable.just(responseResult);
    }
}
```

- MainActivity.java

```java
package com.example.rxjava2;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.util.Log;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        LoginEngine.login("xxx", "666")
                .subscribe(new CustomObserver() {
                    @Override
                    public void success(SuccessBean successBean) {
                        Log.d("xxx", "成功bean：" + successBean.toString());
                    }

                    @Override
                    public void error(String message) {
                        Log.d("xxx", "错误信息: " + message);
                    }
                });
    }
}
```

