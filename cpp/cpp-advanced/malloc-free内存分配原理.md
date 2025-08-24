## malloc-free 内存分配原理

- `malloc` 通过 **arena** 管理堆，每次分配先在 **bins** 中找合适的空闲 **chunk**，找不到就从 **top chunk** 切割或用 **mmap**；
- `free` 则把 chunk 放回 bins，必要时与相邻空闲块合并，但通常不会立即归还操作系统。

### 基本概念

| 操作                 | 描述                                               |
| -------------------- | -------------------------------------------------- |
| `malloc(size)`       | 从堆上分配 `size` 字节内存，返回指向该内存块的指针 |
| `free(ptr)`          | 释放之前通过 `malloc` 获取的内存                   |
| `calloc(n, size)`    | 分配 `n * size` 字节并初始化为 0                   |
| `realloc(ptr, size)` | 重新调整已分配内存的大小                           |

- **malloc 管理的内存被分成一块块叫做 chunk 的小块**，每个 chunk 是内存分配的基本单位，包含了元数据（chunk头）和用户数据区。

- 这些 chunk 根据大小分类，**被组织成多个链表（bins）**，每个链表管理一组大小相近或特定范围内的空闲 chunk。

- 当调用 `malloc(size)` 时，系统会去对应大小范围的那个链表里找合适的 chunk，如果找到合适的空闲块，就分配；找不到则从大块或者系统申请新的内存。

- **因此，整个 malloc 管理的内存就是很多个“chunk 链表”的集合**，每个链表负责管理特定大小的 chunk，保证快速分配和释放。

### chunk

`chunk` 是 `malloc` 和 `free` 背后用于管理堆内存的最基本单元。可以把每一个 `malloc` 出来的内存块看成是一个 `chunk` 的“用户区域（user area）”，而系统在它前面隐藏了一段元信息（metadata），用于管理这块内存。

#### chunk 的内存结构

以 64 位系统为例，glibc 中一个 `chunk` 的结构大致如下：

```css
		   +------------------+
           | prev_size        | ← 仅在前一个 chunk 是空闲时才有效
           +------------------+
           | size             | ← 当前 chunk 的大小及标志位（is_free 等）
ptr -->    +------------------+ ← malloc 返回的是这个地址之后的 user data
           | user data...     | ← 返回给用户使用的内存区域
           | padding (可选)   |
           +------------------+
           | next chunk...    |
```

- `prev_size`：前一个 chunk 的大小，仅在前一个 chunk 是空闲块时才使用（用于合并操作）。
- `size`：当前 chunk 的总大小（包括 metadata + user data），最低几个 bit 储存状态位：
  - bit 0 (`PREV_INUSE`)：前一个 chunk 是否被使用
  - bit 1 (`IS_MMAPPED`)：是否是通过 `mmap` 分配的
  - bit 2 (`NON_MAIN_ARENA`)：是否属于主 arena（线程局部分配支持）
- `user data`：返回给用户的区域，`malloc` 实际返回的是 `chunk + sizeof(metadata)` 的地址。

#### chunk 的分类

根据大小不同，glibc 会将 chunk 分类管理：

| 类型        | 范围（glibc 默认） | 管理方式                           |
| ----------- | ------------------ | ---------------------------------- |
| fast chunk  | ≤ 64 字节（小）    | fastbin，单向链表，不合并          |
| small chunk | 小于 512 字节      | small bins，精确分类，双向循环链表 |
| large chunk | ≥ 512 字节         | large bins，有序双向链表           |
| mmap chunk  | 通常 ≥ 128 KB      | 直接使用 `mmap` 管理               |

#### chunk 生命周期

分配（malloc）伪代码：

```c
void* malloc(size_t size) {
    // 1. 计算实际所需大小（包括元数据，并按对齐要求向上对齐）
    size_t real_size = align(size + sizeof(chunk_header));

    // 2. 查找一个合适大小的空闲 chunk（可能来自 fastbin、small bin 等）
    chunk* c = find_free_chunk(real_size);

    // 3. 如果找不到空闲块，则向系统申请新内存（调用 sbrk 或 mmap）
    if (!c) {
        c = request_more_memory(real_size);
    }

    // 4. 设置 chunk 的 size 字段，并标记前一个 chunk 为 in use
    c->size = real_size | PREV_INUSE;

    // 5. 返回指向用户数据部分的指针（跳过 chunk header）
    return (void*)(c + 1);
}

```

