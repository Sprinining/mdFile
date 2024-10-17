---
title: OkHttp
date: 2022-03-21 03:35:24 +0800
categories: [android, tools]
tags: [Android, OkHttp]
description: 
---
# OkHttp

- 添加依赖

```java
implementation("com.squareup.okhttp3:okhttp:4.9.0")
```

- 注册权限

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 同步与异步请求

```java
package com.example.myokhttp;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.util.Log;
import android.view.View;

import org.jetbrains.annotations.NotNull;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.FormBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    private OkHttpClient okHttpClient;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        okHttpClient = new OkHttpClient();
    }

    public void getSync(View view) {
        // 必须放在线程里
        new Thread(()->{
            Request build = new Request.Builder().url("https://www.httpbin.org/get?a=1&b=2").build();
            // 准备好请求的call对象
            Call call = okHttpClient.newCall(build);

            // 同步请求
            try {
                Response response = call.execute(); // 会阻塞
                Log.d(TAG, "getSync: " + response.body().string());
            } catch (IOException e) {
                e.printStackTrace();
            }
        }).start();
    }

    public void getAsync(View view) {
        Request build = new Request.Builder().url("https://www.httpbin.org/get?a=1&b=2").build();
        // 准备好请求的call对象
        Call call = okHttpClient.newCall(build);

        // 异步请求
        call.enqueue(new Callback() {
            @Override
            public void onFailure(@NotNull Call call, @NotNull IOException e) {

            }

            // 只代表和服务器的请求成功了
            @Override
            public void onResponse(@NotNull Call call, @NotNull Response response) throws IOException {
                if(response.isSuccessful()){
                    Log.d(TAG, "getSync: " + response.body().string());
                }
            }
        });
    }

    public void postSync(View view) {
        new Thread(()->{
            FormBody formBody = new FormBody.Builder().add("a", "1").add("b", "2").build();
            
            Request build = new Request.Builder().url("https://www.httpbin.org/post")
                    .post(formBody).build();

            // 准备好请求的call对象
            Call call = okHttpClient.newCall(build);

            // 同步请求
            try {
                Response response = call.execute(); // 会阻塞
                Log.d(TAG, "postSync: " + response.body().string());
            } catch (IOException e) {
                e.printStackTrace();
            }
        }).start();

    }

    public void postASync(View view) {
        FormBody formBody = new FormBody.Builder().add("a", "1").add("b", "2").build();
        
        Request build = new Request.Builder().url("https://www.httpbin.org/post")
                .post(formBody).build();

        // 准备好请求的call对象
        Call call = okHttpClient.newCall(build);

        call.enqueue(new Callback() {
            @Override
            public void onFailure(@NotNull Call call, @NotNull IOException e) {

            }

            @Override
            public void onResponse(@NotNull Call call, @NotNull Response response) throws IOException {
                if(response.isSuccessful()){
                    Log.d(TAG, "postAsync: " + response.body().string());
                }
            }
        });
    }
}
```

## 上传文件

```java
@Test
public void uploadFileTest() throws IOException {
    File file1 = new File("C:\\Users\\86139\\Downloads\\1.txt");
    File file2 = new File("C:\\Users\\86139\\Downloads\\2.txt");

    OkHttpClient client = new OkHttpClient();

    MultipartBody multipartBody = new MultipartBody.Builder()
            .addFormDataPart("file1", file1.getName(), RequestBody.create(file1, MediaType.parse("text/plain")))
            .addFormDataPart("file2", file2.getName(), RequestBody.create(file2, MediaType.parse("text/plain")))
            .build();
    Request request = new Request.Builder().url("https://www.httpbin.org/post").post(multipartBody).build();

    Call call = client.newCall(request);
    Response response = call.execute();
    System.out.println(response.body().string());

}
```

## 提交json

```java
@Test
public void jsonTest() throws IOException {
    OkHttpClient client = new OkHttpClient();
    // https://www.runoob.com/http/http-content-type.html
    RequestBody requestBody = RequestBody.create("{\"a\":1, \"b\":2}", MediaType.parse("application/json"));
    Request request = new Request.Builder().url("https://www.httpbin.org/post").post(requestBody).build();

    Call call = client.newCall(request);
    Response response = call.execute();
    System.out.println(response.body().string());
}
```

## OkHttp的配置

### 拦截器

```java
@Test
public void interceptorTest() throws IOException {
    OkHttpClient okHttpClient = new OkHttpClient.Builder().addInterceptor(new Interceptor() {
        @NotNull
        @Override
        public Response intercept(@NotNull Chain chain) throws IOException {
            // 前置处理
            Request request = chain.request().newBuilder().addHeader("os", "android")
                    .addHeader("version", "1").build();
            Response response = chain.proceed(request);
            // 后置处理
            return response;
        }
    }).addNetworkInterceptor(new Interceptor() { // 一定在addInterceptor后面执行
        @NotNull
        @Override
        public Response intercept(@NotNull Chain chain) throws IOException {
            System.out.println(chain.request().header("version"));
            return chain.proceed(chain.request());
        }
    }).build();

    Request build = new Request.Builder().url("https://www.httpbin.org/get?a=1&b=2").build();
    try {
        Call call = okHttpClient.newCall(build);
        Response response = call.execute();
        System.out.println(response.body().string());
    } finally {

    }
}
```

### 缓存

- 默认关闭

```java
new OkHttpClient.Builder()
        .cache(new Cache(new File("C:\\Users\\86139\\Downloads\\2.txt"), 1024*1024))
    	.build();
```

### Cookie

```java
package com.example.myokhttp;

import org.jetbrains.annotations.NotNull;
import org.junit.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import okhttp3.Call;
import okhttp3.Cookie;
import okhttp3.CookieJar;
import okhttp3.FormBody;
import okhttp3.HttpUrl;
import okhttp3.OkHttp;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class CookieUnitTest {

    Map<String, List<Cookie>> map = new HashMap<>();

    @Test
    public void cookieTest() throws IOException {

        OkHttpClient okHttpClient = new OkHttpClient.Builder()
                .cookieJar(new CookieJar() {
                    @Override
                    public void saveFromResponse(@NotNull HttpUrl httpUrl, @NotNull List<Cookie> list) {
                        map.put(httpUrl.host(), list);
                    }

                    @NotNull
                    @Override
                    public List<Cookie> loadForRequest(@NotNull HttpUrl httpUrl) {
                        List<Cookie> list = CookieUnitTest.this.map.get(httpUrl.host());
                        return list == null ? new ArrayList<>() : list;
                    }
                }).build();

        FormBody formBody = new FormBody.Builder()
                .add("username", "自己注册")
                .add("password", "自己注册")
                .build();
        Request request = new Request.Builder()
                .url("https://www.wanandroid.com/user/login")
                .post(formBody).build();
        Call call = okHttpClient.newCall(request);
        try {
            Response response = call.execute();
            System.out.println(response.body().string());
        } catch (IOException e) {
            e.printStackTrace();
        }


        request = new Request.Builder().url("https://www.wanandroid.com/lg/collect/list/0/json").build();
        call = okHttpClient.newCall(request);
        try {
            Response response = call.execute();
            System.out.println(response.body().string());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

