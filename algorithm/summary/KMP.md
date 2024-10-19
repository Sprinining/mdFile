## KMP

s1 字符串是否包含 s2 字符串，如果包含返回 s1 中包含 s2 的最左开头位置，不包含返回 -1

暴力方法就是 s1 的每个位置都做开头，然后去匹配 s2 整体，时间复杂度 O(n * m)

KMP 算法可以做到时间复杂度 O(n + m)

### [28. 找出字符串中第一个匹配项的下标](https://leetcode.cn/problems/find-the-index-of-the-first-occurrence-in-a-string/)

```c++
#include <iostream>
#include <vector>

using namespace std;

class Solution {
public:
    // next 数组：规定 next[0] = -1
    // 其他位置 next[i] = a 表示 p[0, i-1] 子串的真前缀和真后缀的最大匹配长度（即前后缀不包含整个子串）为 a
    vector<int> getNextArr(string &p) {
        int m = p.length();
        if (m == 1) return {-1};
        vector<int> next(m);
        // 起始位置规定为 -1
        next[0] = -1;
        next[1] = 0;
        int i = 2;
        // 前面子串中和当前位置进行对比的位置
        int pre = 0;
        while (i < m) {
            if (p[i - 1] == p[pre]) {
                next[i++] = ++pre;
            } else if (pre > 0) {
                // 往前跳
                pre = next[pre];
            } else {
                next[i++] = 0;
            }
        }

        return next;
    }

    // 时间复杂度 O(n + m)
    int kmp(string &s, string &p) {
        int n = s.length();
        int m = p.length();
        // 时间复杂度 O(m)
        vector<int> next = getNextArr(p);

        // 字符串 s 当前匹配位置
        int i = 0;
        // 模式串 p 当前匹配位置
        int j = 0;
        // 时间复杂度 O(n)
        while (i < n && j < m) {
            if (s[i] == p[j]) {
                i++;
                j++;
            } else if (j == 0) {
                i++;
            } else {
                j = next[j];
            }
        }
        return j == m ? i - m : -1;
    }

    int strStr(string haystack, string needle) {
        return kmp(haystack, needle);
    }
};
```

### [572. 另一棵树的子树](https://leetcode.cn/problems/subtree-of-another-tree/)

- 暴力递归

```c++
#include <iostream>
#include <vector>

using namespace std;

struct TreeNode {
    int val;
    TreeNode *left;
    TreeNode *right;

    TreeNode() : val(0), left(nullptr), right(nullptr) {}

    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}

    TreeNode(int x, TreeNode *left, TreeNode *right) : val(x), left(left), right(right) {}
};

class Solution {
public:
    // 判断两棵树是否完全一样
    bool isSame(TreeNode *r1, TreeNode *r2) {
        if (r1 == nullptr && r2 == nullptr) return true;
        if (r1 == nullptr || r2 == nullptr) return false;
        return r1->val == r2->val && isSame(r1->left, r2->left) && isSame(r1->right, r2->right);
    }

    // 时间复杂度 O(n * m)
    bool isSubtree(TreeNode *root, TreeNode *subRoot) {
        if (root != nullptr && subRoot != nullptr)
            return isSame(root, subRoot) || isSubtree(root->left, subRoot) || isSubtree(root->right, subRoot);
        return subRoot == nullptr;
    }
};
```

- 先序序列化（遇到空节点要记录） + KMP

