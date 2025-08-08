## RB-Tree（下）

### RB-tree的构造与内存管理

RB-tree 定义了一个专用的空间分配器 `rb_tree_node_allocator`，它的分配策略是——每次只分配恰好一个节点的空间。

```cpp
// 红黑树类模板定义
template <class Key,                     // 键类型（红黑树的排序依据）
          class Value,                   // 节点存储的值类型（如 pair<const Key, T>）
          class KeyOfValue,              // 从 Value 中提取 Key 的仿函数
          class Compare,                 // 键值比较函数（例如 less<Key>）
          class Alloc = alloc>           // 节点内存分配器（默认使用 alloc）
class rb_tree {
protected:
    // 红黑树节点类型（节点中包含颜色、父节点指针、左右子节点指针、值等）
    typedef __rb_tree_node<Value> rb_tree_node;

    // 节点专用的内存分配器：
    // simple_alloc 封装了 Alloc，用于一次分配或释放一个 rb_tree_node 节点的内存
    typedef simple_alloc<rb_tree_node, Alloc> rb_tree_node_allocator;
    
    // ...
};
```

前面给出的程序片段中，还定义了多个与节点管理相关的函数，例如
`get_node()`、`put_node()`、`create_node()`、`clone_node()`、`destroy_node()` 等。

红黑树的构造方式主要有两种：

1. **复制构造**：根据一棵已经存在的红黑树，创建一棵内容完全相同的新红黑树。
2. **默认构造**：直接生成一棵空树，初始时不包含任何节点。

```cpp
// 定义一个红黑树 itree
// Key 类型: int
// Value 类型: int
// KeyOfValue: identity<int>（即 Value 本身就是 Key，不需要额外提取）
// Compare: less<int>（使用升序比较规则）
// Alloc: 使用默认分配器 alloc
rb_tree<int, int, identity<int>, less<int> > itree;
```

这行代码明确指定了：

- 节点的**键类型**（`int`）
- 节点的**值类型**（`int`）
- **键值提取方式**（`identity<int>`，表示值本身就是键）
- **键的比较准则**（`less<int>`，按从小到大排序）

随后调用了 **红黑树的默认构造函数**，生成了一棵空树（仅包含哨兵节点 `header`，尚无实际数据节点）。

```cpp
// 红黑树的默认构造函数
rb_tree(const Compare& comp = Compare())
    : node_count(0),           // 初始节点数量为 0（空树）
      key_compare(comp)        // 保存键值比较规则对象
{
    init();                    // 初始化红黑树结构（创建并设置 header 节点等）
}
```

```cpp
private:
void init() {
    header = get_node();               
    // 分配一个节点空间（但不存放实际数据），作为红黑树的哨兵节点 header

    color(header) = _rb_tree_red;      
    // 将 header 标记为红色
    // 用于与实际根节点区分（迭代器递增操作中会用到颜色判断）

    root() = 0;                        
    // 初始时根节点为空（空树）

    leftmost() = header;               
    // 空树时，最左节点指向 header 自身
    // 在非空树中，leftmost() 会指向最小值节点

    rightmost() = header;              
    // 空树时，最右节点指向 header 自身
    // 在非空树中，rightmost() 会指向最大值节点
}
```

这个 `init()` 的作用就是**初始化一棵空的红黑树**：

- 创建唯一的**哨兵节点 `header`**（不存数据，仅作结构辅助）
- 把 `header` 的左右指针和最值指针都指向自己
- 根节点为空，表示树中没有实际元素
- 用红色标记 `header`，方便与真实节点区分

在树形结构的各种操作中，**最需要特别注意的就是边界情况**，尤其是当遍历或操作到**根节点**时，需要额外的处理逻辑。

为了简化这种边界处理，**SGI STL** 设计了一个额外的“虚拟父节点”，称为 **`header`**，并在初始化时将其设置为特定的结构状态（如图 5-18 所示）。

这样，根节点、最小值节点和最大值节点都可以通过 `header` 的指针方便地访问，并且迭代器的 ++/-- 操作也能统一处理，不必在代码中到处编写根节点特殊判断逻辑。

![image-20250808204055901](./RB-Tree（下）.assets/image-20250808204055901.png)

接下来，每次插入新节点时，除了要按照红黑树的规则进行调整外，还必须维护 `header` 节点的状态，确保：

- `header` 的父节点始终指向当前的根节点，
- `header` 的左子节点指向整棵树中的最小节点，
- `header` 的右子节点指向整棵树中的最大节点。

### RB-tree的元素操作

