## 状压DP（下）

### [1434. 每个人戴不同帽子的方案数](https://leetcode.cn/problems/number-of-ways-to-wear-different-hats-to-each-other/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int MOD = 1e9 + 7;

    int numberWays(vector<vector<int>> &arr) {
        // 帽子颜色 1~m
        int m = 0;
        for (const auto &person: arr)
            for (const auto &hat: person)
                m = max(m, hat);

        // 人的数量 0~n-1
        int n = arr.size();
        // 记录每个帽子可以给哪些人，用 int 的低 n 位表示，1 表示可以满足那个人
        vector<int> hats(m + 1);
        for (int i = 0; i < n; ++i)
            for (const auto &hat: arr[i])
                hats[hat] |= 1 << i;

        vector<vector<int>> dp(m + 1, vector<int>(1 << n, -1));
        return fc(hats, m, n, 1, 0, dp);
    }

    // curIndex 帽子下标，status 记录这 n 个人帽子的获得情况
    int fc(vector<int> &hats, int m, int n, int curIndex, int status, vector<vector<int>> &dp) {
        // 所有人都有帽子了
        if (status == (1 << n) - 1) return 1;
        // 还有人没有帽子，但是能用的帽子已经没了
        if (curIndex == m + 1) return 0;
        if (dp[curIndex][status] != -1) return dp[curIndex][status];
        // p1：curIndex 号帽子不分配给任何人
        int res = fc(hats, m, n, curIndex + 1, status, dp);
        // p2：curIndex 号帽子尝试分配给每个它能满足的人
        int cur = hats[curIndex];
        
        // 枚举
        for (int i = 0; i < n; ++i)
            // 能满足 i 号人，且 i 号人现在没有帽子
            if ((cur & (1 << i)) != 0 && (status & (1 << i)) == 0)
                res = (res + fc(hats, m, n, curIndex + 1, status | (1 << i), dp)) % MOD;
        dp[curIndex][status] = res;
        return res;
    }
};
```

- 使用 Brian Kernighan 算法提取出二进制状态中最右侧的 1

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int MOD = 1e9 + 7;

    int numberWays(vector<vector<int>> &arr) {
        // 帽子颜色 1~m
        int m = 0;
        for (const auto &person: arr)
            for (const auto &hat: person)
                m = max(m, hat);

        // 人的数量 0~n-1
        int n = arr.size();
        // 记录每个帽子可以给哪些人，用 int 的低 n 位表示，1 表示可以满足那个人
        vector<int> hats(m + 1);
        for (int i = 0; i < n; ++i)
            for (const auto &hat: arr[i])
                hats[hat] |= 1 << i;

        vector<vector<int>> dp(m + 1, vector<int>(1 << n, -1));
        return fc(hats, m, n, 1, 0, dp);
    }

    // curIndex 帽子下标，status 记录这 n 个人帽子的获得情况
    int fc(vector<int> &hats, int m, int n, int curIndex, int status, vector<vector<int>> &dp) {
        // 所有人都有帽子了
        if (status == (1 << n) - 1) return 1;
        // 还有人没有帽子，但是能用的帽子已经没了
        if (curIndex == m + 1) return 0;
        if (dp[curIndex][status] != -1) return dp[curIndex][status];
        // p1：curIndex 号帽子不分配给任何人
        int res = fc(hats, m, n, curIndex + 1, status, dp);
        // p2：curIndex 号帽子尝试分配给每个它能满足的人
        int cur = hats[curIndex];

        // 使用 Brian Kernighan 算法提取出二进制状态中最右侧的 1
        int rightOne;
        while (cur != 0) {
            rightOne = cur & -cur;
            if ((status & rightOne) == 0)
                res = (res + fc(hats, m, n, curIndex + 1, status | rightOne, dp)) % MOD;
            cur ^= rightOne;
        }
        dp[curIndex][status] = res;
        return res;
    }
};
```

