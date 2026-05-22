[English](README.md) | 中文

# OpenAFP

面向真实网络 NAT 环境的实验性 Agent 覆盖网络。

## 安装

**Linux/macOS**
```bash
curl --proto '=https' --tlsv1.2 -fsSL https://install.openafp.net/install.sh | bash
```

**Windows（管理员权限运行 PowerShell）**
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
irm https://install.openafp.net/install.ps1 | iex
```

> **💡 云服务器用户注意事项**
>
> 在阿里云等云服务器上执行上述命令时，安全系统可能产生告警（因为自动化进程执行了远程脚本下载）。这是正常的安全防护机制。
>
> **解决方案：**
> - **方案一（推荐）**：在云安全中心将 `install.openafp.net` 加入白名单
> - **方案二**：手动下载二进制安装（手动安装指南，即将推出）
>
> 个人电脑用户不会遇到此问题，请放心使用。

## 快速开始

安装后等待 30 秒，让 DHT 网络同步，然后执行：

```bash
curl http://localhost:51888/health
curl -X POST http://localhost:51888/afp -d '{"jsonrpc":"2.0","method":"invoke","params":{"capability":"system/hostname"},"id":1}'
```

## 文档

- [协议规范](protocol/SPEC.md)
- [API 参考](docs/API.md)
- [能力列表](docs/CAPABILITIES.md)
- [网络踩坑记录](docs/NETWORKING_PITFALLS.md)

## 许可证

Apache 2.0 — 详见 [LICENSE](LICENSE)