释放（free）伪代码：

```c
void free(void* ptr) {
    // 1. 找到对应的 chunk（ptr 是用户数据的起始地址，chunk 在其前面）
    chunk* c = (chunk*)ptr - 1;

    // 2. 清除使用标志（标记该 chunk 为 free）
    c->size &= ~IN_USE;

    // 3. 尝试与前后相邻的空闲 chunk 合并，减少内存碎片
    try_merge_with_adjacent_chunks(c);

    // 4. 将当前 chunk 加入空闲链表（如 fastbin、tcache、bins 等）
    add_to_bin_list(c);

    // 5. 特殊情况：若该 chunk 是大块或 mmap 分配的，可能直接返回给系统
}
```

### bins

在 glibc 的 `malloc` 实现中（即 `ptmalloc`），**bins** 是用于管理空闲 `chunk` 的核心机制。你可以把它们理解为**内存回收仓库**：当你调用 `free` 时，系统并不总是立刻归还内存给操作系统，而是把这块内存扔进一个 bin，供下次 `malloc` 复用。

`bin` 是一个保存空闲 chunk 的数据结构。每种 bin 管理一定大小范围的 chunk，便于快速分配与回收。所有 bin 都是通过**双向链表**管理空闲 chunk 的。

#### bin 的分类（glibc 默认配置）

| Bin 类型         | 大小范围（64 位）    | 是否合并 | 是否有序     | 是否加锁       | 使用场景              | 说明                                   |
| ---------------- | -------------------- | -------- | ------------ | -------------- | --------------------- | -------------------------------------- |
| **tcache**       | ≤ 1032 字节（默认）  | 否       | 否           | 否（线程局部） | 高频小块 malloc/free  | 线程私有，速度最快，每类最多缓存 7 个  |
| **fast bins**    | ≤ 64 字节（默认）    | 否       | 否           | 否             | 极快的小块释放        | 释放时不合并，适合频繁小分配           |
| **small bins**   | 64~512 字节          | 是       | 否           | 是             | 中等分配需求          | 精确分类管理，支持合并空闲块，效率稳定 |
| **large bins**   | > 512 字节           | 是       | 是（按大小） | 是             | 较大对象复用          | 合并空闲块，有序链表，支持首次适配     |
| **unsorted bin** | 所有释放下来的 chunk | 是       | 否           | 是             | 中转站与首次复用机会  | 所有合并后的 chunk 首先进入该 bin      |
| **top chunk**    | 堆空间最顶端         | 是       | 否           | 是             | 无可用 chunk 时扩展堆 | 系统分配来源，通常通过 sbrk 扩展堆     |
| **mmap chunk**   | 通常 >128 KB         | 否       | 否           | 是             | 特大内存块分配        | 直接通过 mmap 分配，释放立即归还系统   |

#### 说明图示

```css
+---------------------+
|        malloc       |
+---------+-----------+
          |
          v
   [ tcache (线程局部) ] ←---优先命中
          |
          v
   [ fastbin (≤64B) ] ←----简单 LIFO 栈，不合并
          |
          v
 [ unsorted bin ] ←-- 所有 free 的 chunk 先到这里
          |
          +--> [ small bin (≤512B) ] ← 精确大小链表，无序
          |
          +--> [ large bin (>512B) ] ← 有序链表，可按需查找
          |
          v
   [ top chunk ] ←-- 堆尾，必要时用 sbrk 扩展
```

```css
+--------------------+
|       free         |
+---------+----------+
          |
          v
   判断 chunk 类型
          |
          +--> 是 mmap chunk？ →→→ munmap()，直接归还系统
          |
          +--> 是 tcache 可接受？ →→→ 放入 tcache（线程局部缓存）
          |
          +--> 是 fastbin 适用？ →→→ 放入 fastbin（不合并）
          |
          v
  与前后 chunk 尝试合并（coalescing）
          |
          v
  放入 unsorted bin（中转站）
          |
          +--> 后续整理进入：
                  |
        +---------+----------+
        |                    |
        v                    v
 [ small bin (≤512B) ]   [ large bin (>512B) ]

```

### arena

`arena` 是 `glibc` 的 `malloc` 实现（ptmalloc）中非常核心的概念，尤其是在多线程程序中，它负责管理分配内存的上下文环境。可以将 `arena` 理解为**堆内存管理的容器或管理者**，它负责：

