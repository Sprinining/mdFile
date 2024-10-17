---
title: Serializable
date: 2024-07-31 05:03:43 +0800
categories: [java, io]
tags: [Java, IO, Serializable]
description: 
---
```java
class CSer {
    private String name;
    private int age;

    public CSer() {
    }

    public CSer(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
    
    @Override
    public String toString() {
        return "CSer{" +
                "name='" + name + '\'' +
                ", age=" + age +
                '}';
    }
}

public class Main {
    public static void main(String[] args) {
        // 初始化
        CSer player = new CSer();
        player.setName("niko");
        player.setAge(18);
        System.out.println(player);

        // 把对象写到文件中
        try (ObjectOutputStream oos = new ObjectOutputStream(Files.newOutputStream(Paths.get("major")));) {
            oos.writeObject(player);
        } catch (IOException e) {
            e.printStackTrace();
        }

        // 从文件中读出对象
        try (ObjectInputStream ois = new ObjectInputStream(Files.newInputStream(new File("major").toPath()));) {
            CSer player1 = (CSer) ois.readObject();
            System.out.println(player1);
        } catch (IOException | ClassNotFoundException e) {
            e.printStackTrace();
        }
    }
}
```

由于 `CSer` 没有实现 `Serializbale` 接口，所以在运行测试类的时候会抛出异常，堆栈信息如下：

```java
java.io.NotSerializableException: org.example.CSer
	at java.io.ObjectOutputStream.writeObject0(ObjectOutputStream.java:1184)
	at java.io.ObjectOutputStream.writeObject(ObjectOutputStream.java:348)
	at org.example.Main.main(Main.java:46)
```

 `ObjectOutputStream` 的 `writeObject0()` 方法。其部分源码如下：

```java
// remaining cases
// 判断对象类型，调用对应方法进行序列化
if (obj instanceof String) {
    writeString((String) obj, unshared);
} else if (cl.isArray()) {
    writeArray(obj, desc, unshared);
} else if (obj instanceof Enum) {
    writeEnum((Enum<?>) obj, desc, unshared);
} else if (obj instanceof Serializable) {
    writeOrdinaryObject(obj, desc, unshared);
} else {
    // 如果对象不能被序列化，则抛出 NotSerializableException 异常
    if (extendedDebugInfo) {
        throw new NotSerializableException(
            cl.getName() + "\n" + debugInfoStack.toString());
    } else {
        throw new NotSerializableException(cl.getName());
    }
}
```

`ObjectOutputStream` 在序列化的时候，会判断被序列化的对象是哪一种类型，字符串？数组？枚举？还是 `Serializable`，如果全都不是的话，抛出 `NotSerializableException`。

## Seralizable

`CSer` 实现了 `Serializable` 接口，就可以序列化和反序列化了

```java
class CSer implements Serializable {
```

以 `ObjectOutputStream` 为例，它在序列化的时候会依次调用 `writeObject()`→`writeObject0()`→`writeOrdinaryObject()`→`writeSerialData()`→`invokeWriteObject()`→`defaultWriteFields()`。

```java
private void defaultWriteFields(Object obj, ObjectStreamClass desc) throws IOException {
    // 获取对象的类，并检查是否可以进行默认的序列化
    Class<?> cl = desc.forClass();
    desc.checkDefaultSerialize();

    // 获取对象的基本类型字段的数量，以及这些字段的值
    int primDataSize = desc.getPrimDataSize();
    desc.getPrimFieldValues(obj, primVals);
    // 将基本类型字段的值写入输出流
    bout.write(primVals, 0, primDataSize, false);

    // 获取对象的非基本类型字段的值
    ObjectStreamField[] fields = desc.getFields(false);
    Object[] objVals = new Object[desc.getNumObjFields()];
    int numPrimFields = fields.length - objVals.length;
    desc.getObjFieldValues(obj, objVals);
    // 循环写入对象的非基本类型字段的值
    for (int i = 0; i < objVals.length; i++) {
        // 调用 writeObject0 方法将对象的非基本类型字段序列化写入输出流
        try {
            writeObject0(objVals[i], fields[numPrimFields + i].isUnshared());
        }
        // 如果在写入过程中出现异常，则将异常包装成 IOException 抛出
        catch (IOException ex) {
            if (abortIOException == null) {
                abortIOException = ex;
            }
        }
    }
}
```

以 `ObjectInputStream` 为例，它在反序列化的时候会依次调用 `readObject()`→`readObject0()`→`readOrdinaryObject()`→`readSerialData()`→`defaultReadFields()`。

```java
private void defaultReadFields(Object obj, ObjectStreamClass desc) throws IOException {
    // 获取对象的类，并检查对象是否属于该类
    Class<?> cl = desc.forClass();
    if (cl != null && obj != null && !cl.isInstance(obj)) {
        throw new ClassCastException();
    }

    // 获取对象的基本类型字段的数量和值
    int primDataSize = desc.getPrimDataSize();
    if (primVals == null || primVals.length < primDataSize) {
        primVals = new byte[primDataSize];
    }
    // 从输入流中读取基本类型字段的值，并存储在 primVals 数组中
    bin.readFully(primVals, 0, primDataSize, false);
    if (obj != null) {
        // 将 primVals 数组中的基本类型字段的值设置到对象的相应字段中
        desc.setPrimFieldValues(obj, primVals);
    }

    // 获取对象的非基本类型字段的数量和值
    int objHandle = passHandle;
    ObjectStreamField[] fields = desc.getFields(false);
    Object[] objVals = new Object[desc.getNumObjFields()];
    int numPrimFields = fields.length - objVals.length;
    // 循环读取对象的非基本类型字段的值
    for (int i = 0; i < objVals.length; i++) {
        // 调用 readObject0 方法读取对象的非基本类型字段的值
        ObjectStreamField f = fields[numPrimFields + i];
        objVals[i] = readObject0(Object.class, f.isUnshared());
        // 如果该字段是一个引用字段，则将其标记为依赖该对象
        if (f.getField() != null) {
            handles.markDependency(objHandle, passHandle);
        }
    }
    if (obj != null) {
        // 将 objVals 数组中的非基本类型字段的值设置到对象的相应字段中
        desc.setObjFieldValues(obj, objVals);
    }
    passHandle = objHandle;
}
```

