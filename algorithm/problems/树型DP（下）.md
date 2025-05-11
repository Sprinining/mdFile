## 树型DP（下）

### [2477. 到达首都的最少油耗](https://leetcode.cn/problems/minimum-fuel-cost-to-report-to-the-capital/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int MAXN = 100001;
    // 无向图
    int MAXM = 200001;

    // 链式前向星
    // 下标：顶点编号，值：该顶点第一条边的边号
    vector<int> head;
    // 下标：边号，值：下一条边的边号
    vector<int> nxt;
    // 下标：边号，值：去往的顶点编号
    vector<int> to;
    // 边号计数，从 1 开始，0 表示没有边
    int cnt;

    Solution() {
        head.resize(MAXN);
        nxt.resize(MAXM);
        to.resize(MAXM);
    }

    void build() {
        cnt = 1;
        fill(head.begin(), head.end(), 0);
    }

    void addEdge(int u, int v) {
        nxt[cnt] = head[u];
        to[cnt] = v;
        head[u] = cnt;
        cnt++;
    }

    long long minimumFuelCost(vector<vector<int>> &roads, int seats) {
        int n = roads.size() + 1;
        // 建立无向图
        build();
        for (const auto &item: roads) {
            addEdge(item[0], item[1]);
            addEdge(item[1], item[0]);
        }

        // 节点总数
        vector<int> count(n);
        // 油耗总数
        vector<long> cost(n);

        fc(n, seats, 0, -1, count, cost);
        return cost[0];
    }

    // u 为当前节点，p 为父节点
    void fc(int n, int seats, int u, int p, vector<int> &count, vector<long> &cost) {
        count[u] = 1;
        // 遍历从 u 节点出发的每一条边
        for (int ei = head[u]; ei > 0; ei = nxt[ei]) {
            // 邻接点编号
            int v = to[ei];
            // 父节点就跳过，确保是从上往下遍历
            if (v == p) continue;
            fc(n, seats, v, u, count, cost);
            // 加上下游的节点总数与油耗
            count[u] += count[v];
            cost[u] += cost[v];
            // 再加上邻接点到当前节点产生的油耗
            cost[u] += (count[v] + seats - 1) / seats;
        }
    }
};
```

### [2246. 相邻字符不同的最长路径](https://leetcode.cn/problems/longest-path-with-different-adjacent-characters/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

struct Info {
    // 必须以当前节点往下所形成的路径长度的最大值，包含自身
    int maxLenFromRoot;
    // 整棵树上的最长路径
    // 可能是经过当前节点 v，由以 v 为端的最长路径和次长路径拼接得到
    // 也可能不经过 v，由 v 的下游提供
    int maxLen;

    Info(int m, int maxLen) : maxLenFromRoot(m), maxLen(maxLen) {}
};

class Solution {
public:
    int MAXN = 100001;
    int MAXM = 200001;

    vector<int> head;
    vector<int> nxt;
    vector<int> to;
    int cnt;

    Solution() {
        head.resize(MAXN);
        nxt.resize(MAXM);
        to.resize(MAXM);
    }

    void build() {
        cnt = 1;
        fill(head.begin(), head.end(), 0);
    }

    void addEdge(int u, int v) {
        nxt[cnt] = head[u];
        to[cnt] = v;
        head[u] = cnt;
        cnt++;
    }

    int longestPath(vector<int> &parent, string str) {
        int n = parent.size();

        // 建立无向图
        build();
        for (int i = 1; i < n; ++i) {
            addEdge(i, parent[i]);
            addEdge(parent[i], i);
        }

        vector<char> s(begin(str), end(str));
        s.push_back('\0');

        return fc(0, parent[0], s).maxLen;
    }

    // 返回任意一对相邻节点都没有分配到相同字符的最长路径
    Info fc(int u, int p, vector<char> &s) {
        // 没有邻边时的返回值
        if (head[u] <= 0) return Info(1, 1);

        // 以当前节点往下所形成的路径长度的最大值和次大值，包含自身
        int m1 = 1;
        int m2 = 0;
        int maxLen = 1;
        // 遍历邻边 u->v
        for (int ei = head[u]; ei > 0; ei = nxt[ei]) {
            int v = to[ei];
            // 是父节点就跳过
            if (v == p) continue;

            Info infoV = fc(v, u, s);
            maxLen = max(maxLen, infoV.maxLen);
            if (s[u] != s[v]) {
                // 字符不一样
                if (infoV.maxLenFromRoot + 1 >= m1) {
                    m2 = m1;
                    m1 = infoV.maxLenFromRoot + 1;
                } else if (infoV.maxLenFromRoot + 1 > m2) {
                    m2 = infoV.maxLenFromRoot + 1;
                }
            }
        }
        maxLen = max(maxLen, m1 + m2 - 1);
        return Info(m1, maxLen);
    }
};
```

