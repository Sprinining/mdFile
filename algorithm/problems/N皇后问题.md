## N皇后问题

- 时间复杂度为 O(n!)

### [51. N 皇后](https://leetcode.cn/problems/n-queens/)

#### 经典做法

```c++
#include <string>
#include <iostream>
#include <vector>
#include <unordered_set>

using namespace std;

class Solution {
public:
    vector<vector<string>> res;
    // 分别标记列和两个方向的斜线上是否已经存在皇后
    unordered_set<int> columns;
    unordered_set<int> diagonals1;
    unordered_set<int> diagonals2;

    vector<vector<string>> solveNQueens(int n) {
        // 记录每一行上，皇后所在的列
        vector<int> queens(n, -1);
        backtrack(queens, n, 0);
        return res;
    }

    void backtrack(vector<int> &queens, int n, int row) {
        if (row == n) {
            // 结算这种情况
            vector<string> board = generateBoard(queens, n);
            res.push_back(board);
            return;
        }
        // 尝试在每一列上放
        for (int i = 0; i < n; i++) {
            // 当前列已有皇后
            if (columns.find(i) != columns.end()) continue;
            // 主斜线已有
            int d1 = row - i;
            if (diagonals1.find(d1) != diagonals1.end()) continue;
            // 副斜线已有
            int d2 = row + i;
            if (diagonals2.find(d2) != diagonals2.end()) continue;

            // 把 row 行的皇后放在 i 列
            queens[row] = i;
            // 标记列和两个方向的斜线上已经存在皇后
            columns.insert(i);
            diagonals1.insert(d1);
            diagonals2.insert(d2);
            // 递归处理下一行
            backtrack(queens, n, row + 1);
            // 取消标记
            queens[row] = -1;
            columns.erase(i);
            diagonals1.erase(d1);
            diagonals2.erase(d2);
        }
    }

    vector<string> generateBoard(vector<int> &queens, int n) {
        vector<string> board;
        for (int i = 0; i < n; i++) {
            string row = string(n, '.');
            row[queens[i]] = 'Q';
            board.push_back(row);
        }
        return board;
    }
};
```

#### 位运算

```c++
#include <string>
#include <vector>

using namespace std;

class Solution {
public:
    vector<vector<string>> res;
    // 记录皇后放的位置，queens[i] 二进制位为 1 的地方才是放皇后的位置
    // 也可以直接记录具体列号，这样生成结果时快些
    vector<int> queens;
    int limit;

    vector<vector<string>> solveNQueens(int n) {
        // 把低 n 位变成 1
        limit = (1 << n) - 1;
        // -1 的位置表示没有皇后
        queens.resize(n, -1);
        backtrack(n, 0, 0, 0, 0);
        return res;
    }

    void backtrack(int n, int row, int columns, int diagonals1, int diagonals2) {
        if (columns == limit) {
            // 生成结果
            res.emplace_back(generateBoard(n));
            return;
        }
        // 0 的位置能放，1 的位置不能放
        int ban = columns | diagonals1 | diagonals2;
        // candidate 为 1 的地方都是可以放皇后的
        int candidate = limit & (~ban);
        // 尝试每个位置
        while (candidate != 0) {
            // 最右侧的 1
            int place = candidate & (-candidate);
            queens[row] = place;
            // 累计上当前皇后的影响，(diagonals1 | place) >> 1 的意思是当前 place 位置放皇后的情况下，主斜线对下一行的影响
            backtrack(n, row + 1, columns | place, (diagonals1 | place) >> 1, (diagonals2 | place) << 1);
            // 删掉最右侧的 1
            candidate ^= place;
        }
    }

    vector<string> generateBoard(int n) {
        vector<string> board;
        for (int i = 0; i < n; i++) {
            string str;
            for (int j = 0; j < n; ++j) {
                if ((queens[i] & (1 << j)) != 0) {
                    str += 'Q';
                } else {
                    str += '.';
                }
            }
            board.emplace_back(str);
        }
        return board;
    }
};
```

### [52. N 皇后 II](https://leetcode.cn/problems/n-queens-ii/)

#### 经典做法

- 常数时间慢

- 过程
  - 用数组记录每一行的皇后所在列
  - 到 row 行时，根据之前行上的皇后位置，判断能放在哪些列
  - 把所有能放的列都尝试一边，每次尝试修改路径数组表示当前的决策

1. 用 set 标记列和斜线上是否已经存在皇后