```c++
#include <iostream>
#include <vector>

using namespace std;

struct TreeNode {
    int val;
    TreeNode *left;
    TreeNode *right;

    TreeNode() : val(0), left(nullptr), right(nullptr) {}

    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}

    TreeNode(int x, TreeNode *left, TreeNode *right) : val(x), left(left), right(right) {}
};

class Solution {
public:
    // next 数组：规定 next[0] = -1
    // 其他位置 next[i] = a 表示 p[0, i-1] 子串的真前缀和真后缀的最大匹配长度（即前后缀不包含整个子串）为 a
    vector<int> getNextArr(vector<string> &p) {
        int m = p.size();
        if (m == 1) return {-1};
        vector<int> next(m);
        // 起始位置规定为 -1
        next[0] = -1;
        next[1] = 0;
        int i = 2;
        // 前面子串中和当前位置进行对比的位置
        int pre = 0;
        while (i < m) {
            if (p[i - 1] == p[pre]) {
                next[i++] = ++pre;
            } else if (pre > 0) {
                // 往前跳
                pre = next[pre];
            } else {
                next[i++] = 0;
            }
        }

        return next;
    }

    // 时间复杂度 O(n + m)
    int kmp(vector<string> &s, vector<string> &p) {
        int n = s.size();
        int m = p.size();
        // 时间复杂度 O(m)
        vector<int> next = getNextArr(p);

        // 字符串 s 当前匹配位置
        int i = 0;
        // 模式串 p 当前匹配位置
        int j = 0;
        // 时间复杂度 O(n)
        while (i < n && j < m) {
            if (s[i] == p[j]) {
                i++;
                j++;
            } else if (j == 0) {
                i++;
            } else {
                j = next[j];
            }
        }
        return j == m ? i - m : -1;
    }

    // 中序序列化，空节点也记录
    void serial(TreeNode *root, vector<string> &path) {
        if (root == nullptr) {
            path.emplace_back("null");
            return;
        }
        path.emplace_back(to_string(root->val));
        serial(root->left, path);
        serial(root->right, path);
    }

    // 时间复杂度 O(n * m)
    bool isSubtree(TreeNode *root, TreeNode *subRoot) {
        vector<string> s;
        vector<string> p;
        serial(root, s);
        serial(subRoot, p);
        return kmp(s, p) != -1;
    }
};
```

### [P4391 [BOI2009] Radio Transmission 无线传输](https://www.luogu.com.cn/problem/P4391)

```c++
#include <iostream>
#include <vector>

using namespace std;

vector<int> getNextArr(string s) {
    int n = s.size();
    // 多求了一位
    vector<int> next(n + 1);
    next[0] = -1;
    next[1] = 0;
    int i = 2, pre = 0;
    while (i <= n) {
        if (s[i - 1] == s[pre]) {
            next[i++] = ++pre;
        } else if (pre > 0) {
            pre = next[pre];
        } else {
            next[i++] = 0;
        }
    }
    return next;
}

int main() {
    int n;
    cin >> n;
    string s;
    cin >> s;

    vector<int> next = getNextArr(s);
    cout << n - next[n];
}
```

### [P4824 [USACO15FEB] Censoring S](https://www.luogu.com.cn/problem/P4824)

```c++
#include <iostream>
#include <vector>
#include <stack>

using namespace std;

int MAXN = 1000001;
vector<int> nxt(1000001);
// <s 中的位置 i，t 中与 s[i] 匹配的位置>
vector<pair<int, int>> stk(MAXN);
// 栈顶位置
int top;

void generateNxt(string s) {
    nxt[0] = -1;
    int n = s.size();
    if (n == 1) return;
    nxt[1] = 0;
    int i = 2, pre = 0;
    while (i < n) {
        if (s[i - 1] == s[pre]) {
            nxt[i++] = ++pre;
        } else if (pre > 0) {
            pre = nxt[pre];
        } else {
            nxt[i++] = 0;
        }
    }
}

int main() {
    string s, t;
    cin >> s >> t;
    int n = s.length();
    int m = t.length();

    top = 0;
    generateNxt(t);

    int i = 0, j = 0;
    while (i < n) {
        if (s[i] == t[j]) {
            stk[top++] = make_pair(i, j);
            i++;
            j++;
        } else if (j == 0) {
            stk[top++] = make_pair(i, -1);
            i++;
        } else {
            j = nxt[j];
        }
        if (j == m) {
            // 弹出一个字符串 t
            top -= m;
            // 如果栈非空，栈顶 s[stk[top - 1].first] 当前和 t[stk[top - 1].second] 匹配，就从下一位置继续和 i 对比
            // 如果栈空，就从 t 的起始位置继续和 i 对比
            j = top > 0 ? stk[top - 1].second + 1 : 0;
        }
    }

    string res = "";
    // 输出栈中剩下的字符
    for (int k = 0; k < top; ++k)
        res += s[stk[k].first];
    cout << res;
}
```

