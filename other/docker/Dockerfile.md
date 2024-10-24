---
title: Dockerfile
date: 2024-10-24 01:07:13 +0800
categories: [other, docker]
tags: [Docker]
description: 镜像制作、Docker 分层存储机制
---
## Dockfile

### [官方文档](https://docs.docker.com/reference/dockerfile/)

| 操作说明                                                     | 描述                               |
| :----------------------------------------------------------- | :--------------------------------- |
| [`ADD`](https://docs.docker.com/reference/dockerfile/#add)   | 添加本地或远程文件和目录。         |
| [`ARG`](https://docs.docker.com/reference/dockerfile/#arg)   | 使用构建时变量。                   |
| [`CMD`](https://docs.docker.com/reference/dockerfile/#cmd)   | 指定默认命令。                     |
| [`COPY`](https://docs.docker.com/reference/dockerfile/#copy) | 复制文件和目录。                   |
| [`ENTRYPOINT`](https://docs.docker.com/reference/dockerfile/#entrypoint) | 指定默认可执行文件。               |
| [`ENV`](https://docs.docker.com/reference/dockerfile/#env)   | 设置环境变量。                     |
| [`EXPOSE`](https://docs.docker.com/reference/dockerfile/#expose) | 描述您的应用程序正在监听哪些端口。 |
| [`FROM`](https://docs.docker.com/reference/dockerfile/#from) | 从基础图像创建一个新的构建阶段。   |
| [`HEALTHCHECK`](https://docs.docker.com/reference/dockerfile/#healthcheck) | 在启动时检查容器的健康状况。       |
| [`LABEL`](https://docs.docker.com/reference/dockerfile/#label) | 向图像添加元数据。                 |
| [`MAINTAINER`](https://docs.docker.com/reference/dockerfile/#maintainer-deprecated) | 指定图像的作者。                   |
| [`ONBUILD`](https://docs.docker.com/reference/dockerfile/#onbuild) | 指定在构建中使用图像时的说明。     |
| [`RUN`](https://docs.docker.com/reference/dockerfile/#run)   | 执行构建命令。                     |
| [`SHELL`](https://docs.docker.com/reference/dockerfile/#shell) | 设置图像的默认外壳。               |
| [`STOPSIGNAL`](https://docs.docker.com/reference/dockerfile/#stopsignal) | 指定退出容器的系统调用信号。       |
| [`USER`](https://docs.docker.com/reference/dockerfile/#user) | 设置用户和组 ID。                  |
| [`VOLUME`](https://docs.docker.com/reference/dockerfile/#volume) | 创建卷挂载。                       |
| [`WORKDIR`](https://docs.docker.com/reference/dockerfile/#workdir) | 改变工作目录。                     |

### 制作镜像

#### Jeklly 的 Dockfile

```dockerfile
# 使用 Jekyll 镜像
FROM jekyll/jekyll:latest

# 创建非 root 用户
RUN useradd -ms /bin/bash jekylluser

# 设置工作目录
WORKDIR /usr/src/app

# 复制 Gemfile 和 Gemfile.lock
COPY Gemfile* ./

# 安装依赖
RUN bundle install

# 复制当前目录内容到容器中
COPY . .

# 切换到非 root 用户
USER jekylluser

# 预览和重建
CMD ["jekyll", "serve", "--host", "0.0.0.0"]
```

#### 构建镜像

```shell
docker build -f Dockfile -t my-chirpy-blog .
```

**`docker build`**：

- 这是 Docker 用来从一个指定的 Dockerfile 构建 Docker 镜像的命令。

**`-f Dockerfile`**：

- `-f` 是指定 Dockerfile 的选项。
- `Dockerfile` 是文件名，它定义了如何构建镜像。默认情况下，Docker 会在当前目录下寻找名为 `Dockerfile` 的文件。可以通过 `-f` 来指定不同位置的 Dockerfile。

**`-t my-chirpy-blog`**：

- `-t` 是用于为镜像指定标签（tag）的选项。
- `my-chirpy-blog` 是构建的镜像的名称（以及它的标签）。

**`.`**（点）：

- 这是上下文目录。它告诉 Docker 使用当前目录（点 `.` 表示当前目录）作为构建的上下文，包含 Dockerfile 以及其他相关的文件。

### Docker 的分层存储机制

Docker 的分层存储机制基于 **联合文件系统（UnionFS）**，这种机制允许将多个文件系统层叠加在一起，形成一个统一的文件系统视图。Docker 镜像和容器都是通过分层的方式来存储和管理文件，从而实现高效的存储和复用。

#### 1. 镜像的分层存储机制

Docker 镜像是由多个只读的层（layers）组成的。每一层代表了一组文件系统的更改，这些层是**不可变的**，且可以被多个容器共享。

##### 镜像的构建过程：

- 每个镜像由多个**只读层**组成，这些层是在构建镜像时生成的。每次镜像构建中的 `RUN`、`ADD` 或 `COPY` 等指令都会生成一个新的层。
- 这些层是按照顺序叠加在一起的，底层为基础镜像，上面的层是该基础镜像上的增量更改。
- 每个层只存储相对于上一层的**差异文件**，例如新添加的文件、修改的文件或删除的文件。这使得镜像的存储变得更高效，因为不同的镜像可以共享相同的基础层。

  使用 `image history` 查看构建历史，输出结果显示了该 Docker 镜像的构建历史，包括每一层的大小、创建时间、创建方式等。

  ```shell
  $ docker image history mcr.microsoft.com/devcontainers/jekyll:2-bullseye
  IMAGE          CREATED       CREATED BY                                      SIZE      COMMENT
  33dc21359970   7 days ago    LABEL devcontainer.metadata=[ {"id":"ghcr.io…   0B        buildkit.dockerfile.v0
  <missing>      7 days ago    USER root                                       0B        buildkit.dockerfile.v0
  。。。。。。
  <missing>      7 weeks ago   /bin/sh -c set -eux;  apt-get update;  apt-g…   28.6MB
  <missing>      7 weeks ago   /bin/sh -c #(nop)  CMD ["bash"]                 0B
  <missing>      7 weeks ago   /bin/sh -c #(nop) ADD file:52a4b3d3a72818125…   124MB
  
  ```

  自己构建的镜像：

  ```shell
  $ docker image history chirpyblog:v1.0
  IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
  97babcf052dc   22 hours ago   /bin/bash                                       272MB     init
  <missing>      7 days ago     LABEL devcontainer.metadata=[ {"id":"ghcr.io…   0B        buildkit.dockerfile.v0
  <missing>      7 days ago     USER root                                       0B        buildkit.dockerfile.v0
  ......
  <missing>      7 weeks ago    /bin/sh -c set -eux;  apt-get update;  apt-g…   28.6MB
  <missing>      7 weeks ago    /bin/sh -c #(nop)  CMD ["bash"]                 0B
  <missing>      7 weeks ago    /bin/sh -c #(nop) ADD file:52a4b3d3a72818125…   124MB
  ```

  对比可见，只有最近的记录不一样。或者通过 `docker inspect` 查看：

  ```shell
  $ docker image inspect mcr.microsoft.com/devcontainers/jekyll:2-bullseye
  "Layers": [
      "sha256:315317d32d9b3cadda3f89b1c2c172b6973b6fe080b131bf8d25252036d8d0f5",
      "sha256:c79ad3cc3bfa8ae6d12b81b2ea69baea53b256436fe27ca6d65afe998683be93",
      ......
      "sha256:94e6af056aaff7fb7111c75aeebe64115c0135e226b0cd6d806b3de974c22553",
      "sha256:2a018faca7c8a73ec0363789ad3ff7af57cdd0a514b2208f76274ffc683707c5"
  ]
  $ docker image inspect chirpyblog:v1.0
  "Layers": [
      "sha256:315317d32d9b3cadda3f89b1c2c172b6973b6fe080b131bf8d25252036d8d0f5",
      "sha256:c79ad3cc3bfa8ae6d12b81b2ea69baea53b256436fe27ca6d65afe998683be93",
     	......
      "sha256:94e6af056aaff7fb7111c75aeebe64115c0135e226b0cd6d806b3de974c22553",
      "sha256:2a018faca7c8a73ec0363789ad3ff7af57cdd0a514b2208f76274ffc683707c5",
      "sha256:321ef2eeb1488e138ab2abd194acce7fdad2f4a4caecbd0621f77cf41fc0e3a7"
  ]
  ```

  可以看出只多出一条记录：`"sha256:321ef2eeb1488e138ab2abd194acce7fdad2f4a4caecbd0621f77cf41fc0e3a7"`

##### 镜像层的特点：

- **只读**：镜像中的每一层都是只读的，不能被修改。
- **共享性**：多个镜像可以共享相同的基础层。例如，不同的应用镜像可能都基于相同的操作系统镜像，因此它们可以共享该层，避免重复存储。
- **增量构建**：因为镜像是分层的，每次构建时只需要重新构建改变的部分，而无需重建整个镜像。

#### 2. **容器的分层存储机制**

容器是基于镜像启动的，容器与镜像的关系也是基于分层存储的，但容器在镜像的基础上增加了一个**可写层**。

##### 容器层的结构：

- **底层镜像层**：容器依赖的镜像层，仍然是只读的。
- **顶层的可写层（容器层）**：当你运行一个容器时，Docker 会在镜像的只读层之上创建一个可写层。容器对文件系统的任何更改（如文件添加、修改或删除）都会记录在这个可写层中。

  使用 `docker ps -s` 可以看见文件大小：

  ```shell
  root@spring:~# docker ps -s
  CONTAINER ID   IMAGE             COMMAND                  CREATED        STATUS        PORTS                                         NAMES     SIZE
  a8f102305aa6   chirpyblog:v1.0   "bundle exec jekyll …"   18 hours ago   Up 15 hours   0.0.0.0:80->4000/tcp, [::]:80->4000/tcp       myblog    87.5MB (virtual 1.99GB)
  586c63be2c6e   chirpyblog:v1.0   "bundle exec jekyll …"   21 hours ago   Up 15 hours   0.0.0.0:4001->4000/tcp, [::]:4001->4000/tcp   myblog2   87.5MB (virtual 1.99GB)
  ```

  其中 `87.5MB` 是指可写层所占用的实际磁盘空间，这个大小是容器启动后，所有容器运行期间产生的数据（如日志、临时文件等）的大小。可写层是在容器的镜像层之上创建的，容器停止或删除后，该层会丢失。

  `virtual 1.99GB` 是容器的虚拟磁盘空间大小，即容器**依赖的镜像**和所有层加在一起的总大小。它包括容器启动所基于的镜像所有层的大小。虽然这些层是只读的，并且可能被多个容器共享，但它们仍然会在此处统计，因为容器依赖这些层来运行。

##### 容器层的特点：

- **可写层**：容器的顶层是可写的，所有对文件系统的更改都会在这个层中进行。当容器运行时，它可以对这个层进行文件写入、修改和删除。
- **写时复制（Copy-on-Write，CoW）**：如果容器需要修改镜像中的某个文件，Docker 会将该文件从只读层复制到容器的可写层，然后在可写层中进行修改。这种机制避免了对共享镜像层的直接更改，保证镜像层的完整性和共享性。
- **一次性**：容器的可写层是临时的，当容器被删除后，所有写入到可写层中的数据都会丢失。如果需要保留数据，通常使用**数据卷（volumes）**或**绑定挂载（bind mounts）**来存储持久化数据。

#### 3. **分层机制的优点**

- **高效性**：由于镜像和容器层是分开的，多个容器可以共享相同的镜像层，减少了磁盘空间的使用。即使构建不同的应用镜像，它们可以共享相同的基础镜像层（如操作系统层），避免重复存储。
- **复用性**：镜像层之间的依赖关系使得复用变得简单。镜像的每个层都可以被不同的镜像或容器复用，从而减少构建时间和存储开销。
- **灵活性**：通过分层机制，可以通过层的增量更新来快速构建新镜像，而不需要从头构建。更新只需修改变更的部分，其他不变的部分可以保持不动。

#### 4. **存储驱动（Storage Drivers）**

Docker 的分层存储机制依赖于不同的存储驱动来实现文件系统的管理。常见的存储驱动包括：

- **Overlay2**：这是目前最常用的存储驱动，支持联合文件系统，能够高效地管理分层结构，适合大多数现代 Linux 内核。
- **AUFS**：以前的默认存储驱动，类似于 Overlay，但支持更多层。由于 AUFS 需要专门的内核支持，逐渐被 Overlay2 取代。
- **btrfs 和 ZFS**：这些是专用的文件系统驱动，具有自己的高级功能，如快照和子卷管理。但由于复杂性和特定的依赖，使用场景较少。

#### 5. **分层存储的缺点**

虽然分层存储机制带来了很多优势，但也有一些潜在的问题：

- **性能问题**：由于可写层使用的是写时复制机制，频繁的文件修改可能导致性能下降，尤其是在修改大量小文件时。
- **层数限制**：一些存储驱动对层的数量有限制（如 AUFS 最多支持 127 层）。虽然这个限制在 Overlay2 中已经大大改善，但在某些复杂场景下，可能会影响镜像的设计。

#### 总结

Docker 的分层存储机制通过联合文件系统将镜像和容器的存储分为多个层次，实现了高效的存储和复用。镜像是由只读的层组成的，而容器在镜像的基础上添加了一个可写层。分层存储不仅节省了磁盘空间，还加快了镜像的构建速度和容器的启动时间，但在某些场景下，分层存储可能会带来一定的性能瓶颈。
