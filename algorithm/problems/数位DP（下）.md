## 数位DP（下）

### [P2657 [SCOI2009] windy 数](https://www.luogu.com.cn/problem/P2657)

```c++
#include <iostream>
#include <vector>

using namespace std;

vector<vector<vector<int>>> dp;

// 剩下 len 位没有确定
// 上一位数字为 pre，除了 pre = 10 时，表示之前的位都没有选数字
// 之前的位以及决定数字比 num 小，则 free = 1
int fc(int num, int len, int offset, int pre, int free) {
    if (len == 0) return 1;
    if (dp[len][pre][free] != -1) return dp[len][pre][free];

    int cur = (num / offset) % 10;
    int res = 0;

    if (free == 0) {
        // 之前的位和 num 一致，当前位不能超过 num 的当前位
        if (pre == 10) {
            // 且之前啥都没选，说明当前是 num 的最高位
            res += fc(num, len - 1, offset / 10, 10, 1);
            for (int i = 1; i < cur; ++i)
                res += fc(num, len - 1, offset / 10, i, 1);
            res += fc(num, len - 1, offset / 10, cur, 0);
        } else {
            // 之前位选过数字
            for (int i = 0; i <= 9; ++i) {
                // 必须保证相邻的数字差值大于等于 2
                if (abs(i - pre) < 2) continue;
                if (i < cur) {
                    res += fc(num, len - 1, offset / 10, i, 1);
                } else if (i == cur) {
                    res += fc(num, len - 1, offset / 10, i, 0);
                }
            }
        }
    } else {
        if (pre == 10) {
            // 位数变少了
            res += fc(num, len - 1, offset / 10, 10, 1);
            for (int i = 1; i <= 9; ++i)
                res += fc(num, len - 1, offset / 10, i, 1);
        } else {
            for (int i = 0; i <= 9; ++i)
                if (abs(i - pre) >= 2)
                    res += fc(num, len - 1, offset / 10, i, 1);
        }
    }

    dp[len][pre][free] = res;
    return res;
}

int cnt(int num) {
    if (num == 0) return 1;
    int len = 1, offset = 1, temp = num / 10;
    while (temp > 0) {
        len++;
        offset *= 10;
        temp /= 10;
    }
    dp = vector<vector<vector<int>>>(len + 1, vector<vector<int>>(11, vector<int>(2, -1)));
    return fc(num, len, offset, 10, 0);
}

int main() {
    int a, b;
    while (cin >> a >> b)
        cout << cnt(b) - cnt(a - 1) << '\n';
    return 0;
}
```

### [P3413 SAC#1 - 萌数](https://www.luogu.com.cn/problem/P3413)

```c++
#include <iostream>
#include <vector>
#include <string>

using namespace std;

const int MOD = 1e9 + 7;

// dp[i][pp][p][free]
// i：当前处理的位数
// pp：前前一位的数字（如果未使用则为10）
// p：前一位的数字（如果未使用则为10）
// free：是否可以自由选择数字
vector<vector<vector<vector<int>>>> dp;

// 构建 DP 表
void build(int n) {
    dp.assign(n, vector<vector<vector<int>>>(
            11, vector<vector<int>>(
                    11, vector<int>(2, -1)
            )
    ));
}

// 检查一个数字是否为“萌数”
// 即是否含有长度 >= 2 的回文子串
bool check(const string &num) {
    for (int i = 0; i < num.size(); ++i) {
        if (i >= 2 && num[i] == num[i - 2]) return true;
        if (i >= 1 && num[i] == num[i - 1]) return true;
    }
    return false;
}

// fc: 数位 DP 的核心函数，用于计算 <= num 的“非萌数”数量
// i: 当前数位（从高位向低位）
// pp: 前前一位数字（用于判断是否形成长度 >= 3 的回文）
// p: 前一位数字
// free: 当前位是否可以自由选择（即前缀已经严格小于 num）
int fc(const string &num, int i, int pp, int p, int free) {
    if (i == num.size()) return 1;
    if (dp[i][pp][p][free] != -1) return dp[i][pp][p][free];

    int res = 0;

    // 当前这一位最多能选到多少（取决于是否自由）
    int up = (free ? 9 : num[i] - '0');

    // 遍历当前这一位可以放的所有数字
    for (int cur = 0; cur <= up; ++cur) {
        if (p == 10 && cur == 0) {
            // 特殊处理：前面尚未开始选数字 && 当前位也选择了 0，相当于继续不选数字（跳过当前位）
            // 代表前缀 0，不算进数字构造
            res = (res + fc(num, i + 1, 10, 10, 1)) % MOD;
            continue;
        }

        // 如果当前数字和前一位或前前一位相同，就形成了回文子串，跳过这个状态（因为我们只要“非萌数”）
        if (cur == p || cur == pp) continue;

        // 判断下一个位置是否“自由选择”
        // free == 1 说明前面已经放了一个小于 num[i] 的数字，当前就是完全自由了
        // cur < up 说明当前数字比限制小，下一个也就不再受限了
        int nextFree = (free || cur < up) ? 1 : 0;

        // 递归求解下一位，更新 pp=p，p=cur，free 状态同步
        res = (res + fc(num, i + 1, p, cur, nextFree)) % MOD;
    }

    return dp[i][pp][p][free] = res;
}

// 将字符串形式的数字 num 转为 <= num 且不是萌数的个数
int countNonM(const string &num) {
    build(num.size());
    return fc(num, 0, 10, 10, 0);
}

// 返回 [0, num] 中的“萌数”数量
int cnt(const string &num) {
    if (num[0] == '0') return 0;

    // 把 num 转成数值
    long long all = 0, base = 1;
    for (int i = num.size() - 1; i >= 0; --i) {
        all = (all + base * (num[i] - '0')) % MOD;
        base = (base * 10) % MOD;
    }

    int notM = countNonM(num);
    return (int) ((all - notM + MOD) % MOD);
}

// 计算 l 到 r 范围内的萌数个数
int compute(const string &l, const string &r) {
    int res = (cnt(r) - cnt(l) + MOD) % MOD;
    if (check(l)) res = (res + 1) % MOD;
    return res;
}

int main() {
    string l, r;
    cin >> l >> r;
    cout << compute(l, r) << "\n";
    return 0;
}
```