### [最优账单平衡](https://leetcode.cn/problems/optimal-account-balancing/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int MAXN = 13;

    int minTransfers(vector<vector<int>> &transactions) {
        vector<int> debt = debts(transactions);

        cout << "收支表: ";
        for (int i = 0; i < debt.size(); ++i)
            cout << debt[i] << " ";
        cout << endl;

        int n = debt.size();
        vector<int> dp(1 << n, -1);
        // 数组中划分出的累加和为 0 且不可拆分的集合，集合中若有 n 个元素，则最少转账 n - 1 次即可平账
        // 集合个数越多，最终总的转账次数越少
        // 总的转账次数 = 所有累加和为 0 且不可拆分的集合中的元素总个数就是 debt.size()，再减去集合总个数
        return n - fc(debt, (1 << n) - 1, 0, n, dp);
    }

    // 转化成收支表
    vector<int> debts(vector<vector<int>> &transactions) {
        vector<int> help(MAXN, 0);
        for (const auto &tran: transactions) {
            help[tran[0]] -= tran[2];
            help[tran[1]] += tran[2];
        }
        // 只返回收支不平衡的
        vector<int> debt;
        for (int num: help)
            if (num != 0)
                debt.push_back(num);
        return debt;
    }

    // 返回累加和为 0 且不可拆分的集合的最大数量
    int fc(const vector<int> &debt, int set, int sum, int n, vector<int> &dp) {
        if (dp[set] != -1) return dp[set];
        int res = 0;
        // 集合中不止一个元素
        if ((set & (set - 1)) != 0) {
            if (sum == 0) {
                // p1: 集合整体累加和为 0
                for (int i = 0; i < n; i++) {
                    // 找到一个在集合中的元素
                    if ((set & (1 << i)) != 0) {
                        // 去掉它，剩下的集合进行尝试，返回值 + 1
                        res = fc(debt, set ^ (1 << i), sum - debt[i], n, dp) + 1;
                        // 后续的在集合中的元素就不用再被去除掉进行尝试了，结果都一样
                        break;
                    }
                }
            } else {
                // p2: 不为 0
                for (int i = 0; i < n; i++) {
                    if ((set & (1 << i)) != 0) {
                        res = max(res, fc(debt, set ^ (1 << i), sum - debt[i], n, dp));
                    }
                }
            }
        }
        dp[set] = res;
        return res;
    }
};