本节主要讨论红黑树中的元素（节点）的插入和查找操作。

#### 元素插入操作

红黑树提供了两种插入函数：

- `insert_unique()`：要求插入节点的键值（key）在整棵树中必须唯一。如果已有相同键值的节点，插入操作将不会执行。
- `insert_equal()`：允许插入节点的键值在树中重复，无论是否存在相同键值，插入都会成功，除非内存不足导致分配失败。

这两个函数都有多个重载版本，本文以最简单的版本为例，即只传入一个参数——被插入节点的实际值（value）。

需要注意的是，虽然插入时只指定了节点的实际值，但由于红黑树初始化时必须提供 `KeyOfValue` 仿函数，因此可以准确地从值中提取出对应的键值，保证插入时的键值判断和比较是正确的。

##### insert_equal()

```cpp
// 插入新值，允许节点的键值重复
// 返回值是一个指向新插入节点的迭代器
template <class Key, class Value, class KeyOfValue, class Compare, class Alloc>
typename rb_tree<Key, Value, KeyOfValue, Compare, Alloc>::iterator
rb_tree<Key, Value, KeyOfValue, Compare, Alloc>::insert_equal(const Value& v) {
    link_type y = header;   // y 记录当前搜索路径上的父节点，初始指向 header
    link_type x = root();   // x 从根节点开始，寻找插入位置

    // 从根节点开始，沿树向下寻找合适的插入点
    while (x != 0) {
        y = x;
        // 使用 key_compare 比较新值的键与当前节点的键
        // 如果新键小于当前节点键，往左子树走
        // 否则（大于或等于）往右子树走，保证允许重复键值插入右侧
        x = key_compare(KeyOfValue()(v), key(x)) ? left(x) : right(x);
    }

    // 找到插入位置 x（为空），以及插入位置的父节点 y
    // 调用 _insert 执行具体插入操作，返回新节点的迭代器
    return __insert(x, y, v);
}
```

##### insert_unique()

```cpp
// 插入新值：节点键值不允许重复，若重复则插入无效
// 返回值是一个 pair，第一元素是 RB-tree 迭代器，指向新增节点或已有节点，
// 第二元素表示插入是否成功
template <class Key, class Value, class KeyOfValue,
          class Compare, class Alloc>
pair<typename rb_tree<Key, Value, KeyOfValue, Compare, Alloc>::iterator, bool>
rb_tree<Key, Value, KeyOfValue, Compare, Alloc>::insert_unique(const Value& v) {
    link_type y = header;
    link_type x = root();
    bool comp = true;

    // 从根节点开始，寻找插入点
    while (x != 0) {
        y = x;
        comp = key_compare(KeyOfValue()(v), key(x)); // 比较新值键与当前节点键
        x = comp ? left(x) : right(x); // 小于往左，大于等于往右
    }

    // 离开循环时，y 是插入点的父节点（叶节点）
    iterator j = iterator(y); // 令迭代器 j 指向插入点的父节点 y

    if (comp) { // 如果新值键小于父节点键
        if (j == begin()) // 且父节点是最左节点
            return pair<iterator, bool>(__insert(x, y, v), true); // 直接插入左侧

        else
            --j; // 否则回退一个节点，准备做后续判断
    }

    // 判断回退节点的键是否小于新值键
    if (key_compare(key(j.node), KeyOfValue()(v)))
        return pair<iterator, bool>(__insert(x, y, v), true); // 插入右侧

    // 否则键值重复，不插入，返回已有节点和 false
    return pair<iterator, bool>(j, false);
}
```

- `y` 是插入点的父节点（往往是“右边界”），
- `--j` 让迭代器指向 `y` 的“左边界”，
- 新节点键值必须介于这两个边界之间才能插入，避免重复。

##### __insert()