### [2458. 移除子树后的二叉树高度](https://leetcode.cn/problems/height-of-binary-tree-after-subtree-removal-queries/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

struct TreeNode {
    int val;
    TreeNode *left;
    TreeNode *right;

    TreeNode() : val(0), left(nullptr), right(nullptr) {}

    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}

    TreeNode(int x, TreeNode *left, TreeNode *right) : val(x), left(left), right(right) {}
};

int MAXN = 100002;
// 下标为节点的值
vector<int> dfn(MAXN);
// 下标为 dfn 序号，记录根节点到当前节点经过的边数
vector<int> deep(MAXN);
// 下标为 dfn 序号，记录这棵树的节点总数
vector<int> cnt(MAXN);
// 辅助数组，用于快速在 size 数组去除一段后找最值
vector<int> maxL(MAXN, 0);
vector<int> maxR(MAXN, 0);
int dfnCnt;


class Solution {
public:
    vector<int> treeQueries(TreeNode *root, vector<int> &queries) {
        dfnCnt = 0;
        fc(root, 0);

        for (int i = 1; i <= dfnCnt; ++i)
            maxL[i] = max(maxL[i - 1], deep[i]);
        maxR[dfnCnt + 1] = 0;
        for (int i = dfnCnt; i >= 1; i--)
            maxR[i] = max(maxR[i + 1], deep[i]);

        int m = queries.size();
        vector<int> res(m);
        for (int i = 0; i < m; ++i) {
            int index = dfn[queries[i]];
            int leftMax = maxL[index - 1];
            int rightMax = maxR[index + cnt[index]];
            res[i] = max(leftMax, rightMax);
        }
        return res;
    }

