---
title: Service
date: 2022-03-21 03:35:24 +0800
categories: [android, ui]
tags: [Android, UI, Service]
description: 
---
# Service

- Service既不是一个线程，Service通常运行在当成宿主进程的主线程中，所以在Service中进行一些**耗时操作就需要在Service内部开启线程去操作**，否则会引发ANR异常。

- 也不是一个单独的进程。**除非在清单文件中声明时指定进程名，否则Service所在进程就是application所在进程。**

## 生命周期

![service_lifecycle](./Service.assets/service_lifecycle.png)

- 服务要在清单文件中声明

- 如果组件通过调用 `startService()` 启动服务（这会引起对 `onStartCommand()` 的调用），则服务会一直运行，直到其使用 `stopSelf()` 自行停止运行，或由其他组件通过调用 `stopService()` 将其停止为止。

- 如果组件通过调用 `bindService()` 来创建服务，且*未*调用 `onStartCommand()`，则服务只会在该组件与其绑定时运行。当该服务与其所有组件取消绑定后，系统便会将其销毁。

- onStartCommand()返回值

  - START_STICKY = 1:service所在进程被kill之后，系统会保留service状态为开始状态。系统尝试重启service，当服务被再次启动，传递过来的intent可能为null，需要注意。
  - START_NOT_STICKY = 2:service所在进程被kill之后，系统不再重启服务
  - START_REDELIVER_INTENT = 3:系统自动重启service，并传递之前的intent

  默认返回START_STICKY。

## 前台服务

- 请求前台权限

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

- MainActivity.java

```java
package com.example.myService;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;

import androidx.appcompat.app.AppCompatActivity;

import com.example.myService.service.MyService;

public class MainActivity extends AppCompatActivity {

    private Button btn_start;
    private Button btn_stop;
    private static final String TAG = "xxx";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        btn_start = findViewById(R.id.btn_start);
        btn_stop = findViewById(R.id.btn_stop);
        Intent intent = new Intent(MainActivity.this, MyService.class);

        btn_start.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {

                startService(intent);
            }
        });

        btn_stop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                stopService(intent);
            }
        });

    }
}
```

- MyForegroundService.java

```java
package com.example.myService.service;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import com.example.myService.activity.BindingActivity;
import com.example.myService.R;

public class MyForegroundService extends Service {
    private static final int NOTIFICATION_ID = 1; // 不能为0
    public static final String CHANNEL_ID = "channel_id";
    private static final String TAG = "xxx";


    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "MyForegroundService onCreate: ");
    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "MyForegroundService onStartCommand: ");

        // 获取通知管理器类对象
        NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);

        // 通知渠道，参数3是通知重要程度
        NotificationChannel notificationChannel = new NotificationChannel(CHANNEL_ID, "测试通知", NotificationManager.IMPORTANCE_HIGH);
        notificationManager.createNotificationChannel(notificationChannel);

        // 点击通知后触发的Intent
        Intent notificationIntent  = new Intent(this, BindingActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(getApplicationContext(), 0, notificationIntent , 0);

//        RemoteViews remoteViews = new RemoteViews(this.getPackageName(), R.layout.notification_layout);

        // Builder构造器创建Notification对象
        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("通知标题")
                .setContentText("通知详情")
                .setAutoCancel(true) // 点击通知后自动消失
                .setSmallIcon(R.drawable.ic_launcher_background)
                .setContentIntent(pendingIntent) // 点击后触发的Intent
                .setColor(Color.parseColor("#FF0000")) // 小图标颜色
                .setLargeIcon(BitmapFactory.decodeResource(getResources(), R.drawable.dog)) // 通知右侧大图标
//                .setContent(remoteViews)
                .build();// id和上面一致

        // 参数一是唯一的通知标识
        startForeground(NOTIFICATION_ID, notification);

        return super.onStartCommand(intent, flags, startId);
    }
    
    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "MyForegroundService onDestroy: ");
        stopForeground(true); // 停止前台服务
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        Log.d(TAG, "MyForegroundService onBind: ");
        return null;
    }
}
```

- NotificationActivity.java

```java
package com.example.myService;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.Nullable;

public class NotificationActivity extends Activity {

    private static final String TAG = "xxx";

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d(TAG, "onCreate: NotificationActivity");
    }
}
```

## 绑定服务

- 如果您确实允许服务同时具有已启动和已绑定状态，那么服务启动后，系统不会在所有客户端均与服务取消绑定后销毁服务，而必须由您通过调用 `stopSelf()` 或 `stopService()` 显式停止服务。
- 可以将多个客户端同时连接到某项服务。但是，系统会缓存 `IBinder` 服务通信通道。换言之，只有在第一个客户端绑定服务时，系统才会调用服务的 `onBind()` 方法来生成 `IBinder`。然后，系统会将该 `IBinder` 传递至绑定到同一服务的所有其他客户端，无需再次调用 `onBind()`。
- 当最后一个客户端取消与服务的绑定时，系统会销毁该服务（除非还通过 `startService()` 启动了该服务）。

