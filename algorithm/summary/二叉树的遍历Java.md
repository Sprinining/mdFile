---
title: 二叉树的遍历Java
date: 2023-12-31 11:29:55 +0800
categories: [algorithm, summary]
tags: [Algorithm, Algorithm Template, Binary Tree, Binary Tree Traversal]
description: 
---
# 二叉树的遍历

## 先序

```java
/**
 * Definition for a binary tree node.
 * public class TreeNode {
 *     int val;
 *     TreeNode left;
 *     TreeNode right;
 *     TreeNode() {}
 *     TreeNode(int val) { this.val = val; }
 *     TreeNode(int val, TreeNode left, TreeNode right) {
 *         this.val = val;
 *         this.left = left;
 *         this.right = right;
 *     }
 * }
 */
class Solution {
    static List<Integer> res;

    public List<Integer> preorderTraversal(TreeNode root) {
        res = new ArrayList<>();
        // preorderRecursion(root);
        // preorder(root);
        // preorderMorris(root);
        postorder2(root);
        return res;
    }
    
    // 保存右节点
    public static void postorder2(TreeNode root) {
        if (root == null) return;
        Stack<TreeNode> stack = new Stack<>();
        stack.push(root);
        while (!stack.isEmpty()) {
            TreeNode cur = stack.pop();
            res.add(cur.val);
            if (cur.right != null) stack.push(cur.right);
            if (cur.left != null) stack.push(cur.left);
        }
    }
    
    // Morris
    public static void preorderMorris(TreeNode root) {
        if (root == null) return;

        TreeNode cur = root;

        while (cur != null) {
            if (cur.left != null) {
                // 左子树不空，遍历左子树，找到左子树的最右侧节点
                TreeNode rightMost = cur.left;
                while (rightMost.right != null && rightMost.right != cur) {
                    rightMost = rightMost.right;
                }
                // 最右侧节点的右指针指向null或者cur
                if (rightMost.right == null) {
                    // 有左右孩子的节点第一次被访问
                    res.add(cur.val);
                    // 把最右侧节点的right指向cur
                    rightMost.right = cur;
                    // 访问左子树
                    cur = cur.left;
                } else {
                    // 有左右孩子的节点第二次被访问
                    // 恢复
                    rightMost.right = null;
                    // 遍历右子树
                    cur = cur.right;
                }
            } else {
                // 只有右孩子的节点只会被访问一次
                res.add(cur.val);
                // 遍历右子树
                cur = cur.right;
            }
        }
    }

    // 非递归
    public static void preorder(TreeNode root) {
        Stack<TreeNode> stack = new Stack<>();
        while (!stack.isEmpty() || root != null) {
            while (root != null) {
                res.add(root.val);
                stack.add(root);
                root = root.left;
            }
            root = stack.pop();
            root = root.right;
        }
    }

    // 递归
    public static void preorderRecursion(TreeNode root) {
        if (root == null)
            return;
        res.add(root.val);
        preorderRecursion(root.left);
        preorderRecursion(root.right);
    }
}
```

## 中序

```java
/**
 * Definition for a binary tree node.
 * public class TreeNode {
 *     int val;
 *     TreeNode left;
 *     TreeNode right;
 *     TreeNode() {}
 *     TreeNode(int val) { this.val = val; }
 *     TreeNode(int val, TreeNode left, TreeNode right) {
 *         this.val = val;
 *         this.left = left;
 *         this.right = right;
 *     }
 * }
 */
class Solution {
    static List<Integer> res;

    public List<Integer> inorderTraversal(TreeNode root) {
        res = new ArrayList<>();
//        inorderRecursion(root);
//        inorder(root);
        inorderMorris(root);
        return res;
    }

    public static void inorderMorris(TreeNode root) {
        if (root == null) return;
        TreeNode cur = root;
        while (cur != null) {
            if (cur.left != null) {
                TreeNode rightMost = cur.left;
                while (rightMost.right != null && rightMost.right != cur) {
                    rightMost = rightMost.right;
                }
                if (rightMost.right == null) {
                    rightMost.right = cur;
                    cur = cur.left;
                } else {
                    // 有左右孩子的节点第二次被经过，左子树都遍历完了，访问节点
                    res.add(cur.val);
                    rightMost.right = null;
                    cur = cur.right;
                }
            } else {
                // 只有右孩子的节点只会被经过一次，直接访问
                res.add(cur.val);
                cur = cur.right;
            }
        }
    }

    public static void inorder(TreeNode root) {
        if (root == null) return;
        Stack<TreeNode> stack = new Stack<>();
        while (!stack.isEmpty() || root != null) {
            while (root != null) {
                stack.push(root);
                root = root.left;
            }
            root = stack.pop();
            res.add(root.val);
            root = root.right;
        }
    }

    public static void inorderRecursion(TreeNode root) {
        if (root == null) return;
        inorderRecursion(root.left);
        res.add(root.val);
        inorderRecursion(root.right);
    }
}
```

## 后序