- 管理一块堆（heap）区域；
- 分配/释放内存 chunk；
- 管理 bins（fastbin、small bin、large bin 等）；
- 维护锁（保证线程安全）；
- 在多线程场景下支持并行分配。

#### 什么是 arena

`arena` 是一个 **独立的 malloc 管理单元**，每个 arena 拥有一组 bins 和一个 top chunk。默认主线程使用 **main arena**，其他线程可以使用或新建非主 arena，以减少锁冲突。

#### arena 的结构（简化）

```c
struct malloc_state {
    mutex_t mutex;           // 加锁保护
    mchunkptr fastbinsY[NFASTBINS];
    mchunkptr bins[NBINS * 2];
    mchunkptr top;           // 顶部 chunk
    mchunkptr last_remainder;
    heap_info* heap;         // 关联堆区信息
    struct malloc_state* next; // 指向下一个 arena
    ...
};
```

每个 arena 就是一个 `malloc_state`，它拥有自己的一套 bin 体系。

#### 为什么需要多个 arena

在多线程程序中，单一锁（如只用 `main_arena`）会成为瓶颈：

- 如果所有线程都访问主 arena，会频繁加锁阻塞；
- 为了解决这个问题，glibc 使用**多 arena **架构；
- 每个线程在 malloc/free 时尝试使用一个独立的 arena，这样多个线程可以并行分配内存。

#### arena 的分配逻辑

```css
malloc/free 请求：
   ↓
当前线程是否已有 arena？
   ↓                  ↘
是，用这个 arena     否，从 arena 链表中选一个空闲 arena
                         ↓
                 找不到？创建新的 arena（调用 mmap）
```

#### 创建新 arena 的条件：

- 系统支持线程；
- 当前 arena 数量 < 配额（默认根据 CPU 核心数）；
- 使用 `mmap` 创建一个新的堆区域；
- 设置 arena 与 heap 的映射。

### glibc 内存管理结构图

```css
         多线程下
+----------------------------+
|        Thread A            |
+----------------------------+
            |
            v
      +-------------+                     +-------------+
      | main_arena  |   ← 所有线程共享     | arena #2    |
      +-------------+                     +-------------+
            |                                   |
            |                                   |
            v                                   v
  +---------------------+           +----------------------+
  | malloc_state struct |           | malloc_state struct  |
  +---------------------+           +----------------------+
  | - fastbinsY[N]      | ---> [ chunk* -> chunk* -> ... ]    ← LIFO, 无序
  | - small bins[]      | ---> [ size class 1: chunk <-> chunk ]
  | - large bins[]      | ---> [ size class N: chunk <-> chunk ]
  | - unsorted bin      | ---> [ chunk <-> chunk ]            ← free 后先放这里
  | - top chunk         | ---> [ chunk ]                      ← 堆尾部 chunk
  | - mutex             |
  +---------------------+

⬇ 每个 bin（fastbin / small bin / large bin）结构：
    双向链表 / 单向链表，管理空闲 chunk

    chunk 结构如下（简化）：
        +-----------------------+
        |   prev_size (可选)   | ← 若前一个 chunk 空闲
        +-----------------------+
        |     size + flags     | ← PREV_INUSE, mmap 标志等
        +-----------------------+
        |     user data        | ← malloc 返回的是这个地址
        |         ...          |
        +-----------------------+
        |     padding / align  |
        +-----------------------+

⬇ chunk 生命周期：
   malloc()：
      1. 查找 tcache / bins 中合适的空闲 chunk；
      2. 若没有则向 top chunk 请求或扩展（sbrk/mmap）；
      3. 设置 size 标志位，返回 user_data。
   free()：
      1. 放入 tcache / fastbin；
      2. 或合并后放入 unsorted bin，再整理到 small/large；

```

| 组件       | 包含内容 / 管理对象                            |
| ---------- | ---------------------------------------------- |
| arena      | 一组 bins、一个 top chunk、mutex               |
| bins       | 多条链表，按 chunk 大小分类管理空闲块          |
| chunk      | 最小分配单元，有 metadata + 用户数据           |
| tcache     | 每线程私有的 chunk 缓存，最先查找              |
| top chunk  | 当前堆空间尾部 chunk，用于分配新内存           |
| mmap chunk | 超大块直接映射的 chunk，独立存在，不在 bins 中 |

