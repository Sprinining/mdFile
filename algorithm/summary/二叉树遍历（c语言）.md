---
title: 二叉树遍历（c语言）
date: 2024-01-11 12:23:30 +0800
categories: [algorithm, summary]
tags: [Algorithm, Algorithm Template, Binary Tree, Binary Tree Traversal]
description: 
---
# 二叉树遍历

## 先序

### 递归

```c
int *res;

void preorder(struct TreeNode *root, int *returnSize) {
    if (root == NULL) return;
    // 根左右
    res[(*returnSize)++] = root->val;
    preorder(root->left, returnSize);
    preorder(root->right, returnSize);
}

int *preorderTraversal(struct TreeNode *root, int *returnSize) {
    res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    preorder(root, returnSize);
    return res;
}
```

### 迭代

```c
int *preorderTraversal(struct TreeNode *root, int *returnSize) {
    int *res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    struct TreeNode *stack[100];
    int top = 0;

    while (top != 0 || root != NULL) {
        // 左子树入栈
        while (root != NULL) {
            // 访问
            res[(*returnSize)++] = root->val;
            stack[top++] = root;
            root = root->left;
        }

        root = stack[--top];
        root = root->right;
    }

    return res;
}
```

### 迭代（右子树先入栈）

```c
int *preorderTraversal(struct TreeNode *root, int *returnSize) {
    int *res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    if (root == NULL) return res;
    struct TreeNode *stack[100];
    int top = 0;
    stack[top++] = root;

    while (top != 0) {
        root = stack[--top];
        res[(*returnSize)++] = root->val;
        // 右子树先入栈
        if (root->right != NULL) stack[top++] = root->right;
        if (root->left != NULL) stack[top++] = root->left;
    }
    return res;
}
```

### 右左根访问，再反转序列

```c
int *res;

void dfs(struct TreeNode *root, int *returnSize) {
    if (root == NULL) return;
    // 按右左根的顺序访问，再把序列反过来
    dfs(root->right, returnSize);
    dfs(root->left, returnSize);
    res[(*returnSize)++] = root->val;
}

int *preorderTraversal(struct TreeNode *root, int *returnSize) {
    res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    if (root == NULL) return res;
    dfs(root, returnSize);

    // 序列反过来
    int left = 0, right = *returnSize - 1;
    while (left < right) {
        int temp = res[left];
        res[left] = res[right];
        res[right] = temp;
        left++;
        right--;
    }

    return res;
}
```

### Morris

```C
int *res;

// Morris
void preorderMorris(struct TreeNode *root, int *returnSize) {
    if (root == NULL) return;

    struct TreeNode *cur = root;

    while (cur != NULL) {
        if (cur->left != NULL) {
            // 左子树不空，遍历左子树，找到左子树的最右侧节点
            struct TreeNode *rightMost = cur->left;
            while (rightMost->right != NULL && rightMost->right != cur) {
                rightMost = rightMost->right;
            }
            // 最右侧节点的右指针指向NULL或者cur
            if (rightMost->right == NULL) {
                // 有左右孩子的节点第一次被访问
                res[(*returnSize)++] = cur->val;
                // 把最右侧节点的right指向cur
                rightMost->right = cur;
                // 访问左子树
                cur = cur->left;
            } else {
                // 有左右孩子的节点第二次被访问
                // 恢复
                rightMost->right = NULL;
                // 遍历右子树
                cur = cur->right;
            }
        } else {
            // 只有右孩子的节点只会被访问一次
            res[(*returnSize)++] = cur->val;
            // 遍历右子树
            cur = cur->right;
        }
    }
}

int *preorderTraversal(struct TreeNode *root, int *returnSize) {
    res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    if (root == NULL) return res;
    preorderMorris(root, returnSize);
    return res;
}
```

## 中序

### 递归

```c
int *res;

void inorder(struct TreeNode *root, int *returnSize) {
    if (root == NULL) return;
    // 左根右
    inorder(root->left, returnSize);
    res[(*returnSize)++] = root->val;
    inorder(root->right, returnSize);
}

int *inorderTraversal(struct TreeNode *root, int *returnSize) {
    res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    inorder(root, returnSize);
    return res;
}
```

### 迭代

```c
int *inorderTraversal(struct TreeNode *root, int *returnSize) {
    int *res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    struct TreeNode *stack[100];
    int top = 0;

    while (top != 0 || root != NULL) {
        // 左子树入栈
        while (root != NULL) {
            stack[top++] = root;
            root = root->left;
        }

        root = stack[--top];
        // 访问
        res[(*returnSize)++] = root->val;
        root = root->right;
    }

    return res;
}
```

### Morris

```c
int *res;

void inorderMorris(struct TreeNode *root, int *returnSize) {
    if (root == NULL) return;
    struct TreeNode *cur = root;
    while (cur != NULL) {
        if (cur->left != NULL) {
            struct TreeNode *rightMost = cur->left;
            while (rightMost->right != NULL && rightMost->right != cur) {
                rightMost = rightMost->right;
            }
            if (rightMost->right == NULL) {
                rightMost->right = cur;
                cur = cur->left;
            } else {
                // 有左右孩子的节点第二次被经过，左子树都遍历完了，访问节点
                res[(*returnSize)++] = cur->val;
                rightMost->right = NULL;
                cur = cur->right;
            }
        } else {
            // 只有右孩子的节点只会被经过一次，直接访问
            res[(*returnSize)++] = cur->val;
            cur = cur->right;
        }
    }
}

int *inorderTraversal(struct TreeNode *root, int *returnSize) {
    res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    if (root == NULL) return res;
    inorderMorris(root, returnSize);
    return res;
}
```

