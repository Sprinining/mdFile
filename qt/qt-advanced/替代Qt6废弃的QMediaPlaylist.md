## 替代 Qt6 废弃的 QMediaPlaylist

- [废弃说明](https://doc.qt.io/qt-6/qtmultimedia-changes-qt6.html)：Qt 6 中移除了 `QMediaPlaylist`，`QMediaPlayer` 也不再内置播放列表支持。
- Qt6 移除了官方 `QMediaPlaylist`，需要自己实现一个简单的播放列表管理类，负责管理媒体文件列表、当前索引、循环模式等。然后用它配合 `QMediaPlayer` 来实现播放切换。

### 核心功能

- 存储媒体文件 URL 列表（`QUrl`）
- 维护当前播放索引
- 支持常用操作：添加、删除、跳转、下一首、上一首
- 支持播放模式（顺序、循环、单曲循环等）

### 实现

#### mymediaplaylist.h

```cpp
#ifndef MYMEDIAPLAYLIST_H
#define MYMEDIAPLAYLIST_H

#include <QObject>
#include <QVector>
#include <QUrl>

/**
 * @brief 自定义简易媒体播放列表类
 * 替代 Qt6 中移除的 QMediaPlaylist，实现播放列表的基本管理功能
 */
class MyMediaPlaylist : public QObject {
    Q_OBJECT
public:
    explicit MyMediaPlaylist(QObject *parent = nullptr);

    // 添加一条媒体资源（文件路径或 URL）
    void addMedia(const QUrl &media);

    // 清空播放列表
    void clear();

    // 获取当前播放索引
    int currentIndex() const;

    // 设置当前播放索引（切换到指定索引的媒体）
    void setCurrentIndex(int index);

    // 获取当前播放的媒体 URL
    QUrl currentMedia() const;

    // 切换到下一条媒体，返回下一条媒体的 URL
    QUrl nextMedia();

    // 切换到上一条媒体，返回上一条媒体的 URL
    QUrl previousMedia();

    // 返回播放列表中媒体的数量
    int mediaCount() const;

signals:
    // 当前播放索引改变时触发
    void currentIndexChanged(int newIndex);

private:
    QVector<QUrl> mediaList_; // 存储媒体列表
    int currentIndex_ = -1;   // 当前播放的索引，-1表示无有效索引
};

#endif // MYMEDIAPLAYLIST_H
```

#### mymediaplaylist.cpp

```cpp
#include "mymediaplaylist.h"

MyMediaPlaylist::MyMediaPlaylist(QObject *parent)
    : QObject(parent), currentIndex_(-1) {
    // 构造函数，初始化当前索引为 -1（无有效索引）
}

void MyMediaPlaylist::addMedia(const QUrl &media) {
    // 向列表中添加新的媒体资源
    mediaList_.append(media);
    // 如果之前没有有效索引，新增媒体后将当前索引设为0，并触发信号
    if (currentIndex_ == -1) {
        currentIndex_ = 0;
        emit currentIndexChanged(currentIndex_);
    }
}

void MyMediaPlaylist::clear() {
    // 清空媒体列表，并重置索引
    mediaList_.clear();
    currentIndex_ = -1;
    emit currentIndexChanged(currentIndex_);
}

int MyMediaPlaylist::currentIndex() const {
    // 返回当前播放索引
    return currentIndex_;
}

void MyMediaPlaylist::setCurrentIndex(int index) {
    // 设置当前播放索引，条件是索引有效且与当前不同
    if (index >= 0 && index < mediaList_.size() && index != currentIndex_) {
        currentIndex_ = index;
        emit currentIndexChanged(currentIndex_);
    }
}

QUrl MyMediaPlaylist::currentMedia() const {
    // 返回当前播放的媒体 URL，如果索引无效返回空 QUrl
    if (currentIndex_ >= 0 && currentIndex_ < mediaList_.size())
        return mediaList_.at(currentIndex_);
    return QUrl();
}

QUrl MyMediaPlaylist::nextMedia() {
    // 切换到下一条媒体，循环播放（到达末尾后返回开头）
    if (mediaList_.isEmpty())
        return QUrl();

    currentIndex_ = (currentIndex_ + 1) % mediaList_.size();
    emit currentIndexChanged(currentIndex_);
    return mediaList_.at(currentIndex_);
}

QUrl MyMediaPlaylist::previousMedia() {
    // 切换到上一条媒体，循环播放（到达开头后返回末尾）
    if (mediaList_.isEmpty())
        return QUrl();

    currentIndex_ = (currentIndex_ - 1 + mediaList_.size()) % mediaList_.size();
    emit currentIndexChanged(currentIndex_);
    return mediaList_.at(currentIndex_);
}

int MyMediaPlaylist::mediaCount() const {
    // 返回播放列表总数
    return mediaList_.size();
}
```

### 使用

#### 先包含头文件

```cpp
#include "mymediaplaylist.h"
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>
#include <QDebug>
```

#### 在类（比如 MainWindow）里声明播放器和播放列表成员

```cpp
class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);

private:
    // 多媒体播放器对象，负责解码和控制媒体播放（音频/视频）
    QMediaPlayer *player_ = nullptr;
    // 音频输出设备，负责将音频数据发送到系统硬件，控制音量、设备等
    QAudioOutput *audioOutput_ = nullptr;
    // 自定义媒体播放列表，用于管理一系列媒体文件的顺序播放
    MyMediaPlaylist *playlist_ = nullptr;
};
```

#### 构造函数里初始化

```cpp
MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent) {
    player_ = new QMediaPlayer(this);
    audioOutput_ = new QAudioOutput(this);
    player_->setAudioOutput(audioOutput_);
    playlist_ = new MyMediaPlaylist(this);

    // 连接播放列表信号，监听当前索引变更，自动切换播放源
    connect(playlist_, &MyMediaPlaylist::currentIndexChanged, this, [this](int index) {
        QUrl mediaUrl = playlist_->currentMedia();
        if (!mediaUrl.isEmpty()) {
            player_->setSource(mediaUrl);
            player_->play();
            qDebug() << "开始播放索引：" << index << ", 文件：" << mediaUrl.toLocalFile();
        }
    });

    audioOutput_->setVolume(0.5); // 设置音量50%
}
```

#### 添加文件到播放列表并开始播放

```cpp
void MainWindow::loadFiles(const QStringList &filePaths) {
    playlist_->clear();
    for (const QString &file : filePaths) {
        playlist_->addMedia(QUrl::fromLocalFile(file));
    }
    // 设置播放第一个文件
    if (playlist_->mediaCount() > 0) {
        playlist_->setCurrentIndex(0);
    }
}
```

#### 控制播放列表跳转

```cpp
void MainWindow::playNext() {
    QUrl next = playlist_->nextMedia();
    if (!next.isEmpty()) {
        player_->setSource(next);
        player_->play();
    }
}

void MainWindow::playPrevious() {
    QUrl prev = playlist_->previousMedia();
    if (!prev.isEmpty()) {
        player_->setSource(prev);
        player_->play();
    }
}
```

#### 简单示例调用

```cpp
QStringList files = QFileDialog::getOpenFileNames(this, tr("选择音频文件"), {}, "音频文件 (*.mp3 *.wav)");
if (!files.isEmpty()) {
    loadFiles(files);
}
```

