## RB-Tree（上）

RB-tree（红黑树）是加了平衡条件的二叉搜索树，需满足以下规则：

1. 每个节点是红或黑。

2. 根节点是黑色。

3. 红节点不能有红色子节点（即不能连续红）。

4. 从任一节点到其所有 NULL（叶端）路径上的黑节点数相同。

   - 这些路径是指：从某个节点出发，往下走到“空指针”结束（即 NULL 节点）。

   - 这些“NULL 节点”并不是真正存在于树中的实际节点，但在理论分析中，会将每个叶子节点的左右子指针（即指向 NULL）视为“虚拟叶子节点”。

   - 这些“NULL”被视作**黑色节点**，这点在红黑树的定义中是默认的。

   - ```css
                [B]         ← 黑节点
               /   \
             [R]   [R]      ← 红节点
             /       \
           [B]       [B]    ← 黑节点
           / \       / \
      NULL NULL NULL NULL   ← 都算作黑色
     ```

5. 每个叶子节点（即 NULL 节点）都是黑色的。

   - 在 **红黑树的语境下**：

     - **NULL 被视作叶子节点**，并且是黑色的。

     - 红黑树中的“叶子节点”就是指的 NULL 节点（并不是没有孩子的真实节点）


新增节点设为红色，若违反规则需通过“变色”和“旋转”调整恢复平衡。

![image-20250727180339676](./RB-Tree（上）.assets/image-20250727180339676.png)

### AVL vs 红黑树的对比

| 特性         | AVL 树                     | 红黑树                                       |
| ------------ | -------------------------- | -------------------------------------------- |
| 平衡条件     | 任一节点左右子树高度差 ≤ 1 | 任一路径黑节点数相同，不允许连续红           |
| 平衡“严格度” | 更严格（几乎是最平衡的）   | 较宽松（可容忍部分不平衡）                   |
| 插入调整     | 可能需要多次旋转           | 最多一次旋转 + 多次变色                      |
| 删除调整     | 较复杂，旋转多             | 简洁，最多三次旋转                           |
| 查找效率     | 更快（因树更矮）           | 略慢（树更高）                               |
| 应用场景     | 注重查找效率，如数据库索引 | 注重插入/删除效率，如操作系统、STL `map/set` |

### 插入节点

插入 3、8、35、75 后，都会违反红黑树的规则，因此需要调整结构。这些调整包括：**旋转**和**变色**，以恢复红黑树的五大规则（尤其是红红相连和黑高不一致的问题）。

![image-20250727181140724](./RB-Tree（上）.assets/image-20250727181140724.png)

为便于讨论，我们为特定节点设定代称：

- 新插入节点为 **X**
- 父节点为 **P**
- 祖父节点为 **G**
- 伯父节点（P 的兄弟）为 **S**
- 曾祖父节点为 **GG**

由于按二叉搜索树规则，X 一定是叶节点；根据红黑树规则 4，X 必须为红色。若其父 **P 也是红色**，就违反了红黑树规则 3，必须进行调整（如果父节点是黑色，直接插入红色新节点，不需要任何旋转或染色操作）。这时，**G 必为黑色**（因为原树满足红黑树规则）。

接下来根据 **X 的位置** 和 **S、GG 的颜色**，我们有四种典型处理情形。

#### **情况1：叔叔节点 S 是黑色，且 X 是“外侧插入”**

处理方法：

- 对 P 和 G 进行 **一次单旋转**
- 然后交换 P 和 G 的颜色

这样就能重新满足红黑树的规则，尤其是规则 3（红色不能相邻）。这是最简单、最直接的一种调整方式。

![image-20250727181800564](./RB-Tree（上）.assets/image-20250727181800564.png)

虽然此时可能出现子树高度差超过 1 的不平衡（如 A、B 为 null 而 D 或 E 非 null），但这无妨，因为红黑树的平衡要求本就比 AVL 树宽松。

经验表明，**红黑树的平均搜索效率和 AVL 树几乎相同**，实际效果很好。

#### 情况2：叔叔节点 S 是黑色，且 X 是“内侧插入”

处理方法：

- 对 P 和 X 进行 **一次单旋转**，并交换 G 和 X 的颜色
- 再对 G 进行 **一次单旋转**

![image-20250727182347189](./RB-Tree（上）.assets/image-20250727182347189.png)

#### **情况3：叔叔节点 S 是红色，且 X 是“外侧插入”**

红黑树插入调整中，**“叔叔节点 S 是红色”时，不论 X 是内侧插入还是外侧插入**，这两种情况的处理方式是一样的——都是“重新染色并递归向上调整”。

处理方法：

- 先对 P 和 G 做一次单旋转
- 改变 X 的颜色

如果曾祖父 GG 是黑色，调整完成；若 GG 是红色，则需进一步处理，见情况4。

