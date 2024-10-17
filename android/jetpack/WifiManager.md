---
title: WifiManager
date: 2022-03-21 03:35:24 +0800
categories: [android, jetpack]
tags: [Android, Jetpack, WifiManager]
description: 
---
# WLAN

## WifiManager

- 获取

```java
WifiManager wifiManager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
```

- 常用操作

```java
addNetwork(WifiConfiguration config) // 添加一个config描述的WIFI网络，默认情况下，这个WIFI网络是DISABLE状态的。
calculateSignalLevel(int rssi , int numLevels) // 计算信号的等级
compareSignalLevel(int rssiA, int rssiB) // 对比网络A和网络B的信号强度
createWifiLock(int lockType, String tag) // 创建一个WIFI 锁，锁定当前的WIFI连接
disableNetwork(int netId) // 让一个网络连接失效
disconnect() 断开当前的WIFI连接
enableNetwork(int netId, Boolean disableOthers) // 连接netId所指的WIFI网络，并是其他的网络都被禁用
getConfiguredNetworks() // 获取网络连接的状态
getConnectionInfo() // 获取当前连接的信息
getDhcpInfo() // 获取DHCP 的信息
getScanResults() // 获取扫描测试的结果
getWifiState() // 获取当前WIFI设备的状态
isWifiEnabled() // 判断WIFI设备是否打开
pingSupplicant() // ping操作，和PC的ping操作相同作用
ressociate() // 重新连接WIFI网络，即使该网络是已经被连接上的
reconnect() // 重新连接一个未连接上的WIFI网络
removeNetwork() // 移除某一个网络
saveConfiguration() // 保留一个配置信息
setWifiEnabled() // 让一个连接有效
startScan() // 开始扫描
updateNetwork(WifiConfiguration config) // 更新一个网络连接
```

## wifi状态()

```java
WIFI_STATE_DISABLED  // WIFI网卡不可用 
WIFI_STATE_DISABLING // WIFI网卡正在关闭 
WIFI_STATE_ENABLED 	 // WIFI网卡可用 
WIFI_STATE_ENABLING  // WIFI网卡正在打开 
WIFI_STATE_UNKNOWN 	 // WIFI网卡状态不可知
```

## ScanResult

- 表示附近 wifi 热点的属性
- 常用属性如下

1.  BSSID 接入点的地址

2. SSID 网络的名字，唯一区别WIFI网络的名字

3. Capabilities 网络接入的性能

4. Frequency 当前WIFI设备附近热点的频率(MHz)

5. Level 所发现的WIFI网络信号强度

## 连接wifi热点

- 通过 WifiManager.getConfiguredNetworks() 方法会返回 WifiConfiguration 对象的列表，然后再调用 WifiManager.enableNetwork(); 方法就可以连接上指定的热点。

## 查看已经连接上的wifi信息

- WifiInfo 是专门用来表示连接的对象，这个对象可以通过 WifiManager.getConnectionInfo() 来获取。
- 常用操作

```java
getBSSID() // 获取BSSID属性
getDetailedStateOf() // 获取客户端的连通性
getHiddenSSID() // 获取SSID是否被隐藏
getIpAddress() // 获取IP地址(int)
getLinkSpeed() // 获取连接的速度
getMacAddress() // 获取Mac地址
getRssi() // 获取802.11n网络的信号
getSSID() // 获取SSID
getSupplicanState() // 获取具体客户端状态的信息
```