### 高效使用 malloc 的建议

- 尽量复用对象，减少频繁分配与释放
- 对小块对象可考虑内存池（如 `boost::pool`）
- 避免在多线程中使用共享数据结构申请内存
- 使用工具检查内存泄漏和越界

### 相关数据结构

#### 1. `task_struct` — 进程描述符（进程控制块 PCB）

- `task_struct` 是 Linux 内核中表示**一个进程（或线程）**的结构体，类似于操作系统中的进程控制块（PCB）。
- 它包含了进程的全部信息，包括进程状态、调度信息、父子关系、信号处理、文件描述符表、内存空间信息等。

主要作用

- 维护进程的生命周期和状态。
- 进程调度时根据其中的调度字段决定执行顺序。
- 进程管理和系统调用的基础。

`task_struct` 简化版

```c
// linux/sched.h (简化)
struct task_struct {
    volatile long state;         // 进程状态，如 TASK_RUNNING, TASK_INTERRUPTIBLE 等

    struct thread_struct thread; // 线程相关寄存器和上下文信息

    struct mm_struct *mm;        // 指向进程的内存描述符 mm_struct，管理虚拟地址空间

    pid_t pid;                   // 进程ID
    pid_t tgid;                  // 线程组ID，线程属于同一进程的标识

    struct task_struct *parent;  // 父进程指针
    struct list_head children;   // 子进程链表
    struct list_head sibling;    // 兄弟进程链表（父进程的子链表）

    struct files_struct *files;  // 进程打开的文件描述符集合指针
    struct fs_struct *fs;        // 进程文件系统相关信息

    unsigned int flags;          // 进程标志，用于状态标识等
    int priority;                // 进程调度优先级

    struct signal_struct *signal; // 信号处理相关信息

    // 调度实体，内核调度时使用
    struct sched_entity se;
    struct sched_dl_entity dl;

    // 其他字段省略
};
```

#### 2. `mm_struct` — 进程的内存管理描述符

- `mm_struct` 是与进程的**虚拟地址空间**相关的数据结构，描述了该进程的内存布局和管理信息。
- 它通常被 `task_struct` 中的 `mm` 字段引用。
- 包含了进程所有虚拟内存区域（`vm_area_struct`）链表、页表指针、内存使用统计等。

主要作用

- 管理进程的虚拟内存空间（堆、栈、代码段、数据段、共享库、mmap 映射等）。
- 管理进程页表，进行地址转换和内存保护。
- 负责内存映射、内存分配、页面交换（swap）等功能。

`mm_struct` 简化版

```c
// linux/mm_types.h (简化)
struct mm_struct {
    struct mm_struct *mmd_next;        // 内核链表指针，连接所有 mm_struct

    atomic_t mm_users;                 // 该 mm_struct 被多少线程共享（引用计数）
    atomic_t mm_count;                 // mm_struct 的总体引用计数

    struct vm_area_struct *mmap;       // 虚拟内存区域链表头，每个节点表示一段连续的虚拟内存区
    int map_count;                     // 虚拟内存区域数量

    unsigned long start_code, end_code; // 代码段虚拟地址起始和结束
    unsigned long start_data, end_data; // 数据段虚拟地址起始和结束
    unsigned long start_brk, brk;       // 堆区起始地址和当前断点（堆尾）
    unsigned long start_stack;          // 栈起始地址

    struct rw_semaphore mmap_sem;       // 保护 mmap 链表的读写锁，防止并发冲突

    pgd_t *pgd;                         // 顶层页目录指针（页表根），用于虚拟地址到物理地址转换

    // 内存使用统计
    unsigned long total_vm;             // 进程使用的虚拟内存总页数
    unsigned long rss;                  // 驻留集大小，进程实际使用的物理内存页数
    unsigned long locked_vm;            // 被锁定在内存中不可换出的页数

    struct anon_vma *anon_vma;          // 匿名内存的管理结构
    struct file *exe_file;              // 进程可执行文件对应的文件结构

    // 其他字段省略
};
```

- `start_brk` 是堆的起始地址

- `brk` 是当前堆尾的地址（程序断点）

- 堆内存是由一连串连续的 `vm_area_struct` 组成的虚拟内存区域（VMA）

- 对堆的操作就是调整 `brk` 的值，同时修改或新增对应的 VMA

