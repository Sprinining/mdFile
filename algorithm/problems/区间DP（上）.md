## 区间DP

### [1312. 让字符串成为回文串的最少插入次数](https://leetcode.cn/problems/minimum-insertion-steps-to-make-a-string-palindrome/)

- 基于两侧端点讨论的可能性展开

- 暴力递归

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    int minInsertions(string s) {
        vector<char> str(begin(s), end(s));
        str.push_back('\0');
        return recursion(str, 0, s.length() - 1);
    }

    int recursion(vector<char> &str, int left, int right) {
        // 只有一个字符，无需添加
        if (left == right) return 0;
        // 只有两个字符，相同则无需添加；不同则需要在首部或尾部加上一个字符，ab 变成 aba 或者 bab
        if (left + 1 == right) return str[left] == str[right] ? 0 : 1;
        // 两个字符以上
        if (str[left] == str[right]) {
            // 首尾相同
            return recursion(str, left + 1, right - 1);
        } else {
            // 首尾不同，选择插入更少字符就能回文的一段，首部或尾部加上一个字符
            return min(recursion(str, left, right - 1), recursion(str, left + 1, right)) + 1;
        }
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
    int minInsertions(string s) {
        int len = s.length();
        vector<char> str(begin(s), end(s));
        str.push_back('\0');
        vector<vector<int>> dp(len, vector<int>(len, -1));
        return recursion(str, 0, s.length() - 1, dp);
    }

    int recursion(vector<char> &str, int l, int r, vector<vector<int>> &dp) {
        if (dp[l][r] != -1) return dp[l][r];

        int res;
        if (l == r) {
            // 只有一个字符，无需添加
            res = 0;
        } else if (l + 1 == r) {
            // 只有两个字符，相同则无需添加；不同则需要在首部或尾部加上一个字符，ab 变成 aba 或者 bab
            res = str[l] == str[r] ? 0 : 1;
        } else {
            // 两个字符以上
            if (str[l] == str[r]) {
                // 首尾相同
                res = recursion(str, l + 1, r - 1, dp);
            } else {
                // 首尾不同，选择插入更少字符就能回文的一段，首部或尾部加上一个字符
                res = min(recursion(str, l, r - 1, dp), recursion(str, l + 1, r, dp)) + 1;
            }
        }

        dp[l][r] = res;
        return res;
    }
};
```

- 严格位置依赖

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    int minInsertions(string s) {
        int len = s.length();
        vector<char> str(begin(s), end(s));
        str.push_back('\0');

        // 主对角线 dp[i][i] 初始化为 0，表示只有一个字符时，无需添加
        vector<vector<int>> dp(len, vector<int>(len, 0));
        // 初始化主对角线右边的一条斜线
        for (int l = 0; l + 1 < len; ++l)
            dp[l][l + 1] = str[l] == str[l + 1] ? 0 : 1;

        // dp[i][j] 依赖左侧下方以及左下方的格子，所以 dp 表从主对角线往右上角推
        // i 为对角线编号，i = 0 和 1 的对角线已经填过了
        for (int i = 2; i < len; ++i) {
            for (int l = 0, r = l + i; r < len; ++l, r++) {
                if (str[l] == str[r]) {
                    // 首尾相同，依赖左下方
                    dp[l][r] = dp[l + 1][r - 1];
                } else {
                    // 首尾不同，依赖左侧和下方
                    dp[l][r] = min(dp[l][r - 1], dp[l + 1][r]) + 1;
                }
            }
        }

        return dp[0][len - 1];
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
    // todo
    int minInsertions(string s) {
        int len = s.length();
        if (len < 2) return 0;
        vector<char> str(begin(s), end(s));
        str.push_back('\0');

        vector<int> dp(len, 0);
        dp[len - 1] = str[len - 2] == str[len - 1] ? 0 : 1;

        for (int l = len - 3, leftDown, backUp; l >= 0; l--) {
            leftDown = dp[l + 1];
            dp[l + 1] = s[l] == s[l + 1] ? 0 : 1;
            for (int r = l + 2; r < len; r++) {
                backUp = dp[r];
                if (s[l] == s[r]) {
                    dp[r] = leftDown;
                } else {
                    dp[r] = min(dp[r - 1], dp[r]) + 1;
                }
                leftDown = backUp;
            }
        }
        return dp[len - 1];
    }
};
```

### [486. 预测赢家](https://leetcode.cn/problems/predict-the-winner/)

- 基于两侧端点讨论的可能性展开

