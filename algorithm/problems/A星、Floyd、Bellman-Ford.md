---
title: A星、Floyd、Bellman-Ford
date: 2024-09-20 08:42:32 +0800
categories: [algorithm, problems]
tags: [Algorithm, A*, Floyd, Bellman-Ford]
description: 
---
## A 星算法

A 星和 Dijkstra 算法唯一区别在于堆中排序的依据。distance 数组仍然保存实际代价，预估代价只影响堆的弹出顺序。

- Dijkstra 根据`源点到当前点的实际代价`进行排序。

- A 星根据`源点到当前点的实际代价 + 当前点到终点的预估代价`进行排序

预估函数要求：`当前点到终点的预估代价 <= 当前点到终点的实际代价`，越接近越快

常用选择：曼哈顿距离、欧氏距离、对角线距离（行差值列差值绝对值的最大值）

## Floyd 算法

Floyd 算法是一种用于解决所有节点对之间最短路径问题的算法。它通过动态规划的思想，逐步计算出所有节点对之间的最短路径。

Floyd 算法使用一个二维数组 distance 来记录节点对之间的最短距离。初始时，distance\[i\]\[j\] 表示节点 i 到节点 j 的直接距离（如果存在边），否则为无穷大。算法通过三重循环不断更新 distance 数组，最终得到所有节点对之间的最短路径。

Floyd 算法的核心思想是动态规划。外层循环控制中间节点 k，内层两个循环分别遍历起点 i 和终点 j。如果通过节点 k 可以使 i 到 j 的距离更短，则更新 distance\[i\]\[j\]。重复此过程，直到所有节点都被遍历过。

diatance\[i\]\[j\] 表示 i 和 j 的最短距离，更新：`distance[i][j] = min(distance[i][j], distance[i][k] + distance[k][j])`

- 时间复杂度：`O(n^3)`，空间复杂度：`O(n^2)`，常数时间小，容易实现
- 不适用于存在负环的图

```c++
int main() {
    // n * n 的矩阵
    int n = 10;
    // 其实就是带权图的邻接矩阵
    vector<vector<int>> distance(n, vector<int>(n, INT_MAX));
    
    // 省略 distance 根据给出的边进行初始化
    
    // i 经过 k 到达 j
    for (int k = 0; k < n; ++k)
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < n; ++j)
                if (distance[i][k] != INT_MAX
                    && distance[k][j] != INT_MAX
                    && distance[i][j] > distance[i][k] + distance[k][j])
                    distance[i][j] = distance[i][k] + distance[k][j];
}
```

### [P2910 [USACO08OPEN] Clear And Present Danger S](https://www.luogu.com.cn/problem/P2910)

```c++
#include <iostream>
#include <vector>
#include <algorithm>
#include <queue>

using namespace std;

int main() {
    int n, m;
    cin >> n >> m;
    // 找宝藏的路径
    vector<int> path(m);
    for (int i = 0; i < m; ++i) {
        // 序号从 1 开始
        cin >> path[i];
        // 序号从 0 开始
        path[i]--;
    }

    vector<vector<int>> distance(n, vector<int>(n, 0x7fffffff));
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            cin >> distance[i][j];

    for (int k = 0; k < n; ++k)
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < n; ++j)
                if (distance[i][k] != 0x7fffffff
                    && distance[k][j] != 0x7fffffff
                    && distance[i][j] > distance[i][k] + distance[k][j])
                    distance[i][j] = distance[i][k] + distance[k][j];

    int res = 0;
    for (int i = 0; i + 1 < m; ++i)
        res += distance[path[i]][path[i + 1]];
    cout << res;
}
```

## Bellman-Ford 算法

解决==可以有负边但不能有负环==的图，求单源最短路径的算法。

**Bellman-Ford 过程**：每一轮考察每条边，每条边都尝试进行松弛操作，那么若干点的 distance 会变小。当某一轮发现不再有松弛操作出现时，算法停止。

**Bellman-Ford 算法时间复杂度**：假设点的数量为 N，边的数量为 M，每一轮时间复杂度 O(M)。最短路存在的情况下，因为 1 次松弛操作会使 1 个点的最短路的边数 +1。而从源点出发到任何点的最短路最多走过全部的 n 个点，所以松弛的轮数必然 <= n - 1。所以Bellman-Ford算法时间复杂度 O(M*N)

**重要推广**：==判断从某个点出发能不能到达负环==。上面已经说了，如果从A出发存在最短路（没有负环），那么松弛的轮数必然 <= n - 1。而如果从A点出发到达一个负环，那么松弛操作显然会无休止地进行下去。所以，如果发现从A点出发，在第n轮时松弛操作依然存在，说明从A点出发能够到达一个负环。可以通过设置一个虚拟源点（与原来所有的点都有连接），==判断图是否有负环==。

### ChatGPT 给出的介绍

Bellman-Ford 算法的关键思想是通过**多次松弛操作**（relaxation）逐步逼近每个顶点的最短路径，最终在迭代结束时，能够正确确定从源点到所有点的最短路径。要理解为什么每一轮松弛能确定一些点的最短距离，可以从以下几个方面解释：

#### 1. 松弛操作的定义

松弛操作的过程是通过检查从某一顶点到另一顶点之间的边，看看是否可以通过这个顶点找到一条更短的路径。如果可以，那么就更新目标顶点的最短距离。

对于每条边 (u, v) ，如果：`dist[v] > dist[u] + weight(u, v)`
那么就更新：`dist[v] = dist[u] + weight(u, v)`