`Serializable` 接口之所以定义为空，是因为它只起到了一个标识的作用，告诉程序实现了它的对象是可以被序列化的，但真正序列化和反序列化的操作并不需要它来完成。

`static `和 `transient `修饰的字段是==不会被序列化==。

`ObjectStreamClass` 部分源码：

```java
private static ObjectStreamField[] getDefaultSerialFields(Class<?> cl) {
    // 获取该类中声明的所有字段
    Field[] clFields = cl.getDeclaredFields();
    ArrayList<ObjectStreamField> list = new ArrayList<>();
    int mask = Modifier.STATIC | Modifier.TRANSIENT;

    // 遍历所有字段，将非 static 和 transient 的字段添加到 list 中
    for (int i = 0; i < clFields.length; i++) {
        Field field = clFields[i];
        int mods = field.getModifiers();
        if ((mods & mask) == 0) {
            // 根据字段名、字段类型和字段是否可序列化创建一个 ObjectStreamField 对象
            ObjectStreamField osf = new ObjectStreamField(field.getName(), field.getType(), !Serializable.class.isAssignableFrom(cl));
            list.add(osf);
        }
    }

    int size = list.size();
    // 如果 list 为空，则返回一个空的 ObjectStreamField 数组，否则将 list 转换为 ObjectStreamField 数组并返回
    return (size == 0) ? NO_FIELDS :
        list.toArray(new ObjectStreamField[size]);
}
```

## Externalizable

除了 `Serializable` 之外，Java 还提供了一个序列化接口 `Externalizable`。

实现 `Externalizable` 接口的 `CSer` 类和实现 `Serializable` 接口的 `CSer` 类有一些不同：

1）新增了一个无参的构造方法。

使用 `Externalizable` 进行反序列化的时候，会调用被序列化类的无参构造方法去创建一个新的对象，然后再将被保存对象的字段值复制过去。否则的话，会抛出异常 `InvalidClassException`

2）新增了两个方法 `writeExternal()` 和 `readExternal()`，实现 `Externalizable` 接口所必须的。如果不重写具体的 `writeExternal()` 和 `readExternal()` 方法，反序列化后得到的对象字段都变成了默认值。

重写两个方法：

```java
@Override
public void writeExternal(ObjectOutput out) throws IOException {
	out.writeObject(name);
	out.writeInt(age);
}

@Override
public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
	name = (String) in.readObject();
	age = in.readInt();
}
```

Externalizable 和 Serializable 都是用于实现 Java 对象的序列化和反序列化的接口，但是它们有以下区别：

①、Serializable 是 Java 标准库提供的接口，而 Externalizable 是 Serializable 的子接口；

②、Serializable 接口不需要实现任何方法，只需要将需要序列化的类标记为 Serializable 即可，而 Externalizable 接口需要实现 writeExternal 和 readExternal 两个方法；

③、Externalizable 接口提供了更高的序列化控制能力，可以在序列化和反序列化过程中对对象进行自定义的处理，如对一些敏感信息进行加密和解密。

transient 关键字用于修饰类的成员变量，在序列化对象时，被修饰的成员变量不会被序列化和保存到文件中。其作用是告诉 JVM 在序列化对象时不需要将该变量的值持久化，这样可以避免一些安全或者性能问题。但是，transient 修饰的成员变量在反序列化时会被初始化为其默认值（如 int 类型会被初始化为 0，引用类型会被初始化为 null），因此需要在程序中进行适当的处理。

transient 关键字和 static 关键字都可以用来修饰类的成员变量。其中，transient 关键字表示该成员变量不参与序列化和反序列化，而 static 关键字表示该成员变量是属于类的，不属于对象的，因此不需要序列化和反序列化。

在 Serializable 和 Externalizable 接口中，transient 关键字的表现也不同，在 Serializable 中表示该成员变量不参与序列化和反序列化，在 Externalizable 中不起作用，因为 Externalizable 接口需要实现 readExternal 和 writeExternal 方法，需要手动完成序列化和反序列化的过程。

## serialVersionUID 

`serialVersionUID` 被称为序列化 ID，它是决定 Java 对象能否反序列化成功的重要因子。在反序列化时，Java 虚拟机会把字节流中的 `serialVersionUID` 与被序列化类中的 `serialVersionUID` 进行比较，如果相同则可以进行反序列化，否则就会抛出序列化版本不一致的异常。

1）添加一个默认版本的序列化 ID：

```java
private static final long serialVersionUID = 1L。
```

2）添加一个随机生成的不重复的序列化 ID。

```java
private static final long serialVersionUID = -2095916884810199532L;
```

3）添加 `@SuppressWarnings` 注解。该注解会为被序列化类自动生成一个随机的序列化 ID。

```java
@SuppressWarnings("serial")
```