- 暴力递归

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    bool predictTheWinner(vector<int> &nums) {
        int sum = 0;
        for (int i = 0; i < nums.size(); ++i)
            sum += nums[i];
        int res = recursion(nums, 0, nums.size() - 1);
        return res >= sum - res;
    }

    // nums[l] 到 nums[r] 上玩家 1 先选，返回能获得的最大总数
    int recursion(vector<int> &nums, int l, int r) {
        if (l == r)
            return nums[l];
        if (l + 1 == r)
            return max(nums[l], nums[r]);
        // 超过两个数
        // 选左边，min 表示玩家 1 选过后玩家 2 再选，玩家 2 只会留给更差的情况给玩家 1
        int m1 = nums[l] + min(recursion(nums, l + 1, r - 1), recursion(nums, l + 2, r));
        // 选右边
        int m2 = nums[r] + min(recursion(nums, l + 1, r - 1), recursion(nums, l, r - 2));
        // 玩家 1 会从他的两种可能中选最好的
        return max(m1, m2);
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
    bool predictTheWinner(vector<int> &nums) {
        int n = nums.size();
        int sum = 0;
        for (int i = 0; i < nums.size(); ++i)
            sum += nums[i];

        vector<vector<int>> dp(n, vector<int>(n, -1));

        int res = recursion(nums, 0, n - 1, dp);
        return res >= sum - res;
    }

    // nums[l] 到 nums[r] 上玩家 1 先选，返回能获得的最大总数
    int recursion(vector<int> &nums, int l, int r, vector<vector<int>> &dp) {
        if (dp[l][r] != -1) return dp[l][r];

        int res = 0;
        if (l == r) {
            res = nums[l];
        } else if (l + 1 == r) {
            res = max(nums[l], nums[r]);
        } else {
            // 超过两个数
            // 选左边，min 表示玩家 1 选过后玩家 2 再选，玩家 2 只会留给更差的情况给玩家 1
            int m1 = nums[l] + min(recursion(nums, l + 1, r - 1, dp), recursion(nums, l + 2, r, dp));
            // 选右边
            int m2 = nums[r] + min(recursion(nums, l + 1, r - 1, dp), recursion(nums, l, r - 2, dp));
            // 玩家 1 会从他的两种可能中选最好的
            res = max(m1, m2);
        }

        dp[l][r] = res;
        return res;
    }
};
```

- 严格位置依赖

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    bool predictTheWinner(vector<int> &nums) {
        int n = nums.size();
        int sum = 0;
        for (int i = 0; i < nums.size(); ++i)
            sum += nums[i];

        vector<vector<int>> dp(n, vector<int>(n, -1));

        // 编号 0 和 1 的对角线
        for (int l = 0; l < n - 1; ++l) {
            dp[l][l] = nums[l];
            dp[l][l + 1] = max(nums[l], nums[l + 1]);
        }
        dp[n - 1][n - 1] = nums[n - 1];

        // 剩下的对角线，从对角线的下方往上填
        for (int l = n - 3; l >= 0; l--) {
            for (int r = l + 2; r < n; ++r) {
                // 依赖左下角和下下方
                int m1 = nums[l] + min(dp[l + 1][r - 1], dp[l + 2][r]);
                // 依赖左下角和左左侧
                int m2 = nums[r] + min(dp[l + 1][r - 1], dp[l][r - 2]);
                dp[l][r] = max(m1, m2);
            }
        }

        int res = dp[0][n - 1];
        return res >= sum - res;
    }
};
```

### [1039. 多边形三角剖分的最低得分](https://leetcode.cn/problems/minimum-score-triangulation-of-polygon/)

- 基于范围上划分点讨论的可能性展开