![image-20250727182540955](./RB-Tree（上）.assets/image-20250727182540955.png)

#### **情况4：叔叔节点 S 和曾祖父节点 GG 都是红色，且 X 是“外侧插入”**

处理方法：

- 先对 P 和 G 做一次单旋转
- 改变 X 的颜色
- 若 GG 仍为红色，则继续向上调整，直到没有连续红色父子节点为止。

![image-20250727182635317](./RB-Tree（上）.assets/image-20250727182635317.png)

### Top-Down 插入优化策略：避免持续向上调整

为避免插入时出现连续红色节点（即“父子皆红”），导致调整向上蔓延的性能问题，可采用一种**自顶向下（Top-Down）**的处理方式：

> 当新节点 A 沿插入路径向下寻找插入点时，**只要遇到某个节点 X 的两个子节点都是红色**，就进行如下变换：
>
> - 将 **X 涂红**
> - 将 **X 的两个子节点涂黑**

这种变换能预先消除将来可能出现的红冲突，从而**减少后续旋转和颜色调整的复杂度**，也能避免向上递归调整，提升插入效率。

![image-20250728180840834](./RB-Tree（上）.assets/image-20250728180840834.png)

即使使用 Top-Down 插入法，在插入节点 A 的路径上先做了变色处理，但若插入 A 后，**A 的父节点 P 是红色**，仍会产生“父子皆红”的违规情况。此时：

- 若是“外侧插入”（A 和 P 同侧）→ 执行一次**单旋转**（参考状况1），并交换颜色。
- 若是“内侧插入”（A 和 P 异侧）→ 执行一次**双旋转**（参考状况2），并调整颜色。

完成这些操作后，**红黑树性质恢复**。接着，后续节点（如节点 35）插入就会很简单：

> 只需普通插入，或插入后配合一次简单的旋转即可。

![image-20250728180854424](./RB-Tree（上）.assets/image-20250728180854424.png)

### RB-tree 的节点设计

RB-tree 是具有红黑节点和左右子树的二叉搜索树。SGI STL 实现中采用双层节点结构，并设有 `parent` 指针，便于向上回溯。极值查找如 `minimum()`、`maximum()` 操作也非常简单高效。

```cpp
// 定义颜色类型为 bool
typedef bool _rb_tree_color_type;

// 红色为 false (0)，黑色为 true (1)
const _rb_tree_color_type _rb_tree_red = false;
const _rb_tree_color_type _rb_tree_black = true;

// 基础节点结构体，包含颜色、父子节点指针
struct _rb_tree_node_base {
    typedef _rb_tree_color_type color_type;   // 节点颜色类型（红或黑）
    typedef _rb_tree_node_base* base_ptr;     // 指向自身类型的指针别名

    color_type color;     // 节点颜色，非红即黑
    base_ptr parent;      // 指向父节点的指针（红黑树的操作常需要回溯父节点）
    base_ptr left;        // 指向左子节点的指针
    base_ptr right;       // 指向右子节点的指针

    // 查找以 x 为根的子树中的最小值节点（一直往左走）
    static base_ptr minimum(base_ptr x) {
        while (x->left != 0) x = x->left;
        // 一直向左走就能找到最小值
        return x;
    }

    // 查找以 x 为根的子树中的最大值节点（一直往右走）
    static base_ptr maximum(base_ptr x) {
        while (x->right != 0) x = x->right;
        // 一直向右走就能找到最大值
        return x;
    }
};

// 继承基础节点结构体，并添加 value 域（即模板值类型）
template <class Value>
struct _rb_tree_node : public _rb_tree_node_base {
    typedef _rb_tree_node<Value>* link_type;  // 指向自身类型的指针别名
    Value value_field;                        // 存储的数据内容（节点的值）
};
```

- 红黑树节点由 `_rb_tree_node_base` 提供通用结构，包括颜色和指针。
- `_rb_tree_node<Value>` 是模板化的节点，额外持有值字段 `value_field`。
- `minimum()` 和 `maximum()` 利用了二叉搜索树的特性，分别查找最小和最大值节点。

![image-20250728182129652](./RB-Tree（上）.assets/image-20250728182129652.png)

### RB-tree 的迭代器

为了将 RB-Tree 实现为泛型容器，**迭代器设计是关键**，需支持以下操作：

- **类型分类（category）**
- **前进（++）、后退（--）**
- **提领（\*）、成员访问（->）**

SGI STL 采用了 **双层结构** 的设计：

- 节点：`_rb_tree_node` 继承自 `_rb_tree_node_base`
- 迭代器：`_rb_tree_iterator` 继承自 `_rb_tree_base_iterator`

这种设计类似 `slist`，**利于统一操作与灵活转换**，也方便我们深入分析 RB-Tree 的行为和状态。

![image-20250728182216005](./RB-Tree（上）.assets/image-20250728182216005.png)

