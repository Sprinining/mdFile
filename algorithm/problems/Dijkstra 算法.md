## 普通堆实现的 Dijkstra 算法

- 时间复杂度为 `O(m * logm)`，m 为边数
- Dijkstra 算法不能处理边带有负权的情况

Dijkstra 算法是一种用于解决带权图最短路径问题的算法。它通过贪心策略逐步找到从源节点到其他节点的最短路径。

Dijkstra 算法维护一个==距离数组==，用于记录从源节点到其他节点的最短距离。算法从源节点开始，依次找出距离源节点最近的未访问节点，并更新其邻居节点的距离。重复此过程，直到所有节点都被访问过。

Dijkstra 算法可以使用==小根堆==来实现。首先将源节点的距离设为 0，并将其加入优先队列。然后循环执行以下步骤：从小根堆中取出距离最小的节点，遍历其邻居节点，如果通过该节点到达邻居节点的距离更短，则更新邻居节点的距离，并将其加入小根堆。当小根堆为空时，算法结束。

1. `distance[i]` 表示从源点到 i 点的最短距离，`visited[i]` 表示 i 节点是否从小根堆弹出过

2. 准备好小根堆，`小根堆`存放记录：`（x 点，源点到 x 的距离）`，小根堆根据距离排序

3. 令 distance[源点] = 0，（源点，0）入堆

4. 从小根堆弹出（u 点，源点到 u 的距离）

   a. 如果 visited[u] == true，啥也不做，重复步骤 4

   b. 如果 visited[u] == false，令 visited[u] = true，u 就算弹出过了，

   ​	然后考察 u 的每一条边，假设某条边去往 v 点，边权为 w

   ​	1）如果 visited[v] == false 并且 distance[u] + w < distance[v]，

   ​	令 distace[v] = distance[u] + w，**把（v，distance[u] + w)加入小根堆**

   ​	2）处理完 u 的每条边后重复步骤 4

5. 小根堆为空，过程结束。

### [P4779 【模板】单源最短路径（标准版）](https://www.luogu.com.cn/problem/P4779)

```c++
#include <iostream>
#include <vector>
#include <algorithm>
#include <queue>

using namespace std;

struct cmp {
    bool operator()(pair<int, int> &p1, pair<int, int> &p2) {
        return p1.second > p2.second;
    }
};

int main() {
    int n, m, s;
    cin >> n >> m >> s;

    vector<vector<pair<int, int>>> graph(n + 1);
    // 建图
    for (int i = 0, u, v, w; i < m; ++i) {
        cin >> u >> v >> w;
        graph[u].emplace_back(make_pair(v, w));
    }

    // 标记是否从堆中弹出过
    vector<bool> visited(n + 1, false);
    priority_queue<pair<int, int>, vector<pair<int, int>>, cmp> heap;
    vector<int> distances(n + 1, 0x7fffffff);
    // 源点入堆
    heap.emplace(make_pair(s, 0));
    distances[s] = 0;

    while (!heap.empty()) {
        auto top = heap.top();
        heap.pop();
        int u = top.first;
        if (visited[u]) continue;
        visited[u] = true;
        for (const auto &item: graph[u]) {
            int v = item.first;
            int w = item.second;
            if (visited[v]) continue;
            if (distances[v] > distances[u] + w) {
                distances[v] = distances[u] + w;
                heap.emplace(make_pair(v, distances[v]));
            }
        }
    }

    for (int i = 1; i <= n; ++i)
        cout << distances[i] << " ";
}
```

### [743. 网络延迟时间](https://leetcode.cn/problems/network-delay-time/)