- 暴力递归

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    int minScoreTriangulation(vector<int> &values) {
        int n = values.size();
        return recursion(values, 0, n - 1);
    }

    int recursion(vector<int> &values, int l, int r) {
        if (l == r || l + 1 == r) {
            return 0;
        } else {
            // 选一个中间点
            int res = 0x7fffffff;
            for (int m = l + 1; m < r; ++m) {
                // 比较当前最小得分和新的得分
                // 新的得分 = 左区间[l, m] 最小得分 + 右区间[m, r] 最小得分 + 顶点标记的乘积
                res = min(res, recursion(values, l, m) + recursion(values, m, r) + values[l] * values[m] * values[r]);
            }
            return res;
        }
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
    int minScoreTriangulation(vector<int> &values) {
        int n = values.size();
        vector<vector<int>> dp(n, vector<int>(n, 0x7fffffff));
        return recursion(values, 0, n - 1, dp);
    }

    int recursion(vector<int> &values, int l, int r, vector<vector<int>> &dp) {
        if (dp[l][r] != 0x7fffffff) return dp[l][r];
        int res = 0x7fffffff;
        if (l == r || l + 1 == r) {
            res = 0;
        } else {
            // 选一个中间点
            for (int m = l + 1; m < r; ++m) {
                // 比较当前最小得分和新的得分
                // 新的得分 = 左区间[l, m] 最小得分 + 右区间[m, r] 最小得分 + 顶点标记的乘积
                res = min(res, recursion(values, l, m, dp) + recursion(values, m, r, dp) +
                               values[l] * values[m] * values[r]);
            }
        }
        dp[l][r] = res;
        return res;
    }
};
```

- 严格位置依赖

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    int minScoreTriangulation(vector<int> &values) {
        int n = values.size();
        // 编号为 0 和 1 的对角线都初始化为 0
        vector<vector<int>> dp(n, vector<int>(n, 0));
        for (int l = n - 3; l >= 0; l--) {
            for (int r = l + 2; r < n; ++r) {
                dp[l][r] = 0x7fffffff;
                for (int m = l + 1; m < r; ++m) {
                    dp[l][r] = min(dp[l][r], dp[l][m] + dp[m][r] + values[l] * values[m] * values[r]);
                }
            }
        }
        return dp[0][n - 1];
    }
};
```

### [1547. 切棍子的最小成本](https://leetcode.cn/problems/minimum-cost-to-cut-a-stick/)

- 基于范围上划分点讨论的可能性展开

- 记忆化搜索

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int minCost(int n, vector<int> &cuts) {
        sort(begin(cuts), end(cuts));
        int m = cuts.size();
        int len = m + 2;
        // 用于计算当前棍子长度
        vector<int> arr(len);
        // 补上开头结尾
        arr[0] = 0;
        arr[len - 1] = n;
        for (int i = 0; i < m; ++i)
            arr[i + 1] = cuts[i];

        vector<vector<int>> dp(len, vector<int>(len, -1));
        return recursion(arr, 1, m, dp);
    }

    // [l, r] 位置是切点
    int recursion(vector<int> &arr, int l, int r, vector<vector<int>> &dp) {
        if (l > r) return 0;
        // 只有一个切点时，直接返回这个棍子长度
        if (l == r) return arr[r + 1] - arr[l - 1];
        if (dp[l][r] != -1) return dp[l][r];

        int res = 0x7fffffff;
        // 从 [l, r] 中选对切点切下去的顺序
        for (int m = l; m <= r; ++m) {
            res = min(res, recursion(arr, l, m - 1, dp) + recursion(arr, m + 1, r, dp));
        }
        // 加上棍子长度
        res += arr[r + 1] - arr[l - 1];
        dp[l][r] = res;
        return res;
    }
};
```

- 严格位置依赖

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int minCost(int n, vector<int> &cuts) {
        sort(begin(cuts), end(cuts));
        int m = cuts.size();
        int len = m + 2;
        // 用于计算当前棍子长度
        vector<int> arr(len);
        // 补上开头结尾
        arr[0] = 0;
        arr[len - 1] = n;
        for (int i = 0; i < m; ++i)
            arr[i + 1] = cuts[i];

        vector<vector<int>> dp(len, vector<int>(len, 0));

        // 只有唯一一个切点时，最小代价就是棍子长度
        for (int i = 1; i <= m; ++i)
            dp[i][i] = arr[i + 1] - arr[i - 1];

        for (int l = m - 1, next; l >= 1; l--) {
            for (int r = l + 1; r <= m; ++r) {
                next = 0x7fffffff;
                // 只依赖左侧和下方的所有格子
                for (int k = l; k <= r; ++k)
                    next = min(next, dp[l][k - 1] + dp[k + 1][r]);
                dp[l][r] = arr[r + 1] - arr[l - 1] + next;
            }
        }
        return dp[1][m];
    }
};
```

### [312. 戳气球](https://leetcode.cn/problems/burst-balloons/)

- 基于范围上划分点讨论的可能性展开