#### 2. 多轮松弛的作用

假设图中有 V 个顶点，最坏情况下，==从源点到一个顶点的最短路径可能包含最多 V - 1 条边==。因此，Bellman-Ford 算法执行 V - 1 ==轮==松弛操作，确保可以找到源点到任意顶点的最短路径。

每一轮松弛都会检查所有边，并尝试通过更短的路径更新节点的最短距离。对于一条最短路径上恰好有 k 条边的节点，==最多==需要 k 轮松弛来确定该节点的最短距离。

#### 3. 每轮松弛确定某些点的最短距离

==在第 i 轮松弛中，Bellman-Ford 算法会确保从源点到任何节点的最短路径最多经过 i 条边==。因此，经过 i 轮松弛后，所有最短路径包含 i 条或更少边的节点的最短距离都会被确定。随着轮数的增加，更多节点的最短路径距离会被确定。

特别是，当执行到第 V - 1 轮时，所有节点的最短距离都会被确定，因为最长的简单路径（不包含环）最多包含  V - 1 条边。

#### 4. 确定最短路径

通过多次松弛操作，Bellman-Ford 算法最终能保证：
- 如果某个点的最短路径被更新为一个值，那么这个值是正确的，因为此时它已经不能通过任何进一步的松弛获得更短的路径。
- 所以，每一轮松弛后，至少有一些点的最短距离是最终值，不会再发生变化。

#### 5. 总结

每一轮松弛都能确定一部分节点的最短路径，因为它==逐渐考虑到从源点到每个节点经过不同数量边的路径==。经过最多 V - 1 轮后，所有点的最短路径都会被确定。因此，每一轮松弛后，某些点的最短路径是最终的且不会再改变。

### [787. K 站中转内最便宜的航班](https://leetcode.cn/problems/cheapest-flights-within-k-stops/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>
#include <queue>

using namespace std;

class Solution {
public:
    // 阉割版 Bellman-Ford
    int findCheapestPrice(int n, vector<vector<int>> &flights, int src, int dst, int k) {
        vector<int> cur(n, INT_MAX);
        cur[src] = 0;
        for (int i = 0; i <= k; ++i) {
            vector<int> nxt(cur);
            for (const auto &edge: flights) {
                if (cur[edge[0]] == INT_MAX) continue;
                // 从旧表中取数据更新，标准的 Bellman—Ford 是从新表中取
                nxt[edge[1]] = min(nxt[edge[1]], cur[edge[0]] + edge[2]);
            }
            cur = nxt;
        }
        return cur[dst] == INT_MAX ? -1 : cur[dst];
    }
};
```

### [P3385 【模板】负环](https://www.luogu.com.cn/problem/P3385)

```c++
#include <iostream>
#include <vector>
#include <algorithm>
#include <queue>

using namespace std;

int n, m, T;
const int MAX_VAL = 0x7fffffff;

// 链式前向星
vector<int> head;
vector<int> nxt;
vector<int> to;
vector<int> weight;
int cnt;

void initGraph() {
    // 点的下标从 1 开始
    head.resize(n + 1, 0);
    nxt.resize((m << 1) + 1);
    to.resize((m << 1) + 1);
    weight.resize((m << 1) + 1);
    fill(begin(head), end(head), 0);
    cnt = 1;
}

void addEdge(int u, int v, int w) {
    nxt[cnt] = head[u];
    to[cnt] = v;
    weight[cnt] = w;
    head[u] = cnt;
    cnt++;
}

// Bellman-Ford
// 从 1 到各个点的最短距离
vector<int> distances;
// 存放上一轮松弛中有变动的点
queue<int> q;
// 是否在队列中
vector<bool> enter;
// 记录点的松弛次数
vector<int> updateCnt;

void initBellmanFord() {
    distances.resize(n + 1, MAX_VAL);
    enter.resize(n + 1, false);
    updateCnt.resize(n + 1, 0);
    fill(begin(distances), end(distances), MAX_VAL);
    fill(begin(enter), end(enter), false);
    fill(begin(updateCnt), end(updateCnt), 0);
}

void clearQueue() {
    queue<int> empty;
    swap(q, empty);
}

// 从顶点 1 出发是否能到达负环
bool hasNegativeCircle() {
    distances[1] = 0;
    updateCnt[1]++;
    q.emplace(1);
    enter[1] = true;

    while (!q.empty()) {
        int u = q.front();
        q.pop();
        enter[u] = false;
        for (int ei = head[u]; ei > 0; ei = nxt[ei]) {
            int v = to[ei];
            int w = weight[ei];
            // 没法松弛就跳过
            if (distances[v] <= distances[u] + w) continue;
            distances[v] = distances[u] + w;
            // 在队列就跳过
            if (enter[v]) continue;
            // 到 v 点的路径被松弛了一次
            updateCnt[v]++;
            if (updateCnt[v] >= n) return true;
            q.emplace(v);
            enter[v] = true;
        }
    }
    return false;
}

int main() {
    cin >> T;
    // 每组测试用例
    for (int i = 0; i < T; ++i) {
        cin >> n >> m;
        // 初始化
        initGraph();
        initBellmanFord();
        clearQueue();
        // 建图
        for (int j = 0, u, v, w; j < m; ++j) {
            cin >> u >> v >> w;
            if (w >= 0) {
                addEdge(u, v, w);
                addEdge(v, u, w);
            } else {
                addEdge(u, v, w);
            }
        }
        cout << (hasNegativeCircle() ? "YES" : "NO") << endl;
    }
}
```