### 扩展Binder类

- 服务仅供本地应用使用，且无需跨进程工作，应该实现自有 `Binder` 类，让客户端通过该类直接访问服务中的公共方法。
- 使用
  - 在您的服务中，创建可执行以下某种操作的Binder实例：
    - 包含客户端可调用的公共方法。
    - 返回当前的 `Service` 实例，该实例中包含客户端可调用的公共方法。
    - 返回由服务承载的其他类的实例，其中包含客户端可调用的公共方法。
  - 从 `onBind()` 回调方法返回此 `Binder` 实例。
  - 在客户端中，从 `onServiceConnected()` 回调方法接收 `Binder`，并使用提供的方法调用绑定服务。
- 只有当客户端和服务处于==同一应用和进程内==（最常见的情况）时，此方式才有效。
- BindingActivity.java

```java
package com.example.myService;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.example.myService.service.MyBindService;

public class BindingActivity extends AppCompatActivity {
    private static final String TAG = "xxx";
    private MyBindService mService;
    private boolean mBound = false;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_binding);
    }


    @Override
    protected void onStart() {
        super.onStart();
        // 绑定服务
        Intent intent = new Intent(this, MyBindService.class);
        // 参数2是回调函数
        bindService(intent, connection, Context.BIND_AUTO_CREATE);
    }

    // 通过ServiceConnection接口来取得建立连接与连接意外丢失的回调
    private ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName className, IBinder service) {
            MyBindService.MyBinder binder = (MyBindService.MyBinder) service;
            mService = binder.getService();
            mBound = true;
            Log.d(TAG, "onServiceConnected: ");
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            mBound = false;
            Log.d(TAG, "onServiceDisconnected: ");
        }
    };

    public void onButtonClick(View v) {
        if (mBound) {
            // 调用服务的public方法
            // 如果此调用可能会挂起，则此请求应该发生在单独的线程中，以避免降低活动性能。
            int num = mService.getRandomNumber();
            Toast.makeText(this, "number: " + num, Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    protected void onStop() {
        super.onStop();
        // 解除绑定
        unbindService(connection);
        mBound = false;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }
}
```

- ​	MyBindService.java

```java
package com.example.myService.service;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;

import java.util.Random;

public class MyBindService extends Service {

    private final Random mGenerator = new Random();
    private static final String TAG = "xxx";

    // 服务总是运行在和客户端相同的进程中，除非在清单文件中设置
    public class MyBinder extends Binder {
        public MyBindService getService() {
            // 返回service以便客户端可以调用service的public方法
            return MyBindService.this;
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "MyBindService onCreate: ");
    }

    @Override
    public IBinder onBind(Intent intent) {
        Log.d(TAG, "MyBindService onBind: ");
        return new MyBinder();
    }

    @Override
    public boolean onUnbind(Intent intent) {
        Log.d(TAG, "MyBindService onUnbind: ");
        return super.onUnbind(intent);
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "MyBindService onDestroy: ");
        super.onDestroy();
    }

    public int getRandomNumber() {
        return mGenerator.nextInt(100);
    }
}

```

### Messenger

- 如果您需要让==服务与远程进程通信==，则可使用 `Messenger` 为您的服务提供接口。
- 对于大多数应用，服务无需执行多线程处理，因此使用 `Messenger` 可让服务一次处理一个调用。如果您的服务必须执行多线程处理，请使用 AIDL来定义接口。
- 使用
  - 服务实现一个 `Handler`，由其接收来自客户端的每个调用的回调。
  - 服务使用 `Handler` 来创建 `Messenger` 对象（该对象是对 `Handler` 的引用）。
  - `Messenger` 创建一个 `IBinder`，服务通过 `onBind()` 将其返回给客户端。
  - 客户端使用 `IBinder` 将 `Messenger`（它引用服务的 `Handler`）实例化，然后再用其将 `Message` 对象发送给服务。
  - 服务在其 `Handler` 中（具体而言，是在 `handleMessage()` 方法中）接收每个 `Message`。
- 服务会在 `Handler` 的 `handleMessage()` 方法中接收传入的 `Message`，并根据 `what` 成员决定下一步操作。客户端只需根据服务返回的 `IBinder` 创建 `Messenger`，然后使用 `send()` 发送消息。
- MessengerActivity.java

