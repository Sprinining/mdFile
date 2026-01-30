## xray 使用

下载[压缩包](https://github.com/XTLS/Xray-core)中的 Xray-linux-64.zip，解压后移动文件：

```bash
sudo cp xry /usr/local/bin/
sudo cp *.dat /usr/local/share/xray/
sudo chmod 644 /usr/local/share/xray/*.dat
```

准备好配置文件 config.json：

```bash
sudo cp config.json /usr/local/etc/xray/
```

然后启动：

```bash
xray -config /usr/local/etc/xray/config.json
```

另外还需配置 linux 的系统代理。