```java
/**
 * Definition for a binary tree node.
 * public class TreeNode {
 *     int val;
 *     TreeNode left;
 *     TreeNode right;
 *     TreeNode() {}
 *     TreeNode(int val) { this.val = val; }
 *     TreeNode(int val, TreeNode left, TreeNode right) {
 *         this.val = val;
 *         this.left = left;
 *         this.right = right;
 *     }
 * }
 */
public class Solution {
    static List<Integer> res;

    public List<Integer> postorderTraversal(TreeNode root) {
        res = new ArrayList<>();
//        postorderRecursion(root);
//        postorder(root);
        postorderMorris(root);
        return res;
    }

    public static void postorderMorris(TreeNode root) {
        TreeNode cur = root;
        while (cur != null) {
            if (cur.left != null) {
                TreeNode rightMost = cur.left;
                while (rightMost.right != null && rightMost.right != cur) {
                    rightMost = rightMost.right;
                }
                if (rightMost.right == null) {
                    rightMost.right = cur;
                    cur = cur.left;
                } else {
                    rightMost.right = null;
                    // 一个节点被第二次经过的时候，自底向上访问左子树的所有的右节点
                    visitReversedRightTree(cur.left);
                    cur = cur.right;
                }
            } else {
                cur = cur.right;
            }
        }
        // 再遍历一次
        visitReversedRightTree(root);
    }

    // 自底向上访问右节点（访问反转后的右节点）
    public static void visitReversedRightTree(TreeNode root) {
        // 反转右子树
        TreeNode reversed = reverseRightTree(root);
        TreeNode cur = reversed;
        while (cur != null) {
            res.add(cur.val);
            cur = cur.right;
        }
        // 反转回去
        reverseRightTree(reversed);
    }

    // 把右子树反转
    public static TreeNode reverseRightTree(TreeNode root) {
        TreeNode pre = null;
        TreeNode cur = root;
        while (cur != null) {
            TreeNode nextRight = cur.right;
            cur.right = pre;
            pre = cur;
            cur = nextRight;
        }
        return pre;
    }

    public static void postorder(TreeNode root) {
        Stack<TreeNode> stack = new Stack<>();
        TreeNode pre = null;
        while (!stack.isEmpty() || root != null) {
            while (root != null) {
                stack.push(root);
                root = root.left;
            }

            root = stack.pop();
            if (root.right == null || root.right == pre) {
                // 没有右子树或者右子树已经被访问过了
                res.add(root.val);
                // pre始终指向上一个被访问过的节点
                pre = root;
                root = null;
            } else {
                // 访问右子树前，先把当前节点重新入栈
                stack.push(root);
                root = root.right;
            }
        }
    }

    public static void postorderRecursion(TreeNode root) {
        if (root == null) return;
        postorderRecursion(root.left);
        postorderRecursion(root.right);
        res.add(root.val);
    }
}
```

## 层序



## 二叉树深度

```java
public class Solution {
    public int maxDepth(TreeNode root) {
        // 递归
/*        if (root == null) return 0;
        return Math.max(maxDepth(root.left), maxDepth(root.right)) + 1;*/

        // 层序遍历累计层数
        if (root == null) return 0;
        int res = 0;
        Queue<TreeNode> queue = new LinkedList<>();
        queue.add(root);

        while (!queue.isEmpty()) {
            res++;
            int size = queue.size();
            for (int i = 0; i < size; i++) {
                TreeNode temp = queue.remove();
                if (temp.left != null) queue.add(temp.left);
                if (temp.right != null) queue.add(temp.right);
            }
        }
        return res;
    }
}
```

## 层序遍历记录每一层

```java
public class Solution {
    public static List<List<Integer>> levelOrder(TreeNode root) {
        List<List<Integer>> res = new ArrayList<>();
        if (root == null) return res;

        Queue<TreeNode> queue = new LinkedList<>();
        queue.add(root);

        while (!queue.isEmpty()) {
            List<Integer> tempList = new ArrayList<>();
            int size = queue.size();
            for (int i = 0; i < size; i++) {
                TreeNode node = queue.remove();
                tempList.add(node.val);
                if (node.left != null) queue.add(node.left);
                if (node.right != null) queue.add(node.right);
            }
            res.add(tempList);
        }
        return res;
    }
}
```

## 最近公共祖先LCA

```java
class Solution {
//    public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
//        if (root == null) return null;
//        if (root == p || root == q) return root;
//        TreeNode left = lowestCommonAncestor(root.left, p, q);
//        TreeNode right = lowestCommonAncestor(root.right, p, q);
//        if (left == null)
//            return right;
//        else if (right == null)
//            return left;
//        else
//            return root;
//    }

    static Map<Integer, TreeNode> map;
    static Set<Integer> visited;

    public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
        // 存储子节点的值和父节点
        map = new HashMap<>();
        visited = new HashSet<>();
        // 保存关系
        dfs(root);

        while (p != null) {
            visited.add(p.val);
            // 获取父节点
            p = map.get(p.val);
        }

        while (q != null) {
            // 第一个遇到的已经被访问过的节点就是LCA
            if (visited.contains(q.val))
                return q;
            q = map.get(q.val);
        }
        return null;
    }

    public static void dfs(TreeNode root) {
        if (root.left != null) {
            map.put(root.left.val, root);
            dfs(root.left);
        }
        if (root.right != null) {
            map.put(root.right.val, root);
            dfs(root.right);
        }
    }
}
```