```cpp
template <class Key, class Value, class KeyOfValue,
          class Compare, class Alloc>
typename rb_tree<Key, Value, KeyOfValue, Compare, Alloc>::iterator
rb_tree<Key, Value, KeyOfValue, Compare, Alloc>::__insert(base_ptr x_, base_ptr y_, const Value& v) {
    link_type x = (link_type) x_;  // 将基础指针转换为具体节点指针，表示插入位置（可能为空）
    link_type y = (link_type) y_;  // 插入点的父节点
    link_type z;                   // 新节点指针

    // 判断新节点应该插入到父节点 y 的左子树还是右子树
    if (y == header || x != 0 || key_compare(KeyOfValue()(v), key(y))) {
        // 条件解释：
        // 1. y == header：树为空，新节点将作为根节点插入
        // 2. x != 0：插入位置已确定
        // 3. v 的键值小于 y 的键值，插入左子树

        z = create_node(v);    // 创建新节点
        left(y) = z;           // 新节点设置为 y 的左子节点

        if (y == header) {
            // 树为空，新节点为根节点，更新相关指针
            root() = z;
            rightmost() = z;   // 最大节点也是新节点
        } else if (y == leftmost()) {
            // 如果 y 是当前最左节点，则更新 leftmost 指向新节点
            leftmost() = z;
        }
    } else {
        // 否则插入右子树
        z = create_node(v);
        right(y) = z;          // 新节点设置为 y 的右子节点

        if (y == rightmost()) {
            // 如果 y 是当前最大节点，更新 rightmost 指向新节点
            rightmost() = z;
        }
    }

    // 新节点父指针设置为 y
    parent(z) = y;
    // 新节点左右子节点都初始化为空
    left(z) = 0;
    right(z) = 0;

    // 插入后红黑树自平衡，维护红黑树性质
    __rb_tree_rebalance(z, header->parent);  // header->parent 即根节点

    // 节点计数加一
    ++node_count;

    // 返回指向新插入节点的迭代器
    return iterator(z);
}
```

其中用到的部分函数在 RB-Tree（上）中已经介绍：

```cpp
// 通过header节点访问红黑树中的重要节点：
// root节点、最左（最小）节点、最右（最大）节点
link_type& root() const { return (link_type&) header->parent; }
link_type& leftmost() const { return (link_type&) header->left; }
link_type& rightmost() const { return (link_type&) header->right; }
```

```cpp
// 静态辅助函数，方便访问节点的成员指针和值
static link_type& left(link_type x) { return (link_type&)(x->left); }
static link_type& right(link_type x) { return (link_type&)(x->right); }
static link_type& parent(link_type x) { return (link_type&)(x->parent); }
```

#### 调整 RB-tree (旋转及改变颜色)

每次向红黑树里插入新节点后，树的结构可能会不符合红黑树的规则，比如颜色不对、路径黑色节点数不一致等。为了修正这些问题，需要做一次“调整”操作。

这个调整操作就是调用 `_rb_tree_rebalance()` 函数，它会根据红黑树的性质，通过旋转节点和修改节点颜色，让树重新变成一棵合法的红黑树。

##### __rb_tree_rebalance()

```cpp
// 全局函数
// 重新平衡红黑树（通过颜色调整和旋转实现）
// 参数 x 为新插入的节点，root 为树的根节点指针
inline void __rb_tree_rebalance(__rb_tree_node_base* x, __rb_tree_node_base*& root) {
    x->color = __rb_tree_red;  // 新插入节点必为红色

    // 只要当前节点不是根节点且父节点是红色，持续调整
    while (x != root && x->parent->color == __rb_tree_red) {
        // 如果父节点是爷爷节点的左子节点
        if (x->parent == x->parent->parent->left) {
            // y 为叔叔节点（爷爷的右子节点）
            __rb_tree_node_base* y = x->parent->parent->right;

            // 叔叔节点存在且为红色（情况1：叔叔红）
            if (y && y->color == _rb_tree_red) {
                x->parent->color = __rb_tree_black;       // 父节点变黑
                y->color = __rb_tree_black;                // 叔叔节点变黑
                x->parent->parent->color = __rb_tree_red; // 爷爷节点变红
                x = x->parent->parent;                    // 向上继续检查
            } else {
                // 叔叔不存在或为黑色（情况2或3）

                // 如果当前节点是父节点的右子节点（情况2）
                if (x == x->parent->right) {
                    x = x->parent;
                    __rb_tree_rotate_left(x, root); // 左旋转父节点
                }
                // 颜色调整和右旋（情况3）
                x->parent->color = __rb_tree_black;
                x->parent->parent->color = __rb_tree_red;
                __rb_tree_rotate_right(x->parent->parent, root); // 右旋祖父节点
            }
        } else {
            // 父节点是祖父节点的右子节点，对称处理

            __rb_tree_node_base* y = x->parent->parent->left; // 叔叔节点

            // 叔叔为红色（情况1）
            if (y && y->color == __rb_tree_red) {
                x->parent->color = __rb_tree_black;
                y->color = __rb_tree_black;
                x->parent->parent->color = __rb_tree_red;
                x = x->parent->parent; // 继续向上检查
            } else {
                // 叔叔为黑色或不存在（情况2或3）

                // 如果当前节点是父节点的左子节点（情况2）
                if (x == x->parent->left) {
                    x = x->parent;
                    __rb_tree_rotate_right(x, root); // 右旋转父节点
                }
                // 颜色调整和左旋（情况3）
                x->parent->color = __rb_tree_black;
                x->parent->parent->color = __rb_tree_red;
                __rb_tree_rotate_left(x->parent->parent, root); // 左旋祖父节点
            }
        }
    }
    // 最后，根节点始终保持黑色
    root->color = __rb_tree_black;
}
```