### [600. 不含连续1的非负整数](https://leetcode.cn/problems/non-negative-integers-without-consecutive-ones/)

- 递归

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    int findIntegers(int n) {
        // cnt[i] 表示 i 位长度下，合法状态数
        vector<int> cnt(31, 0);
        cnt[0] = 1;
        cnt[1] = 2;
        for (int i = 2; i <= 30; ++i) {
            // 斐波那契
            cnt[i] = cnt[i - 1] + cnt[i - 2];
        }
        return fc(cnt, n, 30);
    }

    // 从高位向低位检查，统计合法数量
    int fc(const vector<int> &cnt, int num, int i) {
        if (i == -1) return 1;

        int res = 0;
        if ((num & (1 << i)) != 0) {
            // 当前位是 1，尝试将这一位变为 0，下面位可以任意取合法组合
            res += cnt[i];
            // 检查 i + 1 位是否也是1，如果是，则出现连续的 1，提前结束
            if ((num & (1 << (i + 1))) != 0) return res;
        }
        // 递归下一位（当前位是 0 或合法）
        res += fc(cnt, num, i - 1);
        return res;
    }
};
```

- 迭代

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    int findIntegers(int n) {
        vector<int> cnt(31, 0);
        cnt[0] = 1;
        cnt[1] = 2;
        for (int i = 2; i <= 30; ++i) {
            cnt[i] = cnt[i - 1] + cnt[i - 2];
        }

        int res = 0;
        for (int i = 30; i >= -1; --i) {
            if (i == -1) {
                ++res;
                break;
            }
            if ((n & (1 << i)) != 0) {
                res += cnt[i];
                // 如果当前位和上一位都是1，出现连续1，不合法
                if ((n & (1 << (i + 1))) != 0) {
                    break;
                }
            }
        }
        return res;
    }

    // 从高位向低位检查，统计合法数量
    int fc(const vector<int> &cnt, int num, int i) {
        if (i == -1) return 1;

        int res = 0;
        if ((num & (1 << i)) != 0) {
            // 当前位是 1，尝试将这一位变为 0，下面位可以任意取合法组合
            res += cnt[i];
            // 检查 i + 1 位是否也是1，如果是，则出现连续的 1，提前结束
            if ((num & (1 << (i + 1))) != 0) return res;
        }
        // 递归下一位（当前位是 0 或合法）
        res += fc(cnt, num, i - 1);
        return res;
    }
};
```

### [233. 数字 1 的个数](https://leetcode.cn/problems/number-of-digit-one/)

```c++
#include <iostream>

using namespace std;

class Solution {
public:
    // 主方法：返回 1~n 中数字 1 出现的次数
    int countDigitOne(int n) {
        return count(n, 1);
    }

    // 统计数字 d 在 [1, num] 范围中出现的次数
    int count(int num, int d) {
        long long res = 0;

        // 情况1：
        // d != 0
        // 1 ~ 30583 , d = 5
        // cur < d的情况
        // 个位cur=3 : 0000~3057 5
        // 个位上没有额外加
        //
        // cur > d的情况
        // 十位cur=8 : 000~304 5 0~9
        // 十位上额外加 : 305 5 0~9
        //
        // cur == d的情况
        // 百位cur=5 : 00~29 5 00~99
        // 百位上额外加 : 30 5 00~83
        // ...
        // 情况2：
        // d == 0
        // 1 ~ 30583 d = 0
        // cur > d的情况
        // 个位cur=3 : 0001~3057 0
        // 个位上额外加 : 3058 0
        //
        // cur > d的情况
        // 十位cur=8 : 001~304 0 0~9
        // 十位上额外加 : 305 0 0~9
        //
        // cur > d的情况
        // 百位cur=5 : 01~29 0 00~99
        // 百位上额外加 : 30 0 00~99
        //
        // cur == d的情况
        // 千位cur=0 : 1~2 0 000~099
        // 千位上额外加 : 3 0 000~583

        // right 表示当前位右边的情况数
        for (long long right = 1, temp = num; temp != 0; right *= 10, temp /= 10) {
            // left 表示当前位左边的情况数
            long long left = temp / 10;
            // 当前位的数字（正在处理的位）
            long long cur = temp % 10;

            // 处理前导 0 的情况（不能以 0 开头，所以需要特殊减 1）
            if (d == 0) left--;

            // 当前这一位上，数字 d 出现的可能数
            res += left * right;

            if (cur > d) {
                // 如果当前位数字大于 d，那么右边可以从 0 枚举到 999...，即全加一轮 right
                res += right;
            } else if (cur == d) {
                // 如果当前位等于 d，那么右边可以取值的范围是 [0, 右边真实数值]
                res += num % right + 1;
            }
            // 如果 cur < d，当前这一位上就不能再出现 d，不做额外加法
        }

        return (int) res;
    }
};
```