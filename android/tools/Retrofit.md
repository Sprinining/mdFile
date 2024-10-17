---
title: Retrofit
date: 2022-03-21 03:35:24 +0800
categories: [android, tools]
tags: [Android, Retrofit]
description: 
---
# Retrofit

- 添加依赖：implementation 'com.squareup.retrofit2:retrofit:2.9.0'
- 开权限：<uses-permission android:name="android.permission.INTERNET"/>
- HttpbinService.java

```java
package com.example.myretrofit;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.http.Field;
import retrofit2.http.FormUrlEncoded;
import retrofit2.http.GET;
import retrofit2.http.POST;
import retrofit2.http.Query;

public interface HttpbinService {

    // 根据Http接口创建java接口
    @POST("post")
    @FormUrlEncoded
    Call<ResponseBody> post(@Field("username") String userName, @Field("password") String pwd);

    @GET("get")
    Call<ResponseBody> get(@Query("username") String userName, @Query("password") String pwd);
}
```

- MainActivity.java

```java
package com.example.myretrofit;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.util.Log;
import android.view.View;

import java.io.IOException;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;

public class MainActivity extends AppCompatActivity {

    private Retrofit retrofit;
    private HttpbinService httpbinService;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // 创建Retrofit对象，并生成接口实现类对象
        retrofit = new Retrofit.Builder().baseUrl("https://www.httpbin.org/").build();
        httpbinService = retrofit.create(HttpbinService.class);
    }


    public void postAsync(View view){
        // 接口实现类对象调用对应方法获得响应
        Call<ResponseBody> call = httpbinService.post("xxx", "666");

        call.enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                try {
                    Log.d("xxx", "postAsync: " + response.body().string());
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {

            }
        });
    }
}
```

- 运行结果

2021-07-19 11:04:20.820 8337-8337/com.example.myretrofit D/xxx: postAsync: {
      "args": {}, 
      "data": "", 
      "files": {}, 
      "form": {
        "password": "666", 
        "username": "xxx"
      }, 
      "headers": {
        "Accept-Encoding": "gzip", 
        "Content-Length": "25", 
        "Content-Type": "application/x-www-form-urlencoded", 
        "Host": "www.httpbin.org", 
        "User-Agent": "okhttp/3.14.9", 
        "X-Amzn-Trace-Id": "Root=1-60f4ebb6-0877c1ef1d65fced6417f3a9"
      }, 
      "json": null, 
      "origin": "58.213.198.61", 
      "url": "https://www.httpbin.org/post"
    }