#### 3. 它们的关系

```css
task_struct
  └── mm_struct (指向该进程的内存空间描述符)
       └── vm_area_struct 链表（虚拟内存区域列表）
```

- `task_struct` 表示进程整体，`mm_struct` 具体描述该进程的内存布局。
- 线程共享进程地址空间时，会共享同一个 `mm_struct`。

### 相关系统调用

#### 1. `brk()` 和 `sbrk()`

##### `brk()` / `sbrk()` 在内核中的核心动作

- 用户态调用 `brk()` / `sbrk()`，系统调用进入内核。

- 内核通过当前进程的 `mm_struct` 访问和管理进程地址空间。

- 内核调用 `do_brk()` 函数，试图将**程序断点**调整到目标地址。

- 过程大致：

  1. **参数校验**：目标断点地址是否合理（≥ `start_brk` 且不超过最大堆大小限制）。

  2. **加锁**：使用 `mmap_sem` 写锁，防止并发操作修改进程虚拟内存。

  3. **查找堆所在的虚拟内存区域**：遍历 `mmap` 链表，找到堆对应的 VMA。

  4. **调整虚拟内存区域**：

     - 如果断点地址增加，内核扩展堆对应 VMA 的 `vm_end`，并且分配新的物理页面映射。

     - 如果断点地址减少，释放多余页面，并更新 VMA 大小。

  5. **更新 `mm_struct->brk` 为新断点地址**。

  6. **释放锁，返回结果**。

> ##### 程序断点（Program Break）概念
>
> - 程序断点是进程虚拟内存中堆区的结束边界，堆从 `end_of_data_segment` 起始，堆尾就是程序断点。
> - 通过移动程序断点，可以动态增加或减少进程堆的大小。
> - 操作系统保证程序断点位置和进程数据段空间一致。
>
> ```txt
> 高地址
> +-------------------------+
> |      栈 Stack           |  <--- grows downward（向下增长）
> +-------------------------+
> |      映射区 mmap 区域   |  <--- 包含共享库/匿名映射（malloc大块等）
> +-------------------------+
> |                         |
> |       ↑                 |
> |       |                 |
> |      堆 Heap            |  <--- 向上增长
> |       |                 |
> |       ↓                 |
> |-------------------------|  
> | program break（brk）    |  ←←←← 当前断点：堆的顶部（sbrk/brk 调整）
> |-------------------------|
> | end_of_data_segment     |  ←←←← 堆的起点（BSS/data之后）
> |-------------------------|
> |   BSS（未初始化数据）   |
> |-------------------------|
> | Data（已初始化全局/静态）|
> |-------------------------|
> | Text（代码段）          |  <--- 只读，向上增长
> +-------------------------+
> 低地址
> ```

##### `brk()` 与 `sbrk()` 的关系

- `brk(void *addr)` 直接设置断点到 `addr`。

- `sbrk(intptr_t increment)` 是基于当前断点增加（或减少）指定字节数，内部其实调用的是 `brk()` 设置新断点。

- 这两个调用都会经过同样的内核路径，调用 `do_brk()` 完成实际内存映射调整。

##### 内核中相关核心代码（示意）

```c
long do_brk(unsigned long addr)
{
    struct mm_struct *mm = current->mm;
    unsigned long new_brk = addr;

    // 堆的起点
    unsigned long start_brk = mm->start_brk;

    if (new_brk < start_brk)
        return -EINVAL;

    down_write(&mm->mmap_sem);  // 加写锁保护

    // 找到堆对应的虚拟内存区域
    struct vm_area_struct *vma = find_vma(mm, start_brk);
    if (!vma || vma->vm_start != start_brk) {
        up_write(&mm->mmap_sem);
        return -ENOMEM;
    }

    if (new_brk > vma->vm_end) {
        // 扩展堆区：增加VMA大小，申请页框映射
        // 内核调用 vm_brk_extend()
    } else if (new_brk < vma->vm_end) {
        // 缩小堆区，释放页框
        // 内核调用 vm_brk_shrink()
    }

    mm->brk = new_brk;  // 更新断点
    up_write(&mm->mmap_sem);

    return 0; // 成功
}
```

##### `sbrk()` 库函数的内核调用（简化版）

