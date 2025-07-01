## QSS

QSS（**Qt Style Sheets**）是 Qt 的样式系统，用于**美化控件**，控制控件的颜色、边框、字体、背景、间距等外观效果。它的语法类似于 Web 的 CSS，但有自己的限制和扩展。

### QSS 的应用方式

QSS 可以通过以下方式应用：

| 方式                      | 说明                       |
| ------------------------- | -------------------------- |
| `widget->setStyleSheet()` | 应用于单个控件             |
| `parent->setStyleSheet()` | 应用于父控件及其所有子控件 |
| `qApp->setStyleSheet()`   | 全局应用，影响整个应用程序 |
| Qt Designer 中设置样式    | UI 设计时直接设置          |

### 选择器类型

#### 类型选择器

```css
QPushButton { ... }
QLabel { ... }
```

作用于所有该类型的控件。

#### 对象名选择器（ID选择器）

```css
#submitButton { ... }
```

仅作用于 `objectName` 为 `submitButton` 的控件。

#### 类型 + 对象名

```css
QPushButton#submitButton { ... }
```

更精确，必须同时匹配类型和 objectName。

#### 嵌套（后代）选择器

```css
QDialog QPushButton { ... }
```

作用于 QDialog 内部所有 QPushButton。

#### 伪状态选择器

| 状态        | 说明                   |
| ----------- | ---------------------- |
| `:hover`    | 鼠标悬停时             |
| `:pressed`  | 鼠标按下时             |
| `:checked`  | 被选中（复选框等）     |
| `:disabled` | 控件不可用时           |
| `:focus`    | 获取键盘焦点时         |
| `:selected` | 被选中（列表/树/表等） |

#### 伪元素选择器

| 元素          | 说明                          |
| ------------- | ----------------------------- |
| `::item`      | 用于列表、树、表条目          |
| `::section`   | 用于表头                      |
| `::indicator` | 用于复选框/单选按钮指示器部分 |
| `::chunk`     | 用于 QProgressBar 的进度部分  |
| `::handle`    | 滑块、分割条                  |
| `::branch`    | 用于树的分支图标              |

### 常见控件样式写法

#### QPushButton

```css
QPushButton {
    background-color: #444;
    color: white;
    border: 1px solid #666;
    border-radius: 5px;
}
QPushButton:hover {
    background-color: #666;
}
QPushButton:pressed {
    background-color: #222;
}
QPushButton:disabled {
    color: gray;
    background-color: #333;
}
```

#### QLabel

```css
QLabel {
    color: #ddd;
    font-size: 14px;
}
QLabel#title {
    font-weight: bold;
    font-size: 18px;
}
```

#### QLineEdit

```css
QLineEdit {
    background-color: #222;
    color: white;
    border: 1px solid #555;
    border-radius: 3px;
}
QLineEdit:focus {
    border-color: #3399ff;
}
```

#### QListWidget / QTreeView

```css
QListWidget::item:selected,
QTreeView::item:selected {
    background-color: #3399ff;
    color: white;
}
QListWidget::item:hover {
    background-color: #444;
}
```

#### QCheckBox

```css
QCheckBox {
    color: white;
}
QCheckBox::indicator:checked {
    image: url(:/icons/checked.png);
}
QCheckBox::indicator:unchecked {
    image: url(:/icons/unchecked.png);
}
```

#### QScrollBar

```css
QScrollBar:vertical {
    background: #2e2e2e;
    width: 10px;
}
QScrollBar::handle:vertical {
    background: #555;
    border-radius: 4px;
}
```

#### QProgressBar

```css
QProgressBar {
    border: 1px solid #444;
    text-align: center;
    background-color: #222;
}
QProgressBar::chunk {
    background-color: #3399ff;
}
```

#### QToolTip

```css
QToolTip {
    background-color: #333;
    color: white;
    border: 1px solid #555;
    padding: 4px;
    border-radius: 5px;
}
```

### QSS 不生效的原因