```c++
#include <iostream>
#include <vector>
#include <unordered_set>
#include <algorithm>
#include <queue>

using namespace std;

class Solution {
public:

    struct cmp {
        bool operator()(pair<int, int> &p1, pair<int, int> &p2) {
            return p1.second > p2.second;
        }
    };

    // 节点编号从 1 开始
    int networkDelayTime(vector<vector<int>> &times, int n, int k) {
        // 邻接表建图
        vector<vector<pair<int, int>>> graph(n + 1);
        for (const auto &item: times)
            graph[item[0]].emplace_back(make_pair(item[1], item[2]));

        // 记录从源点到每个点的距离
        vector<int> distance(n + 1, INT_MAX);
        // 记录是否从堆中弹出过
        vector<int> visited(n + 1, false);
        // 小根堆：（u，源点到 u 的距离）
        priority_queue<pair<int, int>, vector<pair<int, int>>, cmp> heap;
        // k 到自身距离为 0
        heap.emplace(make_pair(k, 0));
        distance[k] = 0;

        while (!heap.empty()) {
            auto p = heap.top();
            heap.pop();
            int u = p.first;
            // 已经确定距离的不再处理
            if (visited[u] == true) continue;
            visited[u] = true;
            for (const auto &item: graph[u]) {
                int v = item.first;
                int w = item.second;
                // 已经确定距离的不再处理
                if (visited[v] == true) continue;
                // 尝试源点在经过 u 的情况下到达 v ，是否可以使到达 v 的距离缩短
                if (distance[v] > distance[u] + w) {
                    distance[v] = distance[u] + w;
                    // 这条边入堆
                    heap.emplace(v, distance[v]);
                }
            }
        }

        int res = 0;
        for (int i = 1; i <= n; ++i) {
            // 有的点到达不了
            if (distance[i] == INT_MAX) return -1;
            res = max(res, distance[i]);
        }
        return res;
    }
};
```

## 反向索引堆实现 Dijkstra 算法

- 时间复杂度为 `O(m * logn)`，m 为边数，n 为节点数

- 堆中存放`（u，d）`，根据 d 排序。普通堆无法找到指定 u 在实现堆的底层数组中的具体位置。反向索引堆的实现需要建立一张`反向索引表`，记录 u 在数组中的位置，这样就能直接在堆中修改 u 的 d 信息，然后调整堆，同时也要调整反向索引表。

1. 把（源点，0）加入反向索引堆，过程开始

2. 反向索引堆弹出（u，源点到 u 的距离），考察 u 的每条边，假设某条边去往 v，边权为 w

   a. 如果 v 没有进入过反向索引堆，新增记录（v，源点到 u 的距离 + w）

   b. 如果 v 曾经从反向索引堆弹出过，忽略

   c. 如果 v 在反向索引堆里，看看源点到 v 的距离能否变小，能就调整堆，否则跳过

   d. 处理完 u 的每条边，重复步骤 2

3. 反向索引堆为空过程结束。distance 里记录了源点到每个点的最短距离。

### [P4779 【模板】单源最短路径（标准版）](https://www.luogu.com.cn/problem/P4779)

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int n, m, s;

// 链式前向星
vector<int> head;
vector<int> nxt;
vector<int> to;
vector<int> weight;
int cnt;

void initGraph() {
    // 点的编号从 1 开始
    // resize 只会将新增的位置设置为新的值
    head.resize(n + 1, 0);
    fill(head.begin(), head.end(), 0);
    nxt.resize(m + 1);
    to.resize(m + 1);
    weight.resize(m + 1);
    // 边的编号从 1 开始
    cnt = 1;
}

void addEdge(int u, int v, int w) {
    nxt[cnt] = head[u];
    to[cnt] = v;
    weight[cnt] = w;
    head[u] = cnt;
    cnt++;
}

vector<int> heap;
int heapSize;
// 反向索引表
// where[v] = -2，表示v这个节点，已经弹出过了
// where[v] = -1，表示v这个节点，从来没有进入过堆
// where[v] = i(>=0)，表示 v 这个节点，在堆上的 i 位置
// 所有 where 的 set 操作都包含在堆的操作中
vector<int> where;
// 记录源点到目标点的最短距离
// 所有 distances 的 set 操作与堆的操作分离
vector<int> distances;

void initHeap() {
    heap.resize(n);
    heapSize = 0;
    // 初始状态都没进过堆
    where.resize(n + 1, -1);
    fill(where.begin(), where.end(), -1);
    // 初始最短距离都是无穷大
    distances.resize(n + 1, 0x7fffffff);
    fill(distances.begin(), distances.end(), 0x7fffffff);
}