##### __rb_tree_rotate_left()

```cpp
// 全局函数
// 左旋转操作，用于调整红黑树结构
// 参数：
//  x —— 旋转的节点（旋转点）
//  root —— 树的根节点指针的引用，可能因为旋转需要更新根节点

inline void __rb_tree_rotate_left(__rb_tree_node_base* x,
                     __rb_tree_node_base*& root) {
    // 令 y 为 x 的右子节点，将 y 提升为新的旋转点
    __rb_tree_node_base* y = x->right;

    // 将 y 的左子树接到 x 的右子树上（因为 y 将替代 x）
    x->right = y->left;

    // 如果 y 的左子树存在，更新其父节点为 x
    if (y->left != 0)
        y->left->parent = x;

    // y 顶替 x 位置，父节点指针指向 x 的父节点
    y->parent = x->parent;

    // 更新 x 的父节点指向 y，完成 y 顶替 x 的位置
    if (x == root)                // 如果 x 是根节点，更新根节点指针为 y
        root = y;
    else if (x == x->parent->left) // x 是其父节点的左子节点
        x->parent->left = y;
    else                          // x 是其父节点的右子节点
        x->parent->right = y;

    // 将 x 变为 y 的左子节点
    y->left = x;

    // 更新 x 的父节点指针为 y
    x->parent = y;
}
```

##### __rb_tree_rotate_right()

```cpp
// 全局函数
// 右旋转操作，用于调整红黑树结构
// 参数：
//  x —— 旋转的节点（旋转点）
//  root —— 树的根节点指针的引用，可能因为旋转需要更新根节点

inline void __rb_tree_rotate_right(__rb_tree_node_base* x,
                      __rb_tree_node_base*& root) {
    // 令 y 为 x 的左子节点，将 y 提升为新的旋转点
    __rb_tree_node_base* y = x->left;

    // 将 y 的右子树接到 x 的左子树上（因为 y 将替代 x）
    x->left = y->right;

    // 如果 y 的右子树存在，更新其父节点为 x
    if (y->right != 0)
        y->right->parent = x;

    // y 顶替 x 位置，父节点指针指向 x 的父节点
    y->parent = x->parent;

    // 更新 x 的父节点指向 y，完成 y 顶替 x 的位置
    if (x == root)                // 如果 x 是根节点，更新根节点指针为 y
        root = y;
    else if (x == x->parent->right) // x 是其父节点的右子节点
        x->parent->right = y;
    else                          // x 是其父节点的左子节点
        x->parent->left = y;

    // 将 x 变为 y 的右子节点
    y->right = x;

    // 更新 x 的父节点指针为 y
    x->parent = y;
}
```

#### 元素查找操作

```cpp
// 在红黑树中查找键值为 k 的节点，返回指向该节点的迭代器；如果未找到，返回 end()
template <class Key, class Value, class KeyOfValue, class Compare, class Alloc>
typename rb_tree<Key, Value, KeyOfValue, Compare, Alloc>::iterator
rb_tree<Key, Value, KeyOfValue, Compare, Alloc>::find(const Key& k) {
    link_type y = header;      // 保存最后一个不小于 k 的节点
    link_type x = root();      // 从根节点开始搜索

    // 遍历树，寻找键值为 k 的节点
    while (x != 0) {
        // key_compare 是键值比较函数对象，判断 key(x) 是否小于 k
        if (!key_compare(key(x), k)) {
            // 如果 x 的键值 >= k，向左子树搜索
            y = x;           // 记录当前节点，可能是目标节点或其后继
            x = left(x);
        } else {
            // 如果 x 的键值 < k，向右子树搜索
            x = right(x);
        }
    }

    // 构造迭代器指向 y 节点
    iterator j = iterator(y);

    // 判断是否找到目标节点：
    // 如果 j 是 end()，或 k 小于 j 的键值，表示未找到，返回 end()
    // 否则返回指向目标节点的迭代器
    return (j == end() || key_compare(k, key(j.node))) ? end() : j;
}
```