int main() {
    Solution sol;

    vector<vector<vector<int>>> testCases = {
            // 用例 1：闭环交易，净收支为 0
            {
                    {0, 1, 10},
                    {1, 2, 10},
                    {2, 0, 10}
            },
            // 用例 2：链式转账
            {
                    {0, 1, 10},
                    {1, 2, 5}
            },
            // 用例 3：四人闭环
            {
                    {0, 1, 5},
                    {1, 2, 5},
                    {2, 3, 5},
                    {3, 0, 5}
            },
            // 用例 4：集中借款，最坏情况
            {
                    {0, 1, 10},
                    {0, 2, 10},
                    {0, 3, 10}
            },
            // 用例 5：复杂组合
            {
                    {0, 1, 10},
                    {2, 0, 5},
                    {3, 4, 7},
                    {4, 2, 5},
                    {1, 3, 2}
            }
    };

    vector<int> expected = {0, 2, 0, 3, 3};

    for (int i = 0; i < testCases.size(); ++i) {
        int result = sol.minTransfers(testCases[i]);
        cout << "Test Case " << i + 1 << ": Output = " << result
             << ", Expected = " << expected[i]
             << (result == expected[i] ? " ✅" : " ❌") << endl << endl;
    }

    return 0;
}
```

### [1994. 好子集的数目](https://leetcode.cn/problems/the-number-of-good-subsets/)

- 记忆化搜索

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    int MAXN = 30;
    int LIMIT = (1 << 10);
    int MOD = 1e9 + 7;

    vector<int> own;

    Solution() {
        // 打表加速判断
        // 如果一个数字拥有某一种质数因子不只 1 个，那么认为这个数字无效，状态全是 0，0b0000000000
        // 比如 12，拥有 2 这种质数因子不只 1 个，所以无效，用0b0000000000表示
        // 如果一个数字拥有任何一种质数因子都不超过 1 个，那么认为这个数字有效，用位信息表示这个数字拥有质数因子的状态
        // 比如 14，拥有 2 这种质数因子不超过 1 个，拥有 7 这种质数因子不超过 1 个，有效
        // 从高位到低位依次表示：...13 11 7 5 3 2
        // 所以用 0b0000001001 表示 14 拥有质数因子的状态
        // 质数: 29 23 19 17 13 11 7 5 3 2
        // 位置:  9  8  7  6  5  4 3 2 1 0
        own = {
                0b0000000000, // 0
                0b0000000000, // 1
                0b0000000001, // 2
                0b0000000010, // 3
                0b0000000000, // 4
                0b0000000100, // 5
                0b0000000011, // 6
                0b0000001000, // 7
                0b0000000000, // 8
                0b0000000000, // 9
                0b0000000101, // 10
                0b0000010000, // 11
                0b0000000000, // 12
                0b0000100000, // 13
                0b0000001001, // 14
                0b0000000110, // 15
                0b0000000000, // 16
                0b0001000000, // 17
                0b0000000000, // 18
                0b0010000000, // 19
                0b0000000000, // 20
                0b0000001010, // 21
                0b0000010001, // 22
                0b0100000000, // 23
                0b0000000000, // 24
                0b0000000000, // 25
                0b0000100001, // 26
                0b0000000000, // 27
                0b0000000000, // 28
                0b1000000000, // 29
                0b0000000111  // 30
        };
    }

    // 1 <= nums.length <= 105
    // 1 <= nums[i] <= 30
    // todo
    int numberOfGoodSubsets(vector<int> &nums) {
        vector<int> cnt(MAXN + 1, 0);
        // 统计 1~30 出现的次数
        for (int num: nums) cnt[num]++;

        vector<vector<int>> dp(MAXN + 1, vector<int>(LIMIT, -1));
        int res = 0;
        for (int status = 1; status < LIMIT; status++)
            // 累加质因子状态为 status 的
            res = (res + fc(MAXN, status, cnt, dp)) % MOD;
        return res;
    }

    // 最终相乘的结果一定要让质因子的状态为 status，且每种质因子只能有 1 个，返回子集的数量
    // status 每一位代表的质因子如下
    // 质数: 29 23 19 17 13 11 7 5 3 2
    // 位置:  9  8  7  6  5  4 3 2 1 0
    int fc(int i, int status, vector<int> &cnt, vector<vector<int>> &dp) {
        if (dp[i][status] != -1) return  dp[i][status];
        int res = 0;
        if (i == 1) {
            if (status == 0) {
                res = 1;
                for (int j = 0; j < cnt[1]; j++)
                    res = (res << 1) % MOD;
            }
        } else {
            res = fc(i - 1, status, cnt, dp);
            int cur = own[i];
            int times = cnt[i];
            if (cur != 0 && times != 0 && (status & cur) == cur)
                res = (int) (((long long) fc(i - 1, status ^ cur, cnt, dp) * times + res) % MOD);
        }
        dp[i][status] = res;
        return res;
    }
};
```