```java
package com.example.myService.activity;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.view.View;

import androidx.appcompat.app.AppCompatActivity;

import com.example.myService.R;
import com.example.myService.service.MessengerService;

public class MessengerActivity extends AppCompatActivity {

    private boolean bound = false; // 是否已绑定
    private Messenger messenger = null;

    private ServiceConnection connection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder service) {
            messenger = new Messenger(service);
            bound = true;
        }

        public void onServiceDisconnected(ComponentName className) {
            messenger = null;
            bound = false;
        }
    };

    public void sayHello(View v) {
        if (!bound) return;
        Message msg = Message.obtain(null, MessengerService.MSG_SAY_HELLO, 0, 0);
        try {
            messenger.send(msg);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_messenger);
    }

    @Override
    protected void onStart() {
        super.onStart();
        // 绑定服务
        Intent intent = new Intent(this, MessengerService.class);
        bindService(intent, connection, Context.BIND_AUTO_CREATE);
    }

    @Override
    protected void onStop() {
        super.onStop();
        // 如果绑定了就解绑
        if (bound) {
            unbindService(connection);
            bound = false;
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }
}
```

- MessenagerService.java

```java
package com.example.myService.service;

import android.app.Service;
import android.content.Intent;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.util.Log;

public class MessengerService extends Service {

    // 给客户端的信使以向IncomingHandler发送消息。
    private Messenger mMessenger;
    private static final String TAG = "xxx";
    public static final int MSG_SAY_HELLO = 1;

    static class IncomingHandler extends Handler {

        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MSG_SAY_HELLO:
                    Log.d(TAG, "MessengerService handleMessage:");
                    break;
                default:
                    super.handleMessage(msg);
            }
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        mMessenger = new Messenger(new IncomingHandler());
        Log.d(TAG, "MessengerService onBind: ");
        return mMessenger.getBinder();
    }
}
```

### 绑定到服务

- 应用组件（客户端）可通过调用 `bindService()` 绑定到服务。然后，Android 系统会调用服务的 `onBind()` 方法，该方法会返回用于与服务交互的 `IBinder`。

- 绑定是异步操作，并且 `bindService()` 可立即返回，无需将 `IBinder` 返回给客户端。如要接收 `IBinder`，客户端必须创建一个 `ServiceConnection` 实例，并将其传递给 `bindService()`。`ServiceConnection` 包含一个回调方法，系统通过调用该回调方法来传递 `IBinder`。

- **只有 Activity、服务和内容提供程序可以绑定到服务**

- 使用

  - 实现ServiceConnection。

    您的实现必须替换两个回调方法：

    - `onServiceConnected()`

      系统会调用该方法以传递服务的 `onBind()` 方法所返回的 `IBinder`。

    - `onServiceDisconnected()`

      当与服务的连接意外中断时，例如服务崩溃或被终止时，Android 系统会调用该方法。==当客户端取消绑定时，系统不会调用该方法==。

  - 调用bindService()，从而传递ServiceConnection实现。

    **注意**：如果该方法返回 false，说明您的客户端与服务之间并无有效连接。不过，您的客户端仍应调用 `unbindService()`；否则，您的客户端会使服务无法在空闲时关闭。

  - 当系统调用 `onServiceConnected()` 回调方法时，您可以使用接口定义的方法开始调用服务。

  - 如要断开与服务的连接，请调用unbindService()。

    当应用销毁客户端时，如果客户端仍与服务保持绑定状态，销毁会导致客户端取消绑定。更好的做法是在客户端与服务交互完成后，就立即取消客户端的绑定。这样做可以关闭空闲的服务。

### 生命周期

- 当服务与所有客户端之间的绑定全部取消时，Android 系统会销毁该服务（除非还使用 `startService()` 调用启动了该服务）。因此，如果您的服务是纯粹的绑定服务，则无需对其生命周期进行管理，Android 系统会根据它是否绑定到任何客户端代您管理。

- 不过，如果您选择实现 `onStartCommand()` 回调方法，就必须显式停止服务，因为系统现在将服务视为已启动状态。在此情况下，服务将一直运行，直到其通过 `stopSelf()` 自行停止，或其他组件调用 `stopService()`（与该服务是否绑定到任何客户端无关）。

- 此外，如果您的服务已启动并接受绑定，那么当系统调用您的 `onUnbind()` 方法时，如果您想在客户端下一次绑定到服务时接收 `onRebind()` 调用，可以选择返回 `true`。`onRebind()` 返回空值，但客户端仍会在其 `onServiceConnected()` 回调中接收 `IBinder`。下图说明了这种生命周期的逻辑。

![service_binding_tree_lifecycle](./Service.assets/service_binding_tree_lifecycle-16336633637674.png)