// 自顶向下调整堆
void adjustHeapTopDown(int curIndex) {
    auto temp = heap[curIndex];
    int leftChildIndex = 2 * curIndex + 1;
    while (leftChildIndex <= (heapSize - 1)) {
        if ((leftChildIndex < heapSize - 1)
            && distances[heap[leftChildIndex]] > distances[heap[leftChildIndex + 1]])
            leftChildIndex++;
        if (distances[heap[leftChildIndex]] >= distances[temp]) break;
        heap[curIndex] = heap[leftChildIndex];
        // 修改反向索引表
        where[heap[leftChildIndex]] = curIndex;
        curIndex = leftChildIndex;
        leftChildIndex = 2 * curIndex + 1;
    }
    heap[curIndex] = temp;
    // 修改反向索引表
    where[temp] = curIndex;
}

// 自下而上调整堆
void adjustHeapBottomUP(int curIndex) {
    auto temp = heap[curIndex];
    int parentIndex = (curIndex - 1) / 2;
    while (parentIndex >= 0) {
        if (distances[heap[parentIndex]] <= distances[temp]) break;
        heap[curIndex] = heap[parentIndex];
        // 修改反向索引表
        where[heap[parentIndex]] = curIndex;
        curIndex = parentIndex;
        if (curIndex == 0) break;
        parentIndex = (curIndex - 1) / 2;
    }
    heap[curIndex] = temp;
    // 修改反向索引表
    where[temp] = curIndex;
}


void addToHeap(int v) {
    heap[heapSize] = v;
    heapSize++;
    adjustHeapBottomUP(heapSize - 1);
}

int getTop() {
    int res = heap[0];
    heap[0] = heap[heapSize - 1];
    heapSize--;
    adjustHeapTopDown(0);
    where[res] = -2;
    return res;
}

void addOrUpdateOrIgnore(int v, int d) {
    if (where[v] == -2) {
        return;
    } else if (where[v] == -1) {
        distances[v] = d;
        // v 不在堆中，新增记录
        addToHeap(v);
    } else if (where[v] >= 0) {
        // 经过 u 点到达 v 点能使源点到达 v 点距离更短，就更新
        if (distances[v] > d) {
            distances[v] = d;
            // 修改堆中原有的那条，再向上调整（距离变短，只需要往上调整）
            adjustHeapBottomUP(where[v]);
        }
    }
}