1. 控件 `objectName` 不正确（比如 labelPro 写成了 label_pro）
2. 样式设置过早或设置在错误的控件上
3. 被代码中的 `setPalette()`、`setStyle()` 或 `setFont()` 等覆盖
4. 图片路径错误（不是 `:/resource` 格式）
5. 控件被其他控件遮挡或透明

### 进阶技巧

- 可以在运行时切换不同的 QSS 实现“换肤”
- 可以在 QSS 中引用资源系统的图片：`url(:/images/button.png)`
- 利用控件的 `property` 和 `dynamicProperty` 结合代码控制样式（可实现状态类切换）

### 一个完整 QSS 片段（暗色主题）

```css
QMainWindow {
    background-color: #2e2f30;
}

QPushButton {
    background-color: #444;
    color: white;
    border: 1px solid #666;
    border-radius: 4px;
}
QPushButton:hover {
    background-color: #555;
}
QPushButton:pressed {
    background-color: #333;
}
QLineEdit {
    background-color: #333;
    color: white;
    border: 1px solid #555;
    padding: 4px;
}
QListWidget::item:selected {
    background-color: #007acc;
    color: white;
}
QScrollBar:vertical {
    background: #222;
    width: 8px;
}
QScrollBar::handle:vertical {
    background: #555;
    border-radius: 4px;
}
```

### Qt 样式优先级

| 优先级 | 来源                                                   | 是否会覆盖 QSS | 示例                             |
| ------ | ------------------------------------------------------ | -------------- | -------------------------------- |
| 1️⃣      | **代码设置：setPalette() / setFont() / setStyle() 等** | ✅ 是           | `label->setFont(...)`            |
| 2️⃣      | **UI 文件中手动设置的属性**                            | ✅ 是           | Qt Designer 设置颜色、字体等     |
| 3️⃣      | **控件的 QSS（setStyleSheet 或 qApp->setStyleSheet）** | ✅ 中等         | `label->setStyleSheet(...)`      |
| 4️⃣      | **控件的默认外观（系统主题样式）**                     | ❌ 被覆盖       | 未设置颜色、字体，系统默认的样子 |

#### 代码设置（最高优先级）

```cpp
label->setFont(QFont("微软雅黑", 18));
label->setPalette(...);
```

- 优先级最高，会直接覆盖 QSS。

- 设置了字体、颜色、边框等，即使在 QSS 中设了，也不会生效。

#### UI 文件中的属性设置（Designer 里设置的）

- 在 Qt Designer 中选中一个控件，然后在属性编辑器里设置字体、前景色、背景色等。
- Qt 会将其转化为代码等效形式（在构造时调用 `setFont()`、`setPalette()`），**和手动代码设置效果一样**，优先级高于 QSS。

**解决方式**：不要在 UI 文件里设置这些属性，把它们交给 QSS 控制。

#### QSS 设置（样式表）

包括以下几种方式：

```cpp
qApp->setStyleSheet("QLabel { color: red; }");         // 全局 QSS
label->setStyleSheet("color: red;");                   // 局部 QSS
```

- QSS 在没有代码或 UI 设置属性时，是有效的；
- QSS 设置后，可以统一控件外观；
- 它是非常灵活的，但被代码/UI 显式设置时可能被**部分覆盖**。

#### 默认样式（系统主题）

- 当什么都不设置时，Qt 会使用系统风格，如 Windows/ macOS / Fusion 样式。
- 默认值是最低的，几乎总是可以被 QSS 覆盖。

#### 避免 QSS 无效的建议

1. **不要在 Qt Designer 中设置字体、颜色、背景等外观属性**；
2. **不要在代码中调用 `setFont()`、`setPalette()`，除非不打算用 QSS 控制外观**；
3. **推荐统一使用 QSS 控制界面主题，集中管理样式逻辑**；
4. 如果 QSS 仍然不生效，**确保 objectName 是否正确、资源路径是否加载成功**。

#### 示例对比

```cpp
label->setFont(QFont("宋体", 20)); // 优先级最高，覆盖QSS字体设置

label->setStyleSheet("font-size: 14px; color: red;"); // 优先级中等

// UI中设置了字体=宋体12号，也会影响QSS
```

