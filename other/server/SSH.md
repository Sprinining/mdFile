## SSH

SSH（Secure Shell）是一种用于网络通信的加密协议，主要用来实现安全的远程登录和远程命令执行。它由 IETF（互联网工程任务组）标准化，最早由 Tatu Ylönen 于1995年开发。

### SSH 的基本架构

- **客户端（Client）**：运行 SSH 客户端程序（比如 `ssh` 命令行工具、PuTTY 等）发起连接请求。

- **服务器端（Server）**：运行 `sshd` 守护进程，监听默认端口 22，响应客户端请求。

- **网络传输层**：在 TCP/IP 之上建立连接，保证数据可靠传输。

- **加密层**：提供数据加密和完整性保护。

- **认证层**：验证客户端和服务器的身份。

### SSH 工作流程

1. **TCP 连接建立**
    客户端连接服务器的 22 端口（或者自定义端口）。

2. **协议协商**
    双方交换支持的协议版本、加密算法和压缩算法。

3. **密钥交换（Key Exchange）**
    双方通过密钥交换算法（常用 Diffie-Hellman）协商会话密钥，保证后续通信加密。

4. **服务器身份验证**
    客户端验证服务器公钥，防止“中间人攻击”。

5. **用户认证**
    客户端通过密码、公钥、GSSAPI 等方式向服务器认证用户身份。

6. **建立加密通信通道**
    成功认证后，所有数据在对称加密通道中传输。

7. **会话管理**
    客户端和服务器通过这个安全通道交换命令、文件或数据。

### SSH 支持的认证方式

#### 1. 密码认证（Password Authentication）

用户直接输入密码，服务器校验密码正确后允许登录。配置简单，但不够安全，易被暴力破解。

#### 2. 公钥认证（Public Key Authentication）

最推荐的认证方式。

- 用户在客户端生成一对密钥对：私钥（保存在客户端）、公钥（上传到服务器 `~/.ssh/authorized_keys` 文件）。
- 登录时客户端用私钥签名，服务器用公钥验证，完成身份验证。
- 支持免密码登录，安全且方便。

> 公钥认证具体原理
>
> 1. **密钥对生成**
>     用户在本地生成一对密钥：
>    - **私钥（Private Key）**：保存在客户端，必须严格保密。
>    - **公钥（Public Key）**：可以公开，上传到服务器。
> 2. **公钥放到服务器**
>     把公钥内容添加到服务器用户家目录下的文件：`~/.ssh/authorized_keys`
> 3. **认证过程**
>     当客户端尝试连接服务器时：
>    - 服务器发出一个随机数（挑战）。
>    - 客户端用私钥对这个随机数进行数字签名。
>    - 服务器用存储的公钥验证签名是否有效。
>    - 如果验证通过，证明客户端拥有对应私钥，认证成功，无需输入密码。

#### 3. 证书认证（Certificate Authentication）

通过 CA 签发的 SSH 证书验证用户或服务器身份，适合大规模管理。

#### 4. GSSAPI 认证（基于 Kerberos）

主要用于企业环境，通过 Kerberos 协议实现单点登录。

#### 5. Keyboard-Interactive 认证

服务器和客户端通过交互式提示完成认证，支持多因素认证。

### SSH 常用配置文件

#### 服务器端配置文件：`/etc/ssh/sshd_config`

- `Port 22`：监听端口。
- `PermitRootLogin no`：禁止 root 直接登录，提升安全。
- `PasswordAuthentication yes/no`：是否允许密码登录。
- `PubkeyAuthentication yes/no`：是否允许公钥登录。
- `AllowUsers user1 user2`：限制允许登录的用户。
- `MaxAuthTries`：最大认证尝试次数。
- `LoginGraceTime`：登录超时时间。

#### 客户端配置文件：`~/.ssh/config`

用来简化 ssh 命令参数和配置别名，例如：

```bash
Host myserver
    HostName 192.168.1.100
    User myuser
    Port 2222
    IdentityFile ~/.ssh/my_key.pem
```

以后用 `ssh myserver` 就能直接登录。

### SSH 密钥生成和管理

#### 生成密钥对（以 OpenSSH 为例）

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

- `-t rsa` 指定密钥类型（rsa, ed25519 等）。
- `-b 4096` 指定密钥长度，越长越安全。
- 生成的默认文件是 `~/.ssh/id_rsa`（私钥）和 `~/.ssh/id_rsa.pub`（公钥）。

#### 上传公钥到服务器

```bash
ssh-copy-id username@server_ip
```

或者手动将公钥内容追加到服务器的 `~/.ssh/authorized_keys` 文件。

### SSH 高级特性

#### 1. 端口转发（Port Forwarding）

- **本地端口转发**（Local Port Forwarding）：

```bash
ssh -L local_port:target_host:target_port user@ssh_server
```

将本地某端口流量转发到远程目标。

- **远程端口转发**（Remote Port Forwarding）：

```bash
ssh -R remote_port:target_host:target_port user@ssh_server
```

将远程服务器端口转发到本地。

- **动态端口转发**（Dynamic Port Forwarding）：

```bash
ssh -D local_socks_port user@ssh_server
```

充当 SOCKS 代理，实现动态转发。

#### 2. 多重跳板（ProxyJump）

通过跳板机连接目标服务器：

```bash
ssh -J jump_user@jump_host target_user@target_host
```

### SSH 使用场景

- **服务器管理**：远程登录维护服务器。

- **文件传输**：用 SCP、SFTP 传输文件。

- **自动化部署**：CI/CD 工具通过 SSH 执行远程部署脚本。

- **安全隧道**：加密访问内网资源。

- **版本控制**：Git 通过 SSH 认证访问仓库。

### 常见 SSH 安全建议

- 禁止 root 直接登录。

- 关闭密码登录，只允许公钥认证。

- 修改默认端口，避免自动扫描攻击。

- 限制允许登录的用户和 IP。

- 使用强密码和强密钥。

- 定期检查和更新 SSH 版本，防止漏洞。