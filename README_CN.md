OpenAFP — 让 AI Agent 自由互联

无需公网 IP，内网 Agent 也能被外部发现和调用。

OpenAFP 是一个专门为内网 Agent 互联设计的连接层。无需公网 IP，无需端口映射 —— 它让两个都在内网的设备直接建立连接、互相通信，就像它们在同一个局域网里。

![内网互联拓扑](https://openafp.net/topology.svg)

---

📦 一键安装

Linux / macOS

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://install.openafp.net/install.sh | bash
```

Windows（管理员 PowerShell）

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
irm https://install.openafp.net/install.ps1 | iex
```

安装完成后，网关会自动启动，并连接 OpenAFP 公共节点网络（用于节点发现与连接建立）。

等待约 30 秒后，先测试节点是否正常运行：

```bash
curl http://localhost:51888/health
```

如果返回 {"status":"ok"}，说明你的节点已经成功启动。

想进一步测试跨节点调用？

```bash
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"capability":"system/hostname"},"id":1}'
```

你将看到网络中其他节点的 hostname —— 说明你的 Agent 已成功加入 OpenAFP 网络。

💡 云服务器用户注意：部分云平台（如阿里云）可能对一键安装脚本触发安全告警，这是正常的安全防护机制。如遇拦截，请将 install.openafp.net 加入白名单，或手动下载 Release 二进制。

---

🚀 你可以用它做什么？

场景一：多个 AI Agent 自动连接与协作

家里、公司、云服务器上的 Agent 会自动发现彼此，并协同完成任务。例如：节点 A 拉取数据 → 节点 B 分析 → 节点 C 推送结果。

无需公网 IP，无需手工配置端口。节点之间会自动保持长期稳定连接，即使位于不同运营商、不同国家、不同网络环境。

适用于：

- 多节点 AI Workflow
- 分布式 Agent 协作
- 家庭 / 公司 / 云端混合网络

✅ 已验证（多地域异构节点全网贯通，长期稳定运行）

---

场景二：移动热点 / 5G / 临时网络环境下的设备互联

即使在移动热点、运营商网络、临时办公网络等复杂环境下运行 Agent，也能与家里的设备、云服务器自动建立连接。

适用于：

- 5G / 移动热点环境
- 临时办公网络
- 家庭 NAS / 小主机远程互联

✅ 已验证（复杂网络环境下稳定互联）

---

场景三：让公司内网工具被家庭 AI 调用（规划中）

将 MCP Server、内部 API、数据库工具等部署在公司内网，家里的 AI Agent 或 Claude Desktop 可通过 OpenAFP 直接访问。

适用于：

- 公司内网工具访问
- 家庭办公环境
- AI 工具远程协作

🚧 规划中（MCP over OpenAFP Prototype）

---

🔐 安全与设计原则

OpenAFP 默认采用"最小能力暴露"原则。

当前公开能力经过严格限制：

- 不开放任意 shell 执行
- 不开放系统级远程控制
- 文件读取默认限制路径与流量大小
- 所有能力需显式注册
- 默认仅建立节点连接，不自动共享系统权限

目标是：在真实互联网环境中，优先保证安全、稳定与默认成功。

---

📢 我们希望了解真实使用场景

如果你正在解决：

- 家里设备无法被外部访问
- AI Agent 跨地域协作困难
- 多节点自动连接问题
- 家庭 / 公司 / 云端设备互联
- 或任何"Agent 互联"相关问题

欢迎提交 Issue 分享你的真实场景。你的反馈将直接影响 OpenAFP 后续版本的优先方向。

---

🧭 资源链接

- [实时网络状态](https://status.openafp.net)
- [完整能力列表](docs/CAPABILITIES.md)
- [协议规范（实验草案）](protocol/SPEC.md)
- [常见问题与网络踩坑](docs/NETWORKING_PITFALLS.md)

---

🤝 参与贡献

OpenAFP 当前仍处于实验阶段，欢迎：

- 报告 Bug
- 提交真实使用反馈
- 提出能力与协议建议
- 参与测试与文档完善

反馈与讨论：

- [GitHub Discussions（论坛）](https://github.com/openafp-net/openafp/discussions) – 技术讨论、路线图、场景分享（面向海外用户）
- [Gitee Issues（讨论区）](https://gitee.com/openafp/openafp-public/issues) – 提问、分享使用场景（国内用户推荐）
- GitHub Issues
- Gitee Issues
- Discord（规划中）
- 微信联系：2727989（添加请备注 OpenAFP）

---

📄 License

Apache 2.0 — 详见 [LICENSE](LICENSE)

---

OpenAFP — 让 AI Agent 自由互联。
