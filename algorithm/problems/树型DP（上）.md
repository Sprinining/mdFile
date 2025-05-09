## 树型DP（上）

### [最大BST子树](https://leetcode.cn/problems/largest-bst-subtree/description/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>
#include <climits>

using namespace std;

class TreeNode {
public:
    int val;
    TreeNode *left;
    TreeNode *right;

    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}
};

class Info {
public:
    // 整个树的最大节点值
    long max;
    // 整个树的最小节点值
    long min;
    // 整棵树是否是 BST
    bool isBst;
    // 整棵树上的最大的 BST 的大小
    int maxBstSize;

    Info(long a, long b, bool c, int d) : max(a), min(b), isBst(c), maxBstSize(d) {}
};

class Solution {
public:
    int largestBSTSubtree(TreeNode *root) {
        return fc(root).maxBstSize;
    }

private:
    // 后序遍历
    Info fc(TreeNode *node) {
        // 防止空节点干扰父节点是否是 BST 的判断
        // 左空节点的最大值为 LONG_MIN 才能满足小于父节点 int 值
        if (node == nullptr)
            return Info(LONG_MIN, LONG_MAX, true, 0);

        Info lInfo = fc(node->left);
        Info rInfo = fc(node->right);

        long max_ = std::max((long) node->val, std::max(lInfo.max, rInfo.max));
        long min_ = std::min((long) node->val, std::min(lInfo.min, rInfo.min));
        bool isBst = lInfo.isBst && rInfo.isBst && lInfo.max < node->val && node->val < rInfo.min;

        int maxBSTSize;
        if (isBst) {
            maxBSTSize = lInfo.maxBstSize + rInfo.maxBstSize + 1;
        } else {
            maxBSTSize = std::max(lInfo.maxBstSize, rInfo.maxBstSize);
        }
        // 返回父节点可能用到的所有信息
        return Info(max_, min_, isBst, maxBSTSize);
    }
};

int main() {
    /*
        构造如下二叉树：
                10
               /  \
              5   15
             / \    \
            1   8    7

        最大的 BST 子树是：
                5
               / \
              1   8
        所以最大 BST 子树大小是 3。
    */

    TreeNode *root = new TreeNode(10);
    root->left = new TreeNode(5);
    root->right = new TreeNode(15);
    root->left->left = new TreeNode(1);
    root->left->right = new TreeNode(8);
    root->right->right = new TreeNode(7);

    Solution sol;
    int result = sol.largestBSTSubtree(root);
    cout << "最大BST子树的大小是: " << result << endl;

    // 清理内存
    delete root->left->left;
    delete root->left->right;
    delete root->left;
    delete root->right->right;
    delete root->right;
    delete root;

    return 0;
}
```

### [1373. 二叉搜索子树的最大键值和](https://leetcode.cn/problems/maximum-sum-bst-in-binary-tree/)

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

struct Info {
    int minVal;
    int maxVal;
    bool isBST;
    // 树的累加和，与是否是 BST 无关
    int sum;
    int maxBSTSum;

    Info(int minVal, int maxVal, bool isBST, int sum, int maxBSTSum) : minVal(minVal), maxVal(maxVal), isBST(isBST),
                                                                       sum(sum),
                                                                       maxBSTSum(maxBSTSum) {}
};

class Solution {
public:
    int maxSumBST(TreeNode *root) {
        return fc(root).maxBSTSum;
    }

    Info fc(TreeNode *root) {
        if (root == nullptr) return Info(INT_MAX, INT_MIN, true, 0, 0);

        Info l = fc(root->left);
        Info r = fc(root->right);

        int minVal = min(root->val, min(l.minVal, r.minVal));
        int maxVal = max(root->val, max(l.maxVal, r.maxVal));
        bool isBST = l.isBST && r.isBST && (l.maxVal < root->val) && (root->val < r.minVal);
        int sum = l.sum + r.sum + root->val;
        int maxBSTSum = max(l.maxBSTSum, r.maxBSTSum);
        if (isBST) maxBSTSum = max(sum, maxBSTSum);

        return Info(minVal, maxVal, isBST, sum, maxBSTSum);
    }
};
```

### [543. 二叉树的直径](https://leetcode.cn/problems/diameter-of-binary-tree/)

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

struct Info {
    int height;
    int maxPath;

    Info(int h, int m) : height(h), maxPath(m) {}
};

class Solution {
public:
    int diameterOfBinaryTree(TreeNode *root) {
        return fc(root).maxPath;
    }

