## 区间DP

### [括号区间匹配](https://www.nowcoder.com/practice/e391767d80d942d29e6095a935a5b96b)

- 记忆化搜索

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int recursion(vector<char> &s, int l, int r, vector<vector<int>> &dp) {
    if (l == r) {
        // 只有一个字符
        return 1;
    } else if (l + 1 == r) {
        // 只有两个字符
        if ((s[l] == '(' && s[r] == ')')
            || (s[l] == '[' && s[r] == ']')) {
            return 0;
        } else {
            return 2;
        }
    } else {
        // 超过两个
        if (dp[l][r] != -1) return dp[l][r];
        int res = 0x7fffffff;

        // P1: 可能是包含关系
        if ((s[l] == '(' && s[r] == ')')
            || (s[l] == '[' && s[r] == ']'))
            res = recursion(s, l + 1, r - 1, dp);

        // P2: 也可能是并列关系，从内部尝试每个划分点
        for (int m = l; m < r; ++m) {
            res = min(res, recursion(s, l, m, dp) + recursion(s, m + 1, r, dp));
        }

        dp[l][r] = res;
        return res;
    }
}

int main() {
    string str;
    cin >> str;
    int n = str.size();
    vector<char> s(begin(str), end(str));
    s.push_back('\0');

    vector<vector<int>> dp(n, vector<int>(n, -1));
    cout << recursion(s, 0, n - 1, dp);
    return 0;
}
```

### [664. 奇怪的打印机](https://leetcode.cn/problems/strange-printer/)

- 严格位置依赖

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int strangePrinter(string str) {
        vector<char> s(begin(str), end(str));
        s.push_back('\0');
        int n = str.size();

        vector<vector<int>> dp(n, vector<int>(n, 0));
        dp[n - 1][n - 1] = 1;
        for (int i = 0; i < n - 1; ++i) {
            // 主对角线
            dp[i][i] = 1;
            // 主对角线右侧的对角线
            dp[i][i + 1] = s[i] == s[i + 1] ? 1 : 2;
        }

        // 再往右边的对角线，从下往上填
        for (int l = n - 3; l >= 0; l--) {
            for (int r = l + 2; r < n; ++r) {
                if (s[l] == s[r]) {
                    // 两端相同，问题等价于求 [l, r - 1] 位置上的
                    dp[l][r] = dp[l][r - 1];
                } else {
                    int res = 0x7fffffff;
                    // 两端不同，说明两端不可能是在一次印刷中完成的，中间必有一个划分点
                    // 枚举划分点的可能
                    for (int m = l; m < r; ++m)
                        res = min(res, dp[l][m] + dp[m + 1][r]);
                    dp[l][r] = res;
                }
            }
        }
        return dp[0][n - 1];
    }
};
```

### [P3205 [HNOI2010] 合唱队](https://www.luogu.com.cn/problem/P3205)

- 严格位置依赖

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int MOD = 19650827;

int fc(int n, vector<int> &arr) {
    // dp[l][r][0]: 形成 l...r 的方法数，且 l 位置的数字是最后出现的
    // dp[l][r][1]: 形成 l...r 的方法数，且 r 位置的数字是最后出现的
    // 人的编号 [1, n]
    vector<vector<vector<int>>> dp(n + 1, vector<vector<int>>(n + 1, vector<int>(2, 0)));
    for (int i = 1; i < n; ++i) {
        // 只有两个人排队，且是增序
        if (arr[i] < arr[i + 1]) {
            dp[i][i + 1][0] = 1;
            dp[i][i + 1][1] = 1;
        }
    }

    for (int l = n - 2; l >= 1; l--) {
        for (int r = l + 2; r <= n; ++r) {
            // [l+1, r] 范围上 l+1 位置最后出现
            // 前提是 [l+1, r] 范围上 l+1 位置出现后，arr[l] 要更小，才能排在 l+1 位置前面
            if (arr[l] < arr[l + 1])
                dp[l][r][0] = (dp[l][r][0] + dp[l + 1][r][0]) % MOD;
            // [l+1, r] 范围上 r 位置最后出现
            if (arr[l] < arr[r])
                dp[l][r][0] = (dp[l][r][0] + dp[l + 1][r][1]) % MOD;
            // [l, r-1] 范围上
            if (arr[r] > arr[l])
                dp[l][r][1] = (dp[l][r][1] + dp[l][r - 1][0]) % MOD;
            if (arr[r] > arr[r - 1])
                dp[l][r][1] = (dp[l][r][1] + dp[l][r - 1][1]) % MOD;
        }
    }
    return (dp[1][n][0] + dp[1][n][1]) % MOD;
}

