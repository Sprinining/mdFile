---
title: 二分查找框架（c语言）
date: 2024-01-11 12:27:30 +0800
categories: [algorithm, summary]
tags: [Algorithm, Algorithm Template, Binary Search]
description: 
---
# 二分法框架

- 区间`[left, size-1]`时，`while (left <= right)`终止条件必为`left = right + 1`
- 但left和right一旦更新后，right右边必然大于或者大于等于target，left左边必然小于或小于等于target(其实就是因为经过了array[mid]与target比较的if分支)

## 区间[left, size-1]

```c
int binarySearch(int *array, int size, int target) {
    // 区间[left, size-1]
    int left = 0;
    int right = size - 1;
    int mid;
    while (left <= right) {
        mid = left + (right - left) / 2;
        if (array[mid] == target)
            return mid;
        else if (array[mid] > target)
            right = mid - 1;    // right更新之后，right右边必然都大于target(不更新不保证大于)
        else if (array[mid] < target)
            left = mid + 1;     // left更新之后，left左边必然都小于target
    }
    // 查找失败时left = right + 1
    return -1;
}
```

## 大于等于（找应该插入的位置，左边界）

```c
// 大于等于（找应该插入的位置，左边界）
int binarySearch1(int *array, int size, int target) {
    int left = 0;
    int right = size - 1;
    int mid;
    while (left <= right) {
        mid = left + (right - left) / 2;
        if (target > array[mid])
            left = mid + 1;     // left更新之后，left左边必然都小于target
        else if (target <= array[mid])
            right = mid - 1;    // right更新之后，right右边必然都大于等于target
    }
    // 循环结束时left = right + 1
    return left;
}
```

## 大于

```c
// 大于
// 循环结束时，left = right + 1，要使right右边都是大于target就必须使left右移时，遇到等于也要右移
int binarySearch2(int *array, int size, int target) {
    int left = 0;
    int right = size - 1;
    int mid;
    while (left <= right) {
        mid = left + (right - left) / 2;
        if (target >= array[mid])
            left = mid + 1;
        else if (target < array[mid])
            right = mid - 1;
    }
    return left;
}
```

## 小于等于(右边界)

```c
// 小于等于(右边界)
int binarySearch3(int *array, int size, int target) {
    int left = 0;
    int right = size - 1;
    int mid;
    while (left <= right) {
        mid = left + (right - left) / 2;
        if (target >= array[mid])  // 即使等于left也右移，这样小于等于的就都在left左边了，循环结束时，right就在left-1的位置
            left = mid + 1;     // left更新之后，left左边必然都小于等于target
        else if (target < array[mid])
            right = mid - 1;    // right更新之后，right右边必然都大于target
    }
    return right;
}
```

## 小于

```c
// 小于
int binarySearch4(int *array, int size, int target) {
    int left = 0;
    int right = size - 1;
    int mid;
    while (left <= right) {
        mid = left + (right - left) / 2;
        if (target > array[mid])
            left = mid + 1;
        else if (target <= array[mid])
            right = mid - 1;
    }
    return right;
}

int main() {
    int a[] = {0, 1, 3, 3, 4, 7, 7, 7, 9, 10};
    printf("%d\n", binarySearch(a, 10, 3)); // 2
    printf("%d\n", binarySearch(a, 10, 11));// -1
    printf("%d\n", binarySearch1(a, 10, 7));// 5
    printf("%d\n", binarySearch2(a, 10, 7));// 8
    printf("%d\n", binarySearch3(a, 10, 7));// 7
    printf("%d\n", binarySearch4(a, 10, 7));// 4
}
```