- 记忆化搜索

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int maxCoins(vector<int> &nums) {
        int n = nums.size();
        int len = n + 2;
        vector<int> arr(len);
        // 左右两边补上一个气球
        arr[0] = 1;
        arr[len - 1] = 1;
        for (int i = 0; i < n; ++i) {
            arr[i + 1] = nums[i];
        }

        vector<vector<int>> dp(len, vector<int>(len, -1));
        return recursion(arr, 1, n, dp);
    }

    // 从 arr[l...r] 中选择气球爆炸顺序，返回最大得分
    // 前提：arr[l-1] 和 arr[r+1] 没爆炸
    int recursion(vector<int> &arr, int l, int r, vector<vector<int>> &dp) {
        if (dp[l][r] != -1) return dp[l][r];
        int res = 0;
        if (l == r) {
            // 只剩一个气球
            res = arr[l - 1] * arr[l] * arr[r + 1];
        } else {
            // 比较 l 位置最后被打爆和 r 位置最后被打爆的结果
            res = max(arr[l - 1] * arr[l] * arr[r + 1] + recursion(arr, l + 1, r, dp),
                      arr[l - 1] * arr[r] * arr[r + 1] + recursion(arr, l, r - 1, dp));
            // 把中间每个位置都假设成最后被打爆的
            for (int k = l + 1; k < r; ++k) {
                res = max(res, arr[l - 1] * arr[k] * arr[r + 1] + recursion(arr, l, k - 1, dp) +
                               recursion(arr, k + 1, r, dp));
            }
        }
        dp[l][r] = res;
        return res;
    }
};
```

- 严格位置依赖

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int maxCoins(vector<int> &nums) {
        int n = nums.size();
        int len = n + 2;
        vector<int> arr(len);
        // 左右两边补上一个气球
        arr[0] = 1;
        arr[len - 1] = 1;
        for (int i = 0; i < n; ++i) {
            arr[i + 1] = nums[i];
        }

        vector<vector<int>> dp(len, vector<int>(len, -1));

        for (int i = 1; i <= n; ++i)
            dp[i][i] = arr[i - 1] * arr[i] * arr[i + 1];

        for (int l = n, res; l >= 1; l--) {
            for (int r = l + 1; r <= n; r++) {
                res = max(arr[l - 1] * arr[l] * arr[r + 1] + dp[l + 1][r],
                          arr[l - 1] * arr[r] * arr[r + 1] + dp[l][r - 1]);
                for (int k = l + 1; k < r; k++) {
                    res = max(res, arr[l - 1] * arr[k] * arr[r + 1] + dp[l][k - 1] + dp[k + 1][r]);
                }
                dp[l][r] = res;
            }
        }

        return dp[1][n];
    }
};
```

### [面试题 08.14. 布尔运算](https://leetcode.cn/problems/boolean-evaluation-lcci/)

- 基于范围上划分点讨论的可能性展开

- 记忆化搜索

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int countEval(string s, int result) {
        vector<char> str(begin(s), end(s));
        str.push_back('\0');
        int n = s.size();

        vector<vector<vector<int>>> dp(n, vector<vector<int>>(n, vector<int>()));
        vector<int> res = recursion(str, 0, n - 1, dp);
        return res[result];
    }

    // s[l...r] 是表达式的一部分，是合法的表达式
    // 返回结果 res[0] 表示这段表达式结果为 false 的可能数，res[1] 表示为 true 的可能数
    vector<int> recursion(vector<char> &str, int l, int r, vector<vector<vector<int>>> &dp) {
        if (!dp[l][r].empty()) return dp[l][r];
        int f = 0, t = 0;

        if (l == r) {
            // 只有一个字符
            f = str[l] == '0' ? 1 : 0;
            t = str[l] == '1' ? 1 : 0;
        } else {
            // 这段表达式中的每个运算符都尝试作为最后一个运算的符号
            for (int k = l + 1; k < r; k += 2) {
                // 计算 k 位置的运算符的左侧表达式结果为 false 和 ture 的可能数
                vector<int> tmp = recursion(str, l, k - 1, dp);
                int a = tmp[0];
                int b = tmp[1];
                // 计算 k 位置的运算符的右侧表达式结果为 false 和 ture 的可能数
                tmp = recursion(str, k + 1, r, dp);
                int c = tmp[0];
                int d = tmp[1];
                if (str[k] == '&') {
                    f += a * c + a * d + b * c;
                    t += b * d;
                } else if (str[k] == '|') {
                    f += a * c;
                    t += a * d + b * c + b * d;
                } else {
                    f += a * c + b * d;
                    t += a * d + b * c;
                }
            }
        }

        vector<int> res = {f, t};
        dp[l][r] = res;
        return res;
    }
};
```