int main() {
    cin >> n >> m >> s;

    // 建图
    initGraph();
    for (int i = 0, u, v, w; i < m; ++i) {
        cin >> u >> v >> w;
        addEdge(u, v, w);
    }

    initHeap();
    addOrUpdateOrIgnore(s, 0);

    while (heapSize > 0) {
        int u = getTop();
        for (int edge = head[u]; edge != 0; edge = nxt[edge])
            addOrUpdateOrIgnore(to[edge], distances[u] + weight[edge]);
    }

    for (int i = 1; i <= n; ++i)
        cout << distances[i] << " ";
}
```

### [743. 网络延迟时间](https://leetcode.cn/problems/network-delay-time/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int n, m, s;

// 链式前向星
vector<int> head;
vector<int> nxt;
vector<int> to;
vector<int> weight;
int cnt;

void initGraph() {
    // 点的编号从 1 开始
    // resize 只会将新增的位置设置为新的值
    head.resize(n + 1, 0);
    fill(head.begin(), head.end(), 0);
    nxt.resize(m + 1);
    to.resize(m + 1);
    weight.resize(m + 1);
    // 边的编号从 1 开始
    cnt = 1;
}

void addEdge(int u, int v, int w) {
    nxt[cnt] = head[u];
    to[cnt] = v;
    weight[cnt] = w;
    head[u] = cnt;
    cnt++;
}

vector<int> heap;
int heapSize;
// 反向索引表
// where[v] = -2，表示v这个节点，已经弹出过了
// where[v] = -1，表示v这个节点，从来没有进入过堆
// where[v] = i(>=0)，表示 v 这个节点，在堆上的 i 位置
// 所有 where 的 set 操作都包含在堆的操作中
vector<int> where;
// 记录源点到目标点的最短距离
// 所有 distances 的 set 操作与堆的操作分离
vector<int> distances;

void initHeap() {
    heap.resize(n);
    heapSize = 0;
    // 初始状态都没进过堆
    where.resize(n + 1, -1);
    fill(where.begin(), where.end(), -1);
    // 初始最短距离都是无穷大
    distances.resize(n + 1, 0x7fffffff);
    fill(distances.begin(), distances.end(), 0x7fffffff);
}

// 自顶向下调整堆
void adjustHeapTopDown(int curIndex) {
    auto temp = heap[curIndex];
    int leftChildIndex = 2 * curIndex + 1;
    while (leftChildIndex <= (heapSize - 1)) {
        if ((leftChildIndex < heapSize - 1)
            && distances[heap[leftChildIndex]] > distances[heap[leftChildIndex + 1]])
            leftChildIndex++;
        if (distances[heap[leftChildIndex]] >= distances[temp]) break;
        heap[curIndex] = heap[leftChildIndex];
        // 修改反向索引表
        where[heap[leftChildIndex]] = curIndex;
        curIndex = leftChildIndex;
        leftChildIndex = 2 * curIndex + 1;
    }
    heap[curIndex] = temp;
    // 修改反向索引表
    where[temp] = curIndex;
}

// 自下而上调整堆
void adjustHeapBottomUP(int curIndex) {
    auto temp = heap[curIndex];
    int parentIndex = (curIndex - 1) / 2;
    while (parentIndex >= 0) {
        if (distances[heap[parentIndex]] <= distances[temp]) break;
        heap[curIndex] = heap[parentIndex];
        // 修改反向索引表
        where[heap[parentIndex]] = curIndex;
        curIndex = parentIndex;
        if (curIndex == 0) break;
        parentIndex = (curIndex - 1) / 2;
    }
    heap[curIndex] = temp;
    // 修改反向索引表
    where[temp] = curIndex;
}


void addToHeap(int v) {
    heap[heapSize] = v;
    heapSize++;
    adjustHeapBottomUP(heapSize - 1);
}

int getTop() {
    int res = heap[0];
    heap[0] = heap[heapSize - 1];
    heapSize--;
    adjustHeapTopDown(0);
    where[res] = -2;
    return res;
}

void addOrUpdateOrIgnore(int v, int d) {
    if (where[v] == -2) {
        return;
    } else if (where[v] == -1) {
        distances[v] = d;
        // v 不在堆中，新增记录
        addToHeap(v);
    } else if (where[v] >= 0) {
        // 经过 u 点到达 v 点能使源点到达 v 点距离更短，就更新
        if (distances[v] > d) {
            distances[v] = d;
            // 修改堆中原有的那条，再向上调整（距离变短，只需要往上调整）
            adjustHeapBottomUP(where[v]);
        }
    }
}

class Solution {
public:
    int networkDelayTime(vector<vector<int>> &times, int N, int k) {
        n = N;
        m = times.size();
        s = k;

        // 建图
        initGraph();
        for (const auto &item: times)
            addEdge(item[0], item[1], item[2]);

        initHeap();
        addOrUpdateOrIgnore(s, 0);

        while (heapSize > 0) {
            int u = getTop();
            for (int edge = head[u]; edge != 0; edge = nxt[edge])
                addOrUpdateOrIgnore(to[edge], distances[u] + weight[edge]);
        }

        int res = 0;
        for (int i = 1; i <= n; ++i) {
            if (distances[i] == 0x7fffffff)
                return -1;
            res = max(res, distances[i]);
        }
        return res;
    }
};
```

## 其他练习题

### [1631. 最小体力消耗路径](https://leetcode.cn/problems/path-with-minimum-effort/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>
#include <queue>

using namespace std;

class Solution {
public:
    struct cmp {
        bool operator()(vector<int> &v1, vector<int> &v2) {
            return v1[2] > v2[2];
        }
    };

