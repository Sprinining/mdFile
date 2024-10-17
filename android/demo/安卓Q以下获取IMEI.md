---
title: 安卓Q以下获取IMEI
date: 2022-03-21 03:35:24 +0800
categories: [android, demo]
tags: [Android, IMEI]
description: 
---
```java
    // 获取设备的唯一标识IMEI， 需申请READ_PHONE_STATE权限
    public static String getIMEI(Context context) {
        // 检查是否有权限
        int permissionCheck = ContextCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_STATE);
        if (permissionCheck != PackageManager.PERMISSION_GRANTED) {
            Log.d(TAG, "getIMEI: 没有权限");
            // 申请权限，弹出申请框。此时会调用onPause()，申请框消失后会调用onResume()
            ActivityCompat.requestPermissions((Activity) context, new String[]{Manifest.permission.READ_PHONE_STATE}, REQUEST_READ_PHONE_STATE);
        } else { // PackageManager.PERMISSION_DENIED
//            Log.d(TAG, "getIMEI: 有权限");
        }
        // 此处需在清单文件中开放READ_PRIVILEGED_PHONE_STATE权限
        TelephonyManager tm = (TelephonyManager) context.getSystemService(Service.TELEPHONY_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return tm.getImei();
        } else {
            // 8.0以下
            return tm.getDeviceId();
        }
    }
```

```java
// 处理授权结果回调
// x
@Override
public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    switch (requestCode) {
        case REQUEST_READ_PHONE_STATE:
            if ((grantResults.length > 0) && (grantResults[0] == PackageManager.PERMISSION_GRANTED)) {
                Log.d(TAG, "onRequestPermissionsResult: 授权成功");
            }else{
                Log.d(TAG, "onRequestPermissionsResult: 请求权限被拒");
            }
            break;
        default:
            break;
    }
}
```