- 空间压缩

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    int MAX_V = 30;
    int LIMIT = (1 << 10);
    int MOD = 1e9 + 7;
    vector<int> own;
    vector<int> cnt;
    vector<int> dp;

    Solution() {
        cnt.resize(MAX_V + 1, 0);
        dp.resize(LIMIT, 0);
        own = {
                0b0000000000, // 0
                0b0000000000, // 1
                0b0000000001, // 2
                0b0000000010, // 3
                0b0000000000, // 4
                0b0000000100, // 5
                0b0000000011, // 6
                0b0000001000, // 7
                0b0000000000, // 8
                0b0000000000, // 9
                0b0000000101, // 10
                0b0000010000, // 11
                0b0000000000, // 12
                0b0000100000, // 13
                0b0000001001, // 14
                0b0000000110, // 15
                0b0000000000, // 16
                0b0001000000, // 17
                0b0000000000, // 18
                0b0010000000, // 19
                0b0000000000, // 20
                0b0000001010, // 21
                0b0000010001, // 22
                0b0100000000, // 23
                0b0000000000, // 24
                0b0000000000, // 25
                0b0000100001, // 26
                0b0000000000, // 27
                0b0000000000, // 28
                0b1000000000, // 29
                0b0000000111  // 30
        };
    }

    int numberOfGoodSubsets(vector<int> &nums) {
        for (int num: nums) cnt[num]++;
        dp[0] = 1;
        for (int i = 0; i < cnt[1]; i++)
            dp[0] = (dp[0] << 1) % MOD;
        for (int i = 2, cur, times; i <= MAX_V; i++) {
            cur = own[i];
            times = cnt[i];
            if (cur != 0 && times != 0) {
                for (int status = LIMIT - 1; status >= 0; status--) {
                    if ((status & cur) == cur) {
                        dp[status] = (int) (((long long) dp[status ^ cur] * times + dp[status]) % MOD);
                    }
                }
            }
        }
        int res = 0;
        for (int s = 1; s < LIMIT; s++)
            res = (res + dp[s]) % MOD;
        return res;
    }
};
```

### [1655. 分配重复整数](https://leetcode.cn/problems/distribute-repeating-integers/)

- 枚举所有 status 的子集

```c++
#include <iostream>
#include <bitset>

using namespace std;

int main() {
    int status = 0b1001100;
    for (int i = status; i > 0; i = (i - 1) & status) {
        // 输出低 7 位二进制
        cout << bitset<7>(i) << endl;
    }
    /*
     1001100
     1001000
     1000100
     1000000
     0001100
     0001000
     0000100
     */
}
```

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    bool canDistribute(vector<int> &nums, vector<int> &quantity) {
        // 排序后统计词频
        sort(nums.begin(), nums.end());
        int n = 1;
        for (int i = 1; i < nums.size(); i++)
            if (nums[i - 1] != nums[i])
                n++;
        vector<int> cnt(n);
        int c = 1;
        for (int i = 1, j = 0; i < nums.size(); i++) {
            if (nums[i - 1] != nums[i]) {
                cnt[j++] = c;
                c = 1;
            } else {
                c++;
            }
        }
        cnt[n - 1] = c;

        int m = quantity.size();
        // sum[status] 表示满足 status 状态的订单总共要多少个相同的整数
        vector<int> sum(1 << m);
        // 枚举是生成 quantity 中的每个子集，所需要数字的个数
        for (int i = 0; i < quantity.size(); i++) {
            int v = quantity[i];
            int h = 1 << i;
            // 枚举所有比 h 小的状态
            for (int j = 0; j < h; j++)
                sum[h | j] = sum[j] + v;
        }
        vector<vector<int>> dp(1 << m, vector<int>(n, 0));
        return fc(cnt, sum, (1 << m) - 1, 0, dp);
    }

    // curIndex 为当前数字的下标
    // status 为订单状态，1 表示待满足
    bool fc(vector<int> &cnt, vector<int> &sum, int status, int curIndex, vector<vector<int>> &dp) {
        // 所有订单都被满足了
        if (status == 0) return true;
        // 整数已经用完
        if (curIndex == cnt.size()) return false;
        if (dp[status][curIndex] != 0) return dp[status][curIndex] == 1;

        bool res = false;
        // 当前数字的个数
        int k = cnt[curIndex];
        // 枚举所有 status 的子集
        for (int i = status; i > 0; i = (i - 1) & status) {
            // 这个 status 的子集的状态所需要的相同的数字个数小于当前数字个数
            // 满足这个子集，然后 status 去掉这个子集，尝试下一个数字
            if (sum[i] <= k && fc(cnt, sum, status ^ i, curIndex + 1, dp)) {
                res = true;
                break;
            }
        }
        // 当前数字啥也满足不了，尝试下一个数字
        if (!res) res = fc(cnt, sum, status, curIndex + 1, dp);
        dp[status][curIndex] = res ? 1 : -1;
        return res;
    }
};
```