```c++
#include <string>
#include <iostream>
#include <vector>
#include <unordered_set>

using namespace std;

class Solution {
public:
    // 分别标记列和两个方向的斜线上是否已经存在皇后
    unordered_set<int> columns;
    unordered_set<int> diagonals1;
    unordered_set<int> diagonals2;
    // 记录每行的皇后在哪一列
    vector<int> queens;
    int res;

    void backtrack(int n, int row) {
        if (row == n) {
            res++;
            return;
        }
        for (int i = 0; i < n; ++i) {
            // 如果不能放就跳过
            if (columns.find(i) != columns.end()) continue;
            int d1 = i - row;
            if (diagonals1.find(d1) != diagonals1.end()) continue;
            int d2 = i + row;
            if (diagonals2.find(d2) != diagonals2.end()) continue;

            queens[row] = i;
            // 标记
            columns.emplace(i);
            diagonals1.emplace(d1);
            diagonals2.emplace(d2);
            // 递归处理子问题
            backtrack(n, row + 1);
            // 回溯
            queens[row] = -1;
            columns.erase(i);
            diagonals1.erase(d1);
            diagonals2.erase(d2);
        }

    }

    int totalNQueens(int n) {
        res = 0;
        // -1 表示没有放皇后
        queens.resize(n, -1);
        backtrack(n, 0);
        return res;
    }
};
```

2. 遍历之前的皇后，检查和当前位置是否冲突

```c++
#include <string>
#include <iostream>
#include <vector>
#include <unordered_set>

using namespace std;

class Solution {
public:
    // 记录每行的皇后在哪一列
    vector<int> queens;
    int res;

    void backtrack(int n, int row) {
        if (row == n) {
            res++;
            return;
        }
        for (int column = 0; column < n; ++column) {
            if (!isValid(row, column)) continue;
            queens[row] = column;
            // 递归处理子问题
            backtrack(n, row + 1);
            // 下个尝试的列会覆盖掉 queens[row]，所以不需要手动回溯
        }
    }

    // 判断能否在当前位置放皇后
    bool isValid(int row, int column) {
        for (int i = 0; i < row; ++i)
            if (column == queens[i] || abs(row - i) == abs(column - queens[i]))
                return false;
        return true;
    }

    int totalNQueens(int n) {
        res = 0;
        // -1 表示没有放皇后
        queens.resize(n, -1);
        backtrack(n, 0);
        return res;
    }
};
```

3. 递归带返回值

```c++
#include <string>
#include <iostream>
#include <vector>
#include <unordered_set>

using namespace std;

class Solution {
public:
    // 记录每行的皇后在哪一列
    vector<int> queens;

    // 返回: 0...row-1 行已经摆完了，row....n - 1 行可以去尝试的情况下还能找到几种有效的方法
    int backtrack(int n, int row) {
        if (row == n) return 1;
        int res = 0;
        for (int column = 0; column < n; ++column) {
            if (!isValid(row, column)) continue;
            queens[row] = column;
            // 递归处理子问题
            res += backtrack(n, row + 1);
        }
        return res;
    }

    // 判断能否在当前位置放皇后
    bool isValid(int row, int column) {
        for (int i = 0; i < row; ++i)
            if (column == queens[i] || abs(row - i) == abs(column - queens[i]))
                return false;
        return true;
    }

    int totalNQueens(int n) {
        queens.resize(n, -1);
        return backtrack(n, 0);
    }
};
```

#### 位运算

- 常数时间快

```c++
using namespace std;

class Solution {
public:
    int res;
    int limit;

    // columns 按位标记哪些列上已经有皇后了
    // diagonals1、diagonals2 标记两种方向的斜线上对当前行的影响，为 1 的位置表示在这个斜线上已经有过皇后了
    void backtrack(int columns, int diagonals1, int diagonals2) {
        if (columns == limit) {
            // 低 n 位全是 1，说明每一列都放皇后了，结束
            res++;
            return;
        }

        // 0 的位置能放，1 的位置不能放
        int ban = columns | diagonals1 | diagonals2;
        // candidate 为 1 的地方都是可以放皇后的
        int candidate = limit & (~ban);
        // 尝试每个位置
        while (candidate != 0) {
            // 放皇后的具体位置：取出 candidate 最右侧的 1，也就是列从左往右数第一个能放皇后的列
            int place = candidate & (-candidate);
            // 累计上当前皇后的影响，(diagonals1 | place) >> 1 的意思是当前 place 位置放皇后的情况下，主斜线对下一行的影响
            backtrack(columns | place, (diagonals1 | place) >> 1, (diagonals2 | place) << 1);
            // 把 candidate 最右侧的 1 变成 0，然后尝试下个能放皇后的位置
            candidate ^= place;
        }
    }

    int totalNQueens(int n) {
        res = 0;
        // 把低 n 位变成 1
        limit = (1 << n) - 1;
        backtrack(0, 0, 0);
        return res;
    }
};
```