    // 根节点到当前节点经过了 k 条边
    void fc(TreeNode *node, int k) {
        // dfn 序号从 1 开始
        int i = ++dfnCnt;
        // 记录 dfn 序号
        dfn[node->val] = i;
        deep[i] = k;

        cnt[i] = 1;
        // 累加上左右子树的节点数
        if (node->left != nullptr) {
            fc(node->left, k + 1);
            cnt[i] += cnt[dfn[node->left->val]];
        }
        if (node->right != nullptr) {
            fc(node->right, k + 1);
            cnt[i] += cnt[dfn[node->right->val]];
        }
    }
};
```

### [2322. 从树中删除边的最小分数](https://leetcode.cn/problems/minimum-score-after-removals-on-a-tree/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>
#include <forward_list>

using namespace std;

int MAXN = 1001;
// 下标为原始节点编号，dfn 序号从 1 开始
vector<int> dfn(MAXN);
// 下标为 dfn 序号
vector<int> xorSum(MAXN);
// 下标为 dfn 序号
vector<int> cnt(MAXN);
int dfnCnt;
// 邻接表
vector<forward_list<int>> graph(MAXN);

class Solution {
public:

    // 无向图建图
    void undirectedGraph(vector<vector<int>> &edges) {
        for (const auto &edge: edges) {
            graph[edge[0]].emplace_front(edge[1]);
            graph[edge[1]].emplace_front(edge[0]);
        }
    }

    int minimumScore(vector<int> &nums, vector<vector<int>> &edges) {
        int n = nums.size();
        int m = edges.size();
        int res = INT_MAX;

        // 清理全局变量
        dfn.assign(MAXN, 0);
        xorSum.assign(MAXN, 0);
        cnt.assign(MAXN, 0);
        dfnCnt = 0;
        for (auto &g: graph) g.clear();

        // 生成图
        undirectedGraph(edges);
        // 遍历并记录
        fc(nums, 0);

        // 枚举被删除的两条边的所有可能
        for (int i = 0; i < m; ++i) {
            // 第一条被删除的边连着的两个节点的 dfn 序号较大者
            int a = max(dfn[edges[i][0]], dfn[edges[i][1]]);
            for (int j = i + 1; j < m; ++j) {
                // 第二条被删除的边连着的两个节点的 dfn 序号较大者
                int b = max(dfn[edges[j][0]], dfn[edges[j][1]]);
                // 判断 a，b 先后
                int pre = a < b ? a : b;
                int post = a + b - pre;
                // 连通子图的异或和
                int sum1 = xorSum[post];
                int sum2, sum3;
                if (post < pre + cnt[pre]) {
                    // 存在祖先关系
                    sum2 = xorSum[pre] ^ xorSum[post];
                    sum3 = xorSum[1] ^ xorSum[pre];
                } else {
                    sum2 = xorSum[pre];
                    sum3 = xorSum[1] ^ sum1 ^ sum2;
                }
                int maxVal = max(max(sum1, sum2), sum3);
                int minVal = min(min(sum1, sum2), sum3);
                res = min(res, maxVal - minVal);
            }
        }
        return res;
    }

    // u 是原始编号，遍历整棵树，记录 dfn 序号、异或和、节点数
    void fc(vector<int> &nums, int u) {
        int i = ++dfnCnt;
        dfn[u] = i;
        xorSum[i] = nums[u];
        cnt[i] = 1;
        for (const auto &v: graph[u]) {
            // v 节点已经处理过
            if (dfn[v] != 0) continue;
            fc(nums, v);
            xorSum[i] ^= xorSum[dfn[v]];
            cnt[i] += cnt[dfn[v]];
        }
    }
};
```

### [P2014 [CTSC1997] 选课](https://www.luogu.com.cn/problem/P2014)

- 时间复杂度：O（n \* 每个节点的平均孩子数 \* （m 的平方））

```c++
#include <iostream>
#include <vector>
#include <forward_list>

using namespace std;

const int MAXN = 301;
// 记录课程的学分
vector<int> nums(MAXN, 0);
// 邻接表，实际课程编号 1~n，增加了一个编号 0 的虚节点，把多个子树都接在 0 号节点下面
vector<vector<int>> graph(MAXN);
// dp[i][j][k]: 当前根节点为 i，在 i 号节点、及其 i 号节点下方的前 j 棵子树上挑选节点
// 共 k 个，且挑选的节点连成一片，返回最大的累加和
vector<vector<vector<int>>> dp(MAXN, vector<vector<int>>(MAXN, vector<int>(MAXN, -1)));

// 返回最大的累加和
int fc(int i, int j, int k) {
    // 一个都不选
    if (k == 0) return 0;
    // 只能选 i 号节点
    if (j == 0 || k == 1) return nums[i];
    if (dp[i][j][k] != -1) return dp[i][j][k];

    // p1: 第 j 个子树上一个都不选
    int res = fc(i, j - 1, k);
    // 第 j 棵子树根节点 v
    int v = graph[i][j - 1];
    // p2: 尝试第 j 个子树上选 s 个，在 i 的前 j - 1 棵子树上选 k - s 个
    for (int s = 1; s < k; s++)
        res = max(res, fc(i, j - 1, k - s) + fc(v, graph[v].size(), s));
    dp[i][j][k] = res;
    return res;
}

int main() {
    int n, m;
    cin >> n >> m;
    // 多出的一个名额给必须选择的 0 号虚节点
    m++;

    for (int i = 1, pre; i <= n; i++) {
        cin >> pre;
        // 录入先导课程编号 pre 与当前 i 号课程所形成的边
        graph[pre].push_back(i);
        // 以及 i 号课程的学分
        cin >> nums[i];
    }

    cout << fc(0, graph[0].size(), m) << endl;
    return 0;
}
```