#### **RB-Tree 迭代器特性与前后移动操作**

- **属于双向迭代器**，不支持随机访问。
- **提领（`\*`）与成员访问（`->`）** 与 `list` 类似。
- **前进操作 `operator++()`** 会调用基类的 `increment()`
- **后退操作 `operator--()`** 会调用基类的 `decrement()`

前后移动都遵循 **二叉搜索树的中序遍历规则**，实现上对根节点处理有些特殊技巧。

```cpp
// 基层迭代器结构
struct _rb_tree_base_iterator {
    typedef _rb_tree_node_base::base_ptr base_ptr;
    typedef bidirectional_iterator_tag iterator_category;
    typedef ptrdiff_t difference_type;

    base_ptr node; // 当前迭代器所指的节点，用于和容器产生连接（引用某个节点）

    // 前向移动操作（即中序遍历下一个节点）
    void increment() {
        if (node->right != 0) {
            // 情况1：当前节点有右子节点
            node = node->right;
            // 那么就一直往左走，直到最左（最小）节点
            while (node->left != 0)
                node = node->left;
        } else {
            // 情况2：没有右子节点，需要上溯
            base_ptr y = node->parent;
            while (node == y->right) {
                // 如果当前是父节点的右子节点，一直往上找
                node = y;
                y = y->parent;
            }
            // 情况3和4判断
            if (node->right != y)
                node = y;
            // 注意：
            // 如果 node->right == y，表示 node 已经是最右节点
            // 特殊情况：node 是根节点，且无右子节点 —— 用 header 特殊结构处理
        }
    }

    // 后退操作（即中序遍历上一个节点）
    void decrement() {
        // 情况1：node 是 header（end()），其颜色为红，且父节点的父节点等于自己
        if (node->color == _rb_tree_red && node->parent->parent == node) {
            node = node->right; // header 的右子节点是整棵树的最大值
        }
        else if (node->left != 0) {
            // 情况2：有左子树，则往左走一次后一直往右走到底
            base_ptr y = node->left;
            while (y->right != 0)
                y = y->right;
            node = y;
        }
        else {
            // 情况3：没有左子树，需要上溯
            base_ptr y = node->parent;
            while (node == y->left) {
                // 当前节点是左子节点，一直往上找
                node = y;
                y = y->parent;
            }
            node = y; // 最后 y 即为前驱
        }
    }
};
```

RB-tree 正规迭代器结构（继承基层迭代器）:

```cpp
template <class Value, class Ref, class Ptr>
struct _rb_tree_iterator : public _rb_tree_base_iterator {
    typedef Value      value_type;
    typedef Ref        reference;
    typedef Ptr        pointer;

    typedef _rb_tree_iterator<Value, Value&, Value*>             iterator;
    typedef _rb_tree_iterator<Value, const Value&, const Value*> const_iterator;
    typedef _rb_tree_iterator<Value, Ref, Ptr>                   self;
    typedef _rb_tree_node<Value>*                                link_type;

    // 构造函数
    _rb_tree_iterator() {}
    _rb_tree_iterator(link_type x) { node = x; }
    _rb_tree_iterator(const iterator& it) { node = it.node; }

    // 解引用操作（取值）
    reference operator*() const {
        return link_type(node)->value_field;
    }

#ifndef _SGI_STL_NO_ARROW_OPERATOR
    // 成员访问（类似指针访问）
    pointer operator->() const {
        return &(operator*());
    }
#endif

    // 前置 ++
    self& operator++() {
        increment();
        return *this;
    }

    // 后置 ++
    self operator++(int) {
        self tmp = *this;
        increment();
        return tmp;
    }

    // 前置 --
    self& operator--() {
        decrement();
        return *this;
    }

    // 后置 --
    self operator--(int) {
        self tmp = *this;
        decrement();
        return tmp;
    }
};
```

- `increment()` 是实现 **中序遍历的“下一个节点”** 的核心函数。
- `decrement()` 是实现 **中序遍历的“前一个节点”** 的核心函数。
- SGI STL 为了支持 `end()` 和 `rbegin()` 的正确性，引入了一个特殊的 **header 节点**，它的结构特殊（颜色为红，父节点的父节点指向自己），这是实现 `++end()`、`--begin()` 的关键。
- 所有节点都包含 `parent` 指针，因此可以非常方便地“向上追踪”。

![image-20250728182504622](./RB-Tree（上）.assets/image-20250728182504622.png)

`increment()` 的状况4：
当迭代器指向的是整棵树的最大节点，执行 `++` 时会指向 `header`，也就是 `end()`。

`decrement()` 的状况1：
当迭代器是 `end()`（即指向 `header`）时，执行 `--`，实际返回的是最大节点（最右节点）。

### RB-tree 的数据结构

下面是红黑树（RB-tree）的定义简述：