```c
void *sbrk(intptr_t increment)
{
    unsigned long old_brk = (unsigned long)sbrk(0); // 当前断点地址
    unsigned long new_brk = old_brk + increment;

    if (brk((void *)new_brk) != 0) {
        return (void *)-1;  // 失败
    }
    return (void *)old_brk;  // 返回原断点
}
```

##### 总结

| 操作         | 说明                                             | 关联 `mm_struct` 字段         |
| ------------ | ------------------------------------------------ | ----------------------------- |
| 设置断点     | 调整进程堆区结束位置，控制动态内存区域大小       | `mm->brk` （堆尾断点地址）    |
| 保护同步     | 避免多个线程同时操作虚拟内存区域造成数据不一致   | `mm->mmap_sem` （VMA链表锁）  |
| 虚拟内存区域 | 堆是连续的虚拟内存区域，用 `vm_area_struct` 描述 | 通过 `mm->mmap` 找到对应堆VMA |
| 物理内存映射 | 扩展堆时，映射新的物理页面；缩小时释放物理页面   | 内核负责维护页表映射          |

#### 2. `mmap()`

##### 函数原型

```c
#include <sys/mman.h>

void *mmap(void *addr, size_t length, int prot, int flags,
           int fd, off_t offset);
```

| 参数     | 含义                                                         |
| -------- | ------------------------------------------------------------ |
| `addr`   | **建议映射的起始地址**，可为 `NULL`，让系统自动选择地址      |
| `length` | **映射区域的大小**（字节）                                   |
| `prot`   | **访问权限**，可组合使用，如：  `PROT_READ` 读  `PROT_WRITE` 写  `PROT_EXEC` 执行 |
| `flags`  | **映射类型和共享属性**，常见的：  `MAP_SHARED` 映射可共享   `MAP_PRIVATE` 写时拷贝私有映射   `MAP_ANONYMOUS` 匿名映射（无文件） |
| `fd`     | 映射的文件描述符（对于 `MAP_ANONYMOUS` 可为 `-1`）           |
| `offset` | 文件偏移地址（必须是页大小的整数倍）                         |

##### 常见用法示例

1. **匿名内存分配（等价于 malloc，大块内存分配）**

```c
void *ptr = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
                 MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
```

- 用于无文件的内存申请
- glibc 的 malloc 在分配大于 128KB 内存时就用 `mmap()` 而不是 `sbrk()`

2. **映射文件到内存（文件读写）**

```c
int fd = open("data.txt", O_RDONLY);
struct stat st;
fstat(fd, &st);
char *data = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
```

- 将整个文件映射到内存，之后可像数组一样读数据

3. **共享内存映射（多进程共享）**

```c
void *shared = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
                    MAP_SHARED | MAP_ANONYMOUS, -1, 0);
```

- 多个进程使用 `fork()` 后可访问这块共享内存

##### 返回值与错误

- 成功：返回映射区域首地址
- 失败：返回 `MAP_FAILED`（即 `(void *) -1`）

##### mmap vs brk/sbrk

| 特性         | `sbrk()` / `brk()`               | `mmap()`                 |
| ------------ | -------------------------------- | ------------------------ |
| 内存区域     | **堆（heap）区**                 | 任意区域（非连续）       |
| 动态分配来源 | 增长或缩小 heap                  | 系统页映射（匿名或文件） |
| 多线程安全性 | 不安全（改变全局 program break） | 安全（不影响其他线程）   |
| 分配大块内存 | 可能碎片严重                     | 更适合大块（glibc策略）  |
| 是否释放内存 | `free` 不一定收回 sbrk 区        | `munmap()` 可立即释放    |

##### 内核视角（简略）

- 用户调用 `mmap()` 后，内核在当前进程的 `mm_struct` 中：
  - 为映射区域创建一个新的 `vm_area_struct`（VMA）
  - 分配页表映射（匿名页或文件页）
  - 更新 `mmap` 链表并保护一致性
- 核心函数：`do_mmap()`

##### 释放映射内存：`munmap()`

```c
int munmap(void *addr, size_t length);
```

用于释放之前映射的内存，避免内存泄露。

##### 常见问题

1. **为什么 malloc 有时不用 sbrk？**
   - 小内存（<128KB）用 sbrk 增加堆；
   - 大内存直接用 mmap 更灵活、安全、可回收。
2. **mmap 映射失败常见原因？**
   - `offset` 不是页对齐；
   - 权限或 flags 设置冲突；
   - 映射长度非法。