int main() {
    int n;
    cin >> n;
    vector<int> arr(n + 1);
    for (int i = 1; i <= n; ++i)
        cin >> arr[i];

    if (n == 1)
        cout << 1;
    else
        cout << fc(n, arr);
}
```

- 空间压缩

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int MOD = 19650827;

int fc(int n, vector<int> &arr) {
    // dp[l][r][0]: 形成 l...r 的方法数，且 l 位置的数字是最后出现的
    // dp[l][r][1]: 形成 l...r 的方法数，且 r 位置的数字是最后出现的
    // 人的编号 [1, n]
    vector<vector<int>> dp(n + 1, vector<int>(n + 1,0));
    if (arr[n - 1] < arr[n]) {
        dp[n][0] = 1;
        dp[n][1] = 1;
    }
    for (int l = n - 2; l >= 1; l--) {
        if (arr[l] < arr[l + 1]) {
            dp[l + 1][0] = 1;
            dp[l + 1][1] = 1;
        } else {
            dp[l + 1][0] = 0;
            dp[l + 1][1] = 0;
        }
        for (int r = l + 2; r <= n; r++) {
            int a = 0;
            int b = 0;
            if (arr[l] < arr[l + 1]) 
                a = (a + dp[r][0]) % MOD;
            if (arr[l] < arr[r]) 
                a = (a + dp[r][1]) % MOD;
            if (arr[r] > arr[l]) 
                b = (b + dp[r - 1][0]) % MOD;
            if (arr[r] > arr[r - 1])
                b = (b + dp[r - 1][1]) % MOD;
            dp[r][0] = a;
            dp[r][1] = b;
        }
    }
    return (dp[n][0] + dp[n][1]) % MOD;
}

int main() {
    int n;
    cin >> n;
    vector<int> arr(n + 1);
    for (int i = 1; i <= n; ++i)
        cin >> arr[i];

    if (n == 1)
        cout << 1;
    else
        cout << fc(n, arr);
}
```

### [546. 移除盒子](https://leetcode.cn/problems/remove-boxes/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int removeBoxes(vector<int> &boxes) {
        int n = boxes.size();
        vector<vector<vector<int>>> dp(n, vector<vector<int>>(n, vector<int>(n, 0)));
        return fc(boxes, 0, n - 1, 0, dp);
    }

    // boxes[l...r] 范围上去消除时，前面还剩 k 个连续的与 boxes[l] 颜色一样的盒子
    int fc(vector<int> &boxes, int l, int r, int k, vector<vector<vector<int>>> &dp) {
        if (l > r) return 0;
        if (dp[l][r][k] > 0) return dp[l][r][k];

        int s = l;
        while (s + 1 <= r && boxes[l] == boxes[s + 1]) s++;
        // boxes[l...s] 为同一种颜色，boxes[s+1] 不是
        // 前面有 k 个颜色与 boxes[l] 一样，boxes[l...s] 又有 s-l+1 个相同颜色
        int cnt = k + s - l + 1;
        // 可能性1: 前面 k 个和这 s-l+1 个一起消除
        int res = cnt * cnt + fc(boxes, s + 1, r, 0, dp);
        // 可能性2: 前面 k 个和这 s-l+1 个不一起消除，而是留着和后面再次出现的同种颜色一起消去
        for (int m = s + 2; m <= r; ++m) {
            // boxes[m] 要与最前面 k 个的颜色相同，且是后续连续个相同颜色的首个盒子
            if (boxes[l] == boxes[m] && boxes[m - 1] != boxes[m])
                // 先消除中间的 [s+1, m-1] 部分，再将前 k 个和从 m 位置开始的一起消除
                res = max(res, fc(boxes, s + 1, m - 1, 0, dp) + fc(boxes, m, r, cnt, dp));
        }
        dp[l][r][k] = res;
        return res;
    }
};
```

### [1000. 合并石头的最低成本](https://leetcode.cn/problems/minimum-cost-to-merge-stones/)

- k 路归并，若初始归并段数量无法构成严格k叉树，需要补充一些长度为 0 的虚段
  - 若 `(n-1)%(k-1) = 0`，则刚好够
  - 若 `(n-1)%(k-1) = u != 0`，需要补充 `k - u - 1` 个虚段

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int mergeStones(vector<int> &stones, int k) {
        int n = stones.size();
        // 初始归并段的数量构不成严格 k 叉树
        if ((n - 1) % (k - 1) != 0) return -1;
        vector<int> preSum(n + 1);
        // [l, r] 累加和 = preSum[r+1] - preSum[l]
        for (int i = 0, j = 1, sum = 0; i < n; ++i, j++) {
            sum += stones[i];
            preSum[j] = sum;
        }

        // dp[l][r]: [l, r] 范围上的石头，合并到不能再合并的最小代价
        vector<vector<int>> dp(n, vector<int>(n));
        for (int l = n - 2, res; l >= 0; l--) {
            for (int r = l + 1; r < n; r++) {
                res = 0x7fffffff;
                // 左右两边分别，合并成若干份，知道两边都不能再合并为止
                for (int m = l; m < r; m += k - 1)
                    res = min(res, dp[l][m] + dp[m + 1][r]);
                // 若最终能合并成一份，就加上合并代价
                if ((r - l) % (k - 1) == 0)
                    res += preSum[r + 1] - preSum[l];
                dp[l][r] = res;
            }
        }
        return dp[0][n - 1];

    }
};
```

