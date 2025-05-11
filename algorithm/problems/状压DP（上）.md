## 状压DP（上）

### [464. 我能赢吗](https://leetcode.cn/problems/can-i-win/)

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    bool canIWin(int n, int m) {
        if (m == 0) return true;
        // 所有的数加起来都小于 m
        if (n * (n + 1) / 2 < m) return false;
        // dp[status] == -1：没算过
        // dp[status] == 0：false
        // dp[status] == 1：true
        // status 二进制的低 n + 1 位用来表示状态，1 表示能选，0 不能选，第 0 位不用，第 1 到 n 位对应数字 1~n
        // 如果 1~7 范围的数字，4、2 已经选了不能再选，那么 status 的低 8 位为：
        // 1 1 1 0 1 0 1 1
        // 7 6 5 4 3 2 1 0
        vector<int> dp(1 << (n + 1), -1);
        return fc(n, (1 << (n + 1)) - 1, m, dp);
    }

    // 当前的选手能否赢
    bool fc(int n, int status, int rest, vector<int> &dp) {
        if (rest <= 0) return false;
        if (dp[status] != -1) return dp[status] == 1;
        bool res = false;
        for (int i = 1; i <= n; ++i) {
            // i 没有被选过，且当前选手选了 i 之后，对手在 i 已经被选过的情况下输掉
            if ((status & (1 << i)) != 0 && !fc(n, (status ^ (1 << i)), rest - i, dp)) {
                res = true;
                break;
            }
        }
        dp[status] = res ? 1 : 0;
        return res;
    }
};
```

### [473. 火柴拼正方形](https://leetcode.cn/problems/matchsticks-to-square/)

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    bool makesquare(vector<int> &matchsticks) {
        int sum = 0;
        for (const auto &item: matchsticks)
            sum += item;
        if (sum % 4 != 0) return false;
        int n = matchsticks.size();
        vector<int> dp(1 << n, 0);
        // status = (1 << n) - 1 表示低 n 位全 1，所有的火柴都尚未被选择
        return fc(matchsticks, sum / 4, (1 << n) - 1, 0, 4, dp);
    }

    // len: 用掉所有火柴构造出的正方形的边长
    // status: 记录火柴的选取情况，二进制位为 1 表示未被选择
    // cur: 当前要生成的边已经形成的长度
    // rest: 待生成的边的总数
    bool fc(vector<int> &nums, int len, int status, int cur, int rest, vector<int> &dp) {
        // 所有火柴用光的情况下拼成正方形
        if (rest == 0) return status == 0;
        if (dp[status] != 0) return dp[status] == 1;
        bool res = false;
        for (int i = 0; i < nums.size(); ++i) {
            // 尝试每一根二进制位为 1 的即未被使用过的火柴，且加上后，当前边长度不能超出最终的边长
            if ((status & (1 << i)) != 0 && cur + nums[i] <= len) {
                if (cur + nums[i] == len) {
                    // 刚好能生成一个完整的边
                    res = fc(nums, len, status ^ (1 << i), 0, rest - 1, dp);
                } else {
                    // 还差一些
                    res = fc(nums, len, status ^ (1 << i), cur + nums[i], rest, dp);
                }
                if (res) break;
            }
        }
        dp[status] = res ? 1 : -1;
        return res;
    }
};
```

### [698. 划分为k个相等的子集](https://leetcode.cn/problems/partition-to-k-equal-sum-subsets/)