    Info fc(TreeNode *root) {
        if (root == nullptr) return Info(0, 0);

        Info l = fc(root->left);
        Info r = fc(root->right);

        int height = max(l.height, r.height) + 1;
        int maxPath = max(l.maxPath, r.maxPath);
        maxPath = max(maxPath, l.height + r.height);

        return Info(height, maxPath);
    }
};
```

### [979. 在二叉树中分配硬币](https://leetcode.cn/problems/distribute-coins-in-binary-tree/)

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

struct Info {
    // 节点总数
    int count;
    // 硬币总数
    int coins;
    // 移动步数
    int move;

    Info(int ct, int c, int m) : count(ct), coins(c), move(m) {}
};

class Solution {
public:
    int distributeCoins(TreeNode *root) {
        return fc(root).move;
    }

    Info fc(TreeNode *root) {
        if (root == nullptr) return Info(0, 0, 0);

        Info l = fc(root->left);
        Info r = fc(root->right);

        int count = l.count + r.count + 1;
        int coins = l.coins + r.coins + root->val;
        // l.move 是指将 l 的左子树的硬币和左子树节点个数匹配，且 l 的右子树硬币和右子树节点个数匹配，所需要的步数
        // 尽管移动完后，l 节点的硬币数可能是正可能是负（根节点操作完刚好是 1）
        // abs(l.count - l.coins) 是指 l 向其父节点送去硬币或取回硬币，使得 l 节点刚好有一个硬币，操作完后，l 子树的每个节点都有一个硬币
        // r 也同理
        int move = l.move + r.move + abs(l.count - l.coins) + abs(r.count - r.coins);
        return Info(count, coins, move);
    }
};
```

### [337. 打家劫舍 III](https://leetcode.cn/problems/house-robber-iii/)

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

struct Info {
    // 选这个节点的情况下的最高金额
    int pick;
    // 不选这个节点的情况下的最高金额
    int noPick;

    Info(int a, int b) : pick(a), noPick(b) {}
};

class Solution {
public:
    int rob(TreeNode *root) {
        Info i = fc(root);
        // 最终结果是在当前节点选或不选的两种情况下二选一
        return max(i.pick, i.noPick);
    }

    Info fc(TreeNode *root) {
        if (root == nullptr) return Info(0, 0);

        Info l = fc(root->left);
        Info r = fc(root->right);

        // 选中当前节点，那么子节点一定不能选
        int pick = root->val + l.noPick + r.noPick;
        // 不选当前节点，子节点可选可不选
        int noPick = max(l.pick, l.noPick) + max(r.pick, r.noPick);
        return Info(pick, noPick);
    }
};
```

### [968. 监控二叉树](https://leetcode.cn/problems/binary-tree-cameras/)

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

class Solution {
public:
    int res;

    int minCameraCover(TreeNode *root) {
        res = 0;
        if (fc(root) == 0) res++;
        return res;
    }

    // 0: root 是无覆盖的状态，root 下方的节点都已经被覆盖
    // 1: root 是覆盖状态，root 上没摄像头，root 下方的节点都已经被覆盖
    // 2: root 是覆盖状态，root 上有摄像头，root 下方的节点都已经被覆盖
    int fc(TreeNode *root) {
        if (root == nullptr) return 1;
        int l = fc(root->left);
        int r = fc(root->right);
        if (l == 0 || r == 0) {
            res++;
            return 2;
        }
        if (l == 1 && r == 1) return 0;
        return 1;
    }
};
```

### [437. 路径总和 III](https://leetcode.cn/problems/path-sum-iii/)

```c++
#include <iostream>
#include <vector>
#include <algorithm>
#include <unordered_map>

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
    int res;

    int pathSum(TreeNode *root, int sum) {
        res = 0;
        // 保存前缀树，key 为前缀和，value 为前缀和出现的次数
        unordered_map<long, int> preSum;
        // 前缀树为 0 的个数至少是一个
        preSum[0] = 1;

        fc(root, sum, 0, preSum);
        return res;
    }

    void fc(TreeNode *root, int target, long sum, unordered_map<long, int> &preSum) {
        if (root == nullptr) return;
        // 从头节点到 x 的累加和
        sum += root->val;
        // 若是存在前缀和为 prefixSum - target 的节点，则该节点到当前节点的路径就是符合题意的
        res += preSum[sum - target];
        // 当前的前缀和的出现次数加一
        preSum[sum]++;
        fc(root->left, target, sum, preSum);
        fc(root->right, target, sum, preSum);
        // 子树都已经遍历完了，从 map 中去掉当前节点的前缀和，使得兄弟结点无法使用当前结点的前缀和
        preSum[sum]--;
    }
};
```
