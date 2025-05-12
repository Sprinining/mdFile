## 数位DP（上）

### [357. 统计各位数字都不同的数字个数](https://leetcode.cn/problems/count-numbers-with-unique-digits/)

```c++
using namespace std;

class Solution {
public:
    int countNumbersWithUniqueDigits(int n) {
        if (n == 0) return 1;
        int res = 10;
        // 1: 10
        // 2: 9 * 9
        // 3: 9 * 9 * 8
        // 4: 9 * 9 * 8 * 7
        for (int s = 9, i = 9, k = 2; k <= n; i--, k++) {
            s *= i;
            res += s;
        }
        return res;
    }
};
```

### [902. 最大为 N 的数字组合](https://leetcode.cn/problems/numbers-at-most-n-given-digit-set/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int atMostNGivenDigitSet(vector<string> &arr, int num) {
        // 获取 num 位数
        int len = 1;
        // 1000... 长度为 len
        int offset = 1;
        int temp = num / 10;
        while (temp > 0) {
            len++;
            offset *= 10;
            temp /= 10;
        }

        vector<int> digits(arr.size());
        for (int i = 0; i < arr.size(); ++i)
            digits[i] = stoi(arr[i]);

        return fc(digits, num, len, offset, false, false);
    }

    // 剩下 len 位没有确定
    // free 为 true 表示之前的位已经确定比 num 小，后续的数字可以随便选
    // free 为 false 表示之前的位和 num 一样，剩下的数字不能大于 num 当前位的数字
    // fix 为 false 表示之前的位都没有数字
    int fc(vector<int> &digits, int num, int len, int offset, bool free, bool fix) {
        if (len == 0) return fix ? 1 : 0;
        int res = 0;
        // p1: 当前位不选任何数字
        if (!fix) res += fc(digits, num, len - 1, offset / 10, true, false);
        if (free) {
            // p2: 当前位可以随便选
            res += digits.size() * fc(digits, num, len - 1, offset / 10, true, true);
        } else {
            // p3: 当前位不能超过 cur
            // num 当前位的数字
            int cur = (num / offset) % 10;
            // digits 非递减
            for (const auto &i: digits) {
                if (i < cur) {
                    res += fc(digits, num, len - 1, offset / 10, true, true);
                } else if (i == cur) {
                    res += fc(digits, num, len - 1, offset / 10, false, true);
                } else {
                    break;
                }
            }
        }
        return res;
    }
};
```

```c++
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

class Solution {
public:
    int atMostNGivenDigitSet(vector<string> &arr, int num) {
        // 获取 num 位数
        int len = 1;
        // 1000... 长度为 len
        int offset = 1;
        int temp = num / 10;
        while (temp > 0) {
            len++;
            offset *= 10;
            temp /= 10;
        }

        int m = arr.size();
        vector<int> digits(m);
        for (int i = 0; i < m; ++i)
            digits[i] = stoi(arr[i]);

        vector<int> cnt(len);
        cnt[0] = 1;
        int res = 0;
        for (int i = m, k = 1; k < len; k++, i *= m) {
            cnt[k] = i;
            res += i;
        }
        return res + fc(digits, num, len, offset, cnt);
    }

    int fc(vector<int> &digits, int num, int len, int offset, vector<int> &cnt) {
        // num 自身
        if (len == 0) return 1;
        int cur = (num / offset) % 10;
        int res = 0;
        for (const auto &i: digits) {
            if (i < cur) {
                // 后面 len - 1 位都可以任选，可能数为 cnt[len - 1]
                res += cnt[len - 1];
            } else if (i == cur) {
                res += fc(digits, num, len - 1, offset / 10, cnt);
            } else {
                break;
            }
        }
        return res;
    }
};
```

### [2719. 统计整数数目](https://leetcode.cn/problems/count-of-integers/)

```c++
#include <iostream>
#include <vector>
#include <string>
#include <cstring>

using namespace std;

class Solution {
public:
    static const int MOD = 1000000007;
    static const int MAXN = 23;
    static const int MAXM = 401;

    vector<vector<vector<int>>> dp;
    // 数字
    string num;
    // 数字累加和的范围以及数字长度
    int minSum, maxSum, len;