    vector<int> move{-1, 0, 1, 0, -1};
    int rows, columns;

    bool isCoordinateLegal(int row, int column) {
        return row >= 0 && row < rows && column >= 0 && column < columns;
    }

    int minimumEffortPath(vector<vector<int>> &heights) {
        rows = heights.size();
        columns = heights[0].size();
        // 源点到各个点的体力值，记录的是这条路上相邻格子高度差绝对值的最大值
        vector<vector<int>> distance(rows, vector<int>(columns, INT_MAX));
        // 标记是否从堆中弹出过
        vector<vector<bool>> visited(rows, vector<bool>(columns, false));
        // (x, y, 体力值)，根据体力值排序
        priority_queue<vector<int>, vector<vector<int>>, cmp> heap;

        // 源点入堆
        heap.emplace(vector<int>{0, 0, 0});
        distance[0][0] = 0;

        while (!heap.empty()) {
            auto t = heap.top();
            heap.pop();
            int x = t[0];
            int y = t[1];
            int cost = t[2];
            if (x == rows - 1 && y == columns - 1) return cost;
            if (visited[x][y]) continue;
            visited[x][y] = true;

            for (int i = 0; i < 4; ++i) {
                int nx = x + move[i];
                int ny = y + move[i + 1];
                // 非法或者已经从堆弹出过，就忽略
                if (!isCoordinateLegal(nx, ny) || visited[nx][ny]) continue;
                // 相邻高度差的绝对值
                int gap = abs(heights[nx][ny] - heights[x][y]);
                // 这条路径到点 [nx, ny] 的体力值
                // 以前的代价是路径长度，这题的代价是这条路上相邻格子高度差绝对值的最大值
                int newCost = max(cost, gap);
                // 代价可以变小，就更新
                if (newCost < distance[nx][ny]) {
                    distance[nx][ny] = newCost;
                    heap.emplace(vector<int>{nx, ny, newCost});
                }
            }
        }
        return -1;
    }
};
```

### [778. 水位上升的泳池中游泳](https://leetcode.cn/problems/swim-in-rising-water/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>
#include <queue>

using namespace std;

class Solution {
public:
    struct cmp {
        bool operator()(vector<int> &v1, vector<int> &v2) {
            return v1[2] > v2[2];
        }
    };

    vector<int> move{-1, 0, 1, 0, -1};
    int rows, columns;

    bool isCoordinateLegal(int row, int column) {
        return row >= 0 && row < rows && column >= 0 && column < columns;
    }

    int swimInWater(vector<vector<int>> &grid) {
        rows = grid.size();
        columns = grid[0].size();

        // 源点到各个点的最小游泳时间
        vector<vector<int>> distance(rows, vector<int>(columns, INT_MAX));
        // 标记是否从堆中弹出过
        vector<vector<bool>> visited(rows, vector<bool>(columns, false));
        // (x, y, 最小游泳时间)，根据最小游泳时间排序
        priority_queue<vector<int>, vector<vector<int>>, cmp> heap;

        // 至少要等到时间 grid[0][0]
        distance[0][0] = grid[0][0];
        heap.emplace(vector<int>{0, 0, grid[0][0]});

        while (!heap.empty()) {
            auto t = heap.top();
            heap.pop();
            int x = t[0];
            int y = t[1];
            int cost = t[2];
            if (x == rows - 1 && y == columns - 1) return cost;
            if (visited[x][y]) continue;
            visited[x][y] = true;

            for (int i = 0; i < 4; ++i) {
                int nx = x + move[i];
                int ny = y + move[i + 1];
                // 非法或者已经从堆弹出过，就忽略
                if (!isCoordinateLegal(nx, ny) || visited[nx][ny]) continue;
                // 新的代价是游到附近所要等待的最大时间
                int newCost = max(cost, grid[nx][ny]);
                // 代价可以变小，就更新
                if (newCost < distance[nx][ny]) {
                    distance[nx][ny] = newCost;
                    heap.emplace(vector<int>{nx, ny, newCost});
                }
            }
        }
        return -1;
    }
};
```