## 后序

### 递归

```c
int *res;

void postOrder(struct TreeNode *root, int *returnSize) {
    if (root == NULL) return;
    // 左右根
    postOrder(root->left, returnSize);
    postOrder(root->right, returnSize);
    res[(*returnSize)++] = root->val;
}

int *postorderTraversal(struct TreeNode *root, int *returnSize) {
    res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    postOrder(root, returnSize);
    return res;
}
```

### 迭代

```c
int *postorderTraversal(struct TreeNode *root, int *returnSize) {
    int *res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    struct TreeNode *stack[100];
    int top = 0;
    // 记录上个访问的节点
    struct TreeNode *pre = NULL;

    while (top != 0 || root != NULL) {
        // 左子树入栈
        while (root != NULL) {
            stack[top++] = root;
            root = root->left;
        }

        root = stack[--top];
        if (root->right == NULL || root->right == pre) {
            // 右子树为空或者已经访问完了，可以访问这个节点了
            res[(*returnSize)++] = root->val;
            pre = root;
            root = NULL;
        } else {
            // 遍历右子树
            // 先把当前节点再次压栈
            stack[top++] = root;
            root = root->right;
        }
    }

    return res;
}
```

### Morris

```c
int *res;

// 把右子树反转
struct TreeNode *reverseRightTree(struct TreeNode *root) {
    struct TreeNode *pre = NULL;
    struct TreeNode *cur = root;
    while (cur != NULL) {
        struct TreeNode *nextRight = cur->right;
        cur->right = pre;
        pre = cur;
        cur = nextRight;
    }
    return pre;
}

// 自底向上访问右节点（访问反转后的右节点）
void visitReversedRightTree(struct TreeNode *root, int *returnSize) {
    // 反转右子树
    struct TreeNode *reversed = reverseRightTree(root);
    struct TreeNode *cur = reversed;
    while (cur != NULL) {
        res[(*returnSize)++] = cur->val;
        cur = cur->right;
    }
    // 反转回去
    reverseRightTree(reversed);
}

void postorderMorris(struct TreeNode *root, int *returnSize) {
    struct TreeNode *cur = root;
    while (cur != NULL) {
        if (cur->left != NULL) {
            struct TreeNode *rightMost = cur->left;
            while (rightMost->right != NULL && rightMost->right != cur) {
                rightMost = rightMost->right;
            }
            if (rightMost->right == NULL) {
                rightMost->right = cur;
                cur = cur->left;
            } else {
                rightMost->right = NULL;
                // 一个节点被第二次经过的时候，自底向上访问左子树的所有的右节点
                visitReversedRightTree(cur->left, returnSize);
                cur = cur->right;
            }
        } else {
            cur = cur->right;
        }
    }
    // 再遍历一次
    visitReversedRightTree(root, returnSize);
}


int *postorderTraversal(struct TreeNode *root, int *returnSize) {
    res = (int *) malloc(sizeof(int) * 100);
    *returnSize = 0;
    if (root == NULL) return res;
    postorderMorris(root, returnSize);
    return res;
}
```


## 层序

```c
int **levelOrder(struct TreeNode *root, int *returnSize, int **returnColumnSizes) {
    // 一层最多元素个数
    const int size = 1002;
    // 最多层数
    const int leverMax = 2000;

    // 返回的二维数组，第一维表示所在层，第二维表示该层的所有元素
    int **res = (int **) malloc(sizeof(int *) * leverMax);
    // 一维的维度（多少层）
    *returnSize = 0;
    // 每个二维的维度（每层多少元素）
    *returnColumnSizes = (int *) malloc(sizeof(int) * leverMax);
    if (root == NULL) return res;


    // 循环队列
    struct TreeNode *queue[size];
    int lever = 0;
    // 保存每层元素个数，下标就是所在层，从0开始
    int *columnSize = (int *) calloc(leverMax, sizeof(int));
    int front = 0, rear = 0;
    queue[rear++] = root;

    while (front != rear) {
        // 当前层元素数
        int count = (rear - front + size) % size;
        res[lever] = (int *) malloc(sizeof(int) * count);
        int temp = 0;
        while (count-- > 0) {
            root = queue[(front++) % size];
            // 记录当前层的元素
            res[lever][temp++] = root->val;
            // 当前层元素总数加一
            columnSize[lever]++;
            if (root->left != NULL) queue[(rear++) % size] = root->left;
            if (root->right != NULL) queue[(rear++) % size] = root->right;
        }
        // 加一层
        lever++;
    }

    *returnSize = lever;
    for (int i = 0; i < lever; ++i) 
        (*returnColumnSizes)[i] = columnSize[i];
    return res;
}
```