- 使用专属的空间配置器，每次分配一个节点大小的内存。
- 定义了多种类型，用于管理整棵红黑树的数据结构。
- 包含一个仿函数（functor），用于比较节点的大小，保证树的有序性。
- 提供了若干成员函数，用于插入、删除、查找等操作。

这些设计保证了红黑树的灵活性和高效性。

```cpp
template <class Key, class Value, class KeyOfValue, class Compare, class Alloc = allocator>
class rb_tree {
protected:
    typedef void* void_pointer;
    typedef _rb_tree_node_base* base_ptr;      // 基础节点指针类型
    typedef _rb_tree_node<Value> rb_tree_node; // 节点类型
    typedef simple_alloc<rb_tree_node, Alloc> rb_tree_node_allocator; // 节点空间配置器
    typedef _rb_tree_color_type color_type;    // 颜色类型（红或黑）

public:
    // 基本类型定义
    typedef Key key_type;
    typedef Value value_type;
    typedef value_type* pointer;
    typedef const value_type* const_pointer;
    typedef value_type& reference;
    typedef const value_type& const_reference;
    typedef rb_tree_node* link_type;    // 节点指针类型
    typedef size_t size_type;
    typedef ptrdiff_t difference_type;

protected:
    // 内存分配与释放
    link_type get_node() { return rb_tree_node_allocator::allocate(); }
    void put_node(link_type p) { rb_tree_node_allocator::deallocate(p); }

    // 创建节点并构造内容
    link_type create_node(const value_type& x) {
        link_type tmp = get_node();
        _STLTRY {
            construct(&tmp->value_field, x); // 构造节点数据
        } _STL_UNWIND(put_node(tmp));
        return tmp;
    }

    // 复制节点（值和颜色），左右子节点置空
    link_type clone_node(link_type x) {
        link_type tmp = create_node(x->value_field);
        tmp->color = x->color;
        tmp->left = 0;
        tmp->right = 0;
        return tmp;
    }

    // 销毁节点，释放内存
    void destroy_node(link_type p) {
        destroy(&p->value_field);
        put_node(p);
    }

protected:
    // 树的主要数据成员
    size_type node_count;    // 节点数量
    link_type header;        // 特殊节点，作为树的“头”

    Compare key_compare;     // 节点键值比较函数对象（仿函数）

    // 通过header访问根节点和极值节点
    link_type& root() const { return (link_type&) header->parent; }
    link_type& leftmost() const { return (link_type&) header->left; }
    link_type& rightmost() const { return (link_type&) header->right; }

    // 节点成员访问的静态函数，方便操作节点指针
    static link_type& left(link_type x) { return (link_type&)(x->left); }
    static link_type& right(link_type x) { return (link_type&)(x->right); }
    static link_type& parent(link_type x) { return (link_type&)(x->parent); }
    static reference value(link_type x) { return x->value_field; }
    static const Key& key(link_type x) { return KeyOfValue()(value(x)); }
    static color_type& color(link_type x) { return (color_type&)(x->color); }

    // 以上函数对base_ptr同样支持，方便类型转换

    // 查找子树最小、最大节点
    static link_type minimum(link_type x) { return (link_type)_rb_tree_node_base::minimum(x); }
    static link_type maximum(link_type x) { return (link_type)_rb_tree_node_base::maximum(x); }

public:
    typedef _rb_tree_iterator<value_type, reference, pointer> iterator;

private:
    iterator _insert(base_ptr x, base_ptr y, const value_type& v);
    link_type _copy(link_type x, link_type p);
    void _erase(link_type x);

    void init() {
        header = get_node();           // 分配header节点
        color(header) = _rb_tree_red;  // header标记为红色（区别于root）
        root() = 0;
        leftmost() = header;           // header左右指向自己（空树时）
        rightmost() = header;
    }

public:
    // 构造和析构
    rb_tree(const Compare& comp = Compare()) : node_count(0), key_compare(comp) { init(); }
    ~rb_tree() {
        clear();
        put_node(header);
    }

    // 访问器
    Compare key_comp() const { return key_compare; }
    iterator begin() { return leftmost(); }  // 最小节点
    iterator end() { return iterator(header); } // header代表end()
    bool empty() const { return node_count == 0; }
    size_type size() const { return node_count; }
    size_type max_size() const { return size_type(-1); }

    // 插入和删除接口（详细实现略）
    pair<iterator, bool> insert_unique(const value_type& x);
    iterator insert_equal(const value_type& x);
    // ...
};
```

- 该类通过模板支持任意键值类型及比较函数，实现泛型红黑树。
- 通过专门的节点空间配置器管理内存。
- 利用 `header` 节点实现树根、最左、最右节点的快速访问。
- 采用静态函数简化对节点指针的操作和类型转换。
- 预留了插入、删除、复制、遍历等接口和操作。