### [730. 统计不同回文子序列](https://leetcode.cn/problems/count-different-palindromic-subsequences/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int countPalindromicSubsequences(string str) {
        int MOD = 1e9 + 7;
        vector<char> s(begin(str), end(str));
        s.push_back('\0');
        int n = str.size();

        vector<int> last(256, -1);
        // left[i] 表示 i 位置左侧和 s[i] 相同且最近的位置，不存在就是 -1
        vector<int> left(n);
        for (int i = 0; i < n; ++i) {
            left[i] = last[s[i]];
            // 跟新 s[i] 最新出现的位置
            last[s[i]] = i;
        }

        fill(begin(last), end(last), n);
        // right[i] 表示 i 位置右侧和 s[i] 相同且最近的位置，不存在就是 n
        vector<int> right(n);
        for (int i = n - 1; i >= 0; i--) {
            right[i] = last[s[i]];
            // 跟新 s[i] 最新出现的位置
            last[s[i]] = i;
        }

        // dp[i][j] 表示 [i, j] 上不同回文子序列的个数
        vector<vector<long>> dp(n, vector<long>(n, 0));
        for (int i = 0; i < n; ++i)
            dp[i][i] = 1;
        for (int i = n - 2, l, r; i >= 0; i--) {
            for (int j = i + 1; j < n; j++) {
                if (s[i] != s[j]) {
                    // 1. 首尾不同，[i, j-1] 上的加上 [i+1, j] 上的，再减去中间 [i+1, j-1] 重复的
                    dp[i][j] = dp[i][j - 1] + dp[i + 1][j] - dp[i + 1][j - 1] + MOD;
                } else {
                    // 2. 首尾相同
                    // i 位置右侧和 s[i] 相同且最近的位置
                    l = right[i];
                    // j 位置左侧和 s[j] 相同且最近的位置
                    r = left[j];
                    if (l > r) {
                        // (i, j) 上没有 s[i] 字符
                        // 假设 s[i] 字符为 a
                        // [i+1, j-1] 上不同回文子序列的个数为 dp[i + 1][j - 1]，这些回文子序列套上外层两端相同的字符 a 又能分别生成一个回文子序列
                        // 所以要乘 2，再加上两种特殊回文子序列：a, aa（[i+1, j-1] 不会出现这两种情况）
                        dp[i][j] = dp[i + 1][j - 1] * 2 + 2;
                    } else if (l == r) {
                        // (i, j) 上只有一个 s[i] 字符
                        // 同理要乘 2，再加上一种特殊回文子序列：aa（回文子序列a已经在内部计算过了）
                        dp[i][j] = dp[i + 1][j - 1] * 2 + 1;
                    } else {
                        // (i, j) 上不止一个 s[i] 字符
                        // a ... a ...... a ... a
                        // i ... l ...... r ... j
                        // 同理要乘 2，但要去除两侧加上 a 后增加的重复回文子序列，因为 (l+1, r-1) 已经包裹上 l+1 和 r-1 处的 a 了
                        // (l+1, r-1) 已经包裹上的回文子序列个数就是 dp[l + 1][r - 1]
                        dp[i][j] = dp[i + 1][j - 1] * 2 - dp[l + 1][r - 1] + MOD;
                    }
                }
                dp[i][j] %= MOD;
            }
        }
        return (int) dp[0][n - 1];
    }
};
```