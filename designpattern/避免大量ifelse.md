---
title: 避免大量ifelse
date: 2022-03-21 03:35:24 +0800
categories: [design pattern]
tags: [Design Pattern]
description: 
---
## 枚举

```java
public class Test {
    public static void main(String[] args) {
        System.out.println(judge("ROLE_ROOT_ADMIN"));
    }

    public static String judge(String roleName){
        return RoleEnum.valueOf(roleName).operation();
    }
}

interface RoleOperation {
    String operation();
}

enum RoleEnum implements RoleOperation {
    ROLE_ROOT_ADMIN {
        @Override
        public String operation() {
            return "root";
        }
    },
    ROLE_ORDER_ADMIN {
        @Override
        public String operation() {
            return "order";
        }
    },
    ROLE_NORMAL_ADMIN {
        @Override
        public String operation() {
            return "normal";
        }
    };
}
```

## 工厂模式

```java
import java.util.HashMap;
import java.util.Map;

public class Test {
    public static void main(String[] args) {
        System.out.println(judge("ROLE_ROOT_ADMIN"));
    }

    public static String judge(String roleName) {
        return RoleFactory.getOperation(roleName).operation();
    }
}

interface RoleOperation {
    String operation();
}


class RoleFactory {
    static Map<String, RoleOperation> roleOperationMap = new HashMap<>();

    static {
        roleOperationMap.put("ROLE_ROOT_ADMIN", new RootAdminRole("ROLE_ROOT_ADMIN"));
        roleOperationMap.put("ROLE_ORDER_ADMIN", new RootAdminRole("ROLE_ORDER_ADMIN"));
        roleOperationMap.put("ROLE_NORMAL_ADMIN", new RootAdminRole("ROLE_NORMAL_ADMIN"));
    }

    public static RoleOperation getOperation(String name) {
        return roleOperationMap.get(name);
    }
}

class RootAdminRole implements RoleOperation {
    private final String roleName;

    public RootAdminRole(String roleName) {
        this.roleName = roleName;
    }

    @Override
    public String operation() {
        return roleName + " root permission";
    }
}

class OrderAdminRole implements RoleOperation {
    private final String roleName;

    public OrderAdminRole(String roleName) {
        this.roleName = roleName;
    }

    @Override
    public String operation() {
        return roleName + " order permission";
    }
}

class NormalRole implements RoleOperation {
    private final String roleName;

    public NormalRole(String roleName) {
        this.roleName = roleName;
    }

    @Override
    public String operation() {
        return roleName + " normal permission";
    }
}
```

## 策略模式

```java
package test;

public class Test {
    public static void main(String[] args) {
        System.out.println(judge(new RootAdminRole("ROLE_ROOT_ADMIN")));
    }

    public static String judge(RoleOperation roleOperation) {
        RoleContext roleContext = new RoleContext();
        roleContext.setOperation(roleOperation);
        return roleContext.execute();
    }
}

// 策略
interface RoleOperation {
    // 策略方法
    String operation();
}

// 环境类:持有一个策略类的引用，最终给客户端调用
class RoleContext {
    private RoleOperation roleOperation;

    public void setOperation(RoleOperation roleOperation) {
        this.roleOperation = roleOperation;
    }

    public String execute() {
        return roleOperation.operation();
    }
}

// 具体策略类
class RootAdminRole implements RoleOperation {
    private final String roleName;

    public RootAdminRole(String roleName) {
        this.roleName = roleName;
    }

    @Override
    public String operation() {
        return roleName + " root permission";
    }
}

class OrderAdminRole implements RoleOperation {
    private final String roleName;

    public OrderAdminRole(String roleName) {
        this.roleName = roleName;
    }

    @Override
    public String operation() {
        return roleName + " order permission";
    }
}

class NormalRole implements RoleOperation {
    private final String roleName;

    public NormalRole(String roleName) {
        this.roleName = roleName;
    }

    @Override
    public String operation() {
        return roleName + " normal permission";
    }
}
```