### [1367. 二叉树中的链表](https://leetcode.cn/problems/linked-list-in-binary-tree/)

- 递归

```c++
using namespace std;

struct ListNode {
    int val;
    ListNode *next;

    ListNode() : val(0), next(nullptr) {}

    ListNode(int x) : val(x), next(nullptr) {}

    ListNode(int x, ListNode *next) : val(x), next(next) {}
};

struct TreeNode {
    int val;
    TreeNode *left;
    TreeNode *right;

    TreeNode() : val(0), left(nullptr), right(nullptr) {}

    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}

    TreeNode(int x, TreeNode *left, TreeNode *right) : val(x), left(left), right(right) {}
};

class Solution {
public:
    // 判断是否能从当前节点匹配全部链表
    bool dfsJudge(struct TreeNode *root, struct ListNode *head) {
        if (head == nullptr) return true;
        if (root == nullptr || root->val != head->val) return false;
        return dfsJudge(root->left, head->next) || dfsJudge(root->right, head->next);
    }

    // 遍历二叉树
    bool dfs(struct TreeNode *root, struct ListNode *head) {
        if (root == nullptr) return false;
        if (dfsJudge(root, head)) return true;
        return dfs(root->left, head) || dfs(root->right, head);
    }

    bool isSubPath(ListNode *head, TreeNode *root) {
        return dfs(root, head);
    }
};
```

- KMP

```c++
#include <iostream>
#include <vector>

using namespace std;

struct ListNode {
    int val;
    ListNode *next;

    ListNode() : val(0), next(nullptr) {}

    ListNode(int x) : val(x), next(nullptr) {}

    ListNode(int x, ListNode *next) : val(x), next(next) {}
};

struct TreeNode {
    int val;
    TreeNode *left;
    TreeNode *right;

    TreeNode() : val(0), left(nullptr), right(nullptr) {}

    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}

    TreeNode(int x, TreeNode *left, TreeNode *right) : val(x), left(left), right(right) {}
};

class Solution {
public:

    void generateNext(ListNode *head, vector<int> &list, vector<int> &next) {
        // 链表转成数组
        while (head != nullptr) {
            list.emplace_back(head->val);
            head = head->next;
        }
        int n = list.size();
        // 生成 list 数组的 next 数组
        next.resize(n);
        next[0] = -1;
        if (n == 1) return;
        next[1] = 0;
        int i = 2, pre = 0;
        while (i < n) {
            if (list[i - 1] == list[pre]) {
                next[i++] = ++pre;
            } else if (pre > 0) {
                pre = next[pre];
            } else {
                next[i++] = 0;
            }
        }
    }

    // 从 list[cur] 和 root.val 开始往下对比，返回能否将 list 全部匹配
    bool dfs(vector<int> &list, vector<int> &next, TreeNode *root, int cur) {
        if (cur == list.size()) return true;
        if (root == nullptr) return false;
        // 失配时，找到上一个匹配的位置
        // 均摊下来，时间复杂度 O(1)
        while (cur >= 0 && root->val != list[cur])
            cur = next[cur];
        // 推出循环时，i == -1 或者 i >=0 （匹配上了）
        // 子树从下个位置 list[cur + 1] 对比
        return dfs(list, next, root->left, cur + 1) || dfs(list, next, root->right, cur + 1);
    }

    // 时间复杂度 O(n + m)
    bool isSubPath(ListNode *head, TreeNode *root) {
        vector<int> list;
        vector<int> next;
        generateNext(head, list, next);
        return dfs(list, next, root, 0);
    }
};
```

### [1397. 找到所有好字符串](https://leetcode.cn/problems/find-all-good-strings/)

```c++
// todo 数位DP
```