- 暴力递归

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:

    bool canPartitionKSubsets(vector<int> &nums, int k) {
        int sum = 0;
        for (const auto &item: nums) sum += item;
        if (sum % k != 0) return false;
        int n = nums.size();
        // 降序
        sort(nums.begin(), nums.end(), greater<int>());
        // 存放每个集合已经有的累加和
        vector<int> group(k);
        // 从最大的数字开始
        return fc(nums, 0, group, sum / k);
    }

    // 最终每个集合的累加和为 target
    bool fc(vector<int> &nums, int curIndex, vector<int> &group, int target) {
        // 所有整数都用完了，且之后的逻辑确保了每个集合的累加和不超过 target
        if (curIndex >= nums.size()) return true;
        int num = nums[curIndex];
        for (int i = 0; i < group.size(); ++i) {
            // 超过就跳过
            if (group[i] + num > target) continue;
            // 尝试把当前值放入 group[i]
            group[i] += num;
            if (fc(nums, curIndex + 1, group, target)) return true;
            // 回溯
            group[i] -= num;
            // 剪枝，去掉同样的失败情况，但只去掉相邻的情况
            while (i + 1 < group.size() && group[i] == group[i + 1]) i++;
        }
        return false;
    }
};
```

- 记忆化搜索

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:

    bool canPartitionKSubsets(vector<int> &nums, int k) {
        int sum = 0;
        for (const auto &item: nums)
            sum += item;
        if (sum % k != 0) return false;
        int n = nums.size();
        vector<int> dp(1 << n, 0);
        // status = (1 << n) - 1 表示低 n 位全 1，所有的整数都尚未被选择
        return fc(nums, sum / k, (1 << n) - 1, 0, k, dp);
    }

    // len: 最终每个集合中的元素和
    // status: 记录整数的选取情况，二进制位为 1 表示未被选择
    // cur: 当前集合中的元素和
    // rest: 待生成的集合的总数
    bool fc(vector<int> &nums, int len, int status, int cur, int rest, vector<int> &dp) {
        if (rest == 0) return status == 0;
        if (dp[status] != 0) return dp[status] == 1;
        bool res = false;
        for (int i = 0; i < nums.size(); ++i) {
            // 尝试每一根二进制位为 1 的即未被选择过的整数，且加上后，当前边集合中的元素和不能超出最终的元素和
            if ((status & (1 << i)) != 0 && cur + nums[i] <= len) {
                if (cur + nums[i] == len) {
                    // 刚好能生成一个规定的集合
                    res = fc(nums, len, status ^ (1 << i), 0, rest - 1, dp);
                } else {
                    // 还差一些
                    res = fc(nums, len, status ^ (1 << i), cur + nums[i], rest, dp);
                }
                if (res) break;
            }
        }
        dp[status] = res ? 1 : -1;
        return res;
    }
};
```

### [P1171 售货员的难题](https://www.luogu.com.cn/problem/P1171)

- 即TSP 问题，全称是 **旅行商问题（Travelling Salesman Problem）**，是一个经典的组合优化问题，属于 NP-完全问题，广泛用于算法设计、运筹学和人工智能领域。

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int MAXN = 20;
vector<vector<int>> graph(MAXN, vector<int>(MAXN));
vector<vector<int>> dp(1 << MAXN, vector<int>(MAXN));
int n;

// s 低 n 位记录这 n 个村庄是否经过了，二进制位为 1 表示经过了，i 代表当前村庄
int fc(int s, int i) {
    // 所有的村庄都经过了，返回从当前村庄回到起点的代价
    if (s == (1 << n) - 1) return graph[i][0];
    if (dp[s][i] != -1) return dp[s][i];
    int res = 0x7fffffff;
    for (int j = 0; j < n; ++j) {
        // 已经去过的就跳过
        if ((s & (1 << j)) != 0) continue;
        // 尝试下一个去 j 号村庄
        res = min(res, graph[i][j] + fc(s | (1 << j), j));
    }
    dp[s][i] = res;
    return res;
}

int main() {
    cin >> n;
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            cin >> graph[i][j];

    for (int i = 0; i < (1 << n); ++i)
        for (int j = 0; j < n; ++j)
            dp[i][j] = -1;

    // 表示村庄 0 已经经过，从村庄 0 出发
    cout << fc(1, 0) << endl;
    return 0;
}
```