- 时间复杂度：O（n \* m）

```c++
#include <iostream>
#include <vector>
#include <forward_list>

using namespace std;

int MAXN = 301;
int MAXM = 301;

// 链式前向星
vector<int> head(MAXN);
vector<int> nxt(MAXM);
vector<int> to(MAXM);
// 边序号从 1 开始
int edgeCnt;

void addEdge(int u, int v) {
    nxt[edgeCnt] = head[u];
    to[edgeCnt] = v;
    head[u] = edgeCnt;
    edgeCnt++;
}

// 下标为原始节点编号，值为 dfn 序号
vector<int> dfn(MAXN + 1);
// 下标为 dfn 序号，记录这个节点能获得的学分
vector<int> val(MAXN + 1);
// 下标为 dfn 序号，记录节点总数
vector<int> cnt(MAXN + 1);
// dfn 序号，从 1 开始
int dfnCnt;

// dp[i][j]: dfn 序号 i ~ n+1 范围的节点，选择 j 个节点一定要形成有效结构的情况下，最大的累加和
vector<vector<int>> dp(MAXN + 2, vector<int>(MAXN));

// 记录课程的学分
vector<int> nums(MAXN, 0);

void build() {
    edgeCnt = 1;
    dfnCnt = 0;
    fill(begin(head), end(head), 0);
    fill(begin(dp), end(dp), vector<int>(MAXN, 0));
}

// 遍历树，记录 dfn 序号、树的节点总数
void fc(int u) {
    // 原始节点编号 u 的 dfn 序号
    int i = ++dfnCnt;
    dfn[u] = i;
    val[i] = nums[u];
    cnt[i] = 1;
    // 遍历邻边 u->v
    for (int ei = head[u]; ei > 0; ei = nxt[ei]) {
        int v = to[ei];
        fc(v);
        cnt[i] += cnt[dfn[v]];
    }
}

int compute(int n, int m) {
    // 原始节点编号 0~n，dfn 序号 1~n+1
    // 根据 dfn 序号逆序遍历，对当前的根节点进行如下操作
    // 选择的总节点数从 1 尝试到 m
    // p1: 不要当前节点
    // 那么当前节点及其子树，也就是 dfn 序号 i~i + cnt[i] -1 范围的都不能选，因为不能连成一片
    // 只能从 dfn 序号 i + cnt[i] 开始往后选 j 个节点，即 dp[i + cnt[i]][j]
    // p2: 要当前节点
    // 剩下 j-1 个节点从 dfn 序号 i+1~n+1 范围内选，即 dp[i + 1][j - 1]，再加上当前值 val[i]
    // 这些节点在加了一个虚拟头节点的情况下，就能连成一片
    for (int i = n + 1; i >= 2; i--) {
        for (int j = 1; j <= m; j++) {
            // p1，p2 两种情况选最大值
            dp[i][j] = max(dp[i + cnt[i]][j], val[i] + dp[i + 1][j - 1]);
        }
    }
    return dp[2][m];
}

int main() {
    int n, m;
    cin >> n >> m;

    build();

    // 原始节点编号 0~n
    for (int i = 1, pre; i <= n; i++) {
        cin >> pre;
        // 录入先导课程编号 pre 与当前 i 号课程所形成的边
        addEdge(pre, i);
        // 以及 i 号课程的学分
        cin >> nums[i];
    }

    fc(0);

    cout << compute(n, m) << endl;
    return 0;
}
```