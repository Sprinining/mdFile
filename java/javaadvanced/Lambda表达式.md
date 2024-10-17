---
title: Lambda表达式
date: 2022-03-21 03:35:24 +0800
categories: [java, java advanced]
tags: [Java, Lambda]
description: 
---
# Lambda表达式

- 函数式接口：只包含==唯一一个抽象方法==的接口
- 可以用lambda表达式创建该接口的对象

```java
class MyLambda {
    // 3.静态内部类
    static class Like2 implements ILike {
        @Override
        public void lambda() {
            System.out.println("I like lambda2");
        }
    }

    public static void main(String[] args) {
        ILike like = new Like();
        like.lambda();

        like = new Like2();
        like.lambda();

        // 4.局部内部类(在方法内部)
        class Like3 implements ILike {
            @Override
            public void lambda() {
                System.out.println("I like lambda3");
            }
        }

        like = new Like3();
        like.lambda();

        // 5.匿名内部类，没有类的名称，必须借助接口或者父类
        like = new ILike() {
            @Override
            public void lambda() {
                System.out.println("I like lambda4");
            }
        };
        like.lambda();

        // 6.lambda
        like = () -> {
            System.out.println("I like lambda5");
        };
        like.lambda();

        // 7.简化lambda 只有一行代码才行，否则就用代码块
        // 若括号内有参数类型，则可以都去掉
        // (int a, int b)  (a,b)
        like = () -> System.out.println("I like lambda6");
        like.lambda();

    }
}

// 1.函数式接口
interface ILike {
    void lambda(); // 接口的函数都是public abstract
}

// 2.实现类
class Like implements ILike {
    @Override
    public void lambda() {
        System.out.println("I like lambda1");
    }
}
```