    int count(string num1, string num2, int min_sum, int max_sum) {
        minSum = min_sum;
        maxSum = max_sum;

        // 处理 num2
        num = num2;
        len = num.length();
        initDP();
        int res = fc(0, 0, 0);

        // 处理 num1
        num = num1;
        len = num.length();
        initDP();
        res = (res - fc(0, 0, 0) + MOD) % MOD;

        // 补上 num1 本身是否符合条件
        if (check()) res = (res + 1) % MOD;
        return res;
    }

    void initDP() {
        dp = vector<vector<vector<int>>>(
                MAXN,
                vector<vector<int>>(MAXM, vector<int>(2, -1))
        );
    }

    // i: 当前位
    // sum: 当前数字累加和
    // free: 是否可以自由选择数字
    int fc(int i, int sum, int free) {
        if (sum > maxSum) return 0;
        if (sum + (len - i) * 9 < minSum) return 0;
        if (i == len) return (sum >= minSum) ? 1 : 0;

        if (dp[i][sum][free] != -1) return dp[i][sum][free];

        int res = 0;
        int cur = num[i] - '0';

        if (free == 0) {
            // p1: 不能自由选择
            for (int pick = 0; pick < cur; ++pick)
                res = (res + fc(i + 1, sum + pick, 1)) % MOD;
            // pick == cur
            res = (res + fc(i + 1, sum + cur, 0)) % MOD;
        } else {
            // p2: 能自由选择
            for (int pick = 0; pick <= 9; ++pick)
                res = (res + fc(i + 1, sum + pick, 1)) % MOD;
        }

        dp[i][sum][free] = res;
        return res;
    }

    bool check() {
        int sum = 0;
        for (char c: num)
            sum += c - '0';
        return sum >= minSum && sum <= maxSum;
    }
};
```

### [2376. 统计特殊整数](https://leetcode.cn/problems/count-special-integers/)

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    int countSpecialNumbers(int n) {
        int len = 1;
        int offset = 1;
        int temp = n / 10;
        while (temp > 0) {
            len++;
            offset *= 10;
            temp /= 10;
        }

        // cnt[i]: 长度为 len，还剩 i 位没确定，前缀为 len - i 位，并且前缀不为空，有多少种合法的排列（没有重复数字）
        // 0~9 一共 10 个数字，没有选择的数字剩下 10-(len-i) 个
        // 那么在后续的 i 位上，有多少种排列
        // 比如：len = 4
        // cnt[4]不计算
        // cnt[3] = 9 * 8 * 7
        // cnt[2] = 8 * 7
        // cnt[1] = 7
        // cnt[0] = 1，表示前缀已确定，后续也没有了，那么就是 1 种排列，就是前缀的状况
        // 再比如：len = 6
        // cnt[6]不计算
        // cnt[5] = 9 * 8 * 7 * 6 * 5
        // cnt[4] = 8 * 7 * 6 * 5
        // cnt[3] = 7 * 6 * 5
        // cnt[2] = 6 * 5
        // cnt[1] = 5
        // cnt[0] = 1，表示前缀已确定，后续也没有了，那么就是 1 种排列，就是前缀的状况
        vector<int> cnt(len);
        cnt[0] = 1;
        for (int i = 1, k = 10 - len + 1; i < len; i++, k++)
            cnt[i] = cnt[i - 1] * k;

        int res = 0;
        if (len >= 2) {
            // p1: 先加上所有位数小于 len 的合法数
            res = 9;
            for (int i = 2, a = 9, b = 9; i < len; i++, b--) {
                a *= b;
                res += a;
            }
        }

        // p2: 处理等于 len 位的数中满足要求的部分
        int first = n / offset;
        // 小于 num 最高位数字的情况
        res += (first - 1) * cnt[len - 1];
        // 等于 num 最高位数字的情况
        res += f(cnt, n, len - 1, offset / 10, 1 << first);
        return res;
    }

    // 已经确定了和 num 一样的前缀，且确定的部分一定不为空，还有 len 位没有确定
    // status: 当前已经使用过的数字集合（用位掩码表示）
    int f(vector<int> &cnt, int num, int len, int offset, int status) {
        // num 自身
        if (len == 0) return 1;

        int res = 0;
        int cur = (num / offset) % 10;
        for (int i = 0; i < cur; i++)
            // 没有用过的数字才行
            if ((status & (1 << i)) == 0)
                res += cnt[len - 1];

        // 尝试继续保持前缀一致
        if ((status & (1 << cur)) == 0)
            res += f(cnt, num, len - 1, offset / 10, status | (1 << cur));

        return res;
    }
};
```