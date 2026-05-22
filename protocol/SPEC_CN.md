# OpenAFP Protocol（实验性草案）

> ⚠️ Experimental — OpenAFP 当前为实验性 Agent P2P 网络项目。  
> 本协议文档用于记录当前实验中的消息结构、网络行为与工程约束，可能随项目演化发生变化。  
> 当前重点：真实网络环境中的 Agent 发现、Relay、中继穿透、跨 NAT 调用与能力协作。

---

# 1. 设计目标

OpenAFP 不尝试定义"行业标准"。  
当前更关注：

- Agent 在复杂网络中的互联问题
- NAT / Relay / DHT 场景验证
- 节点发现与能力调用
- 最小化消息结构
- 真实公网环境稳定性

协议设计强调：

- 极简
- 可调试
- 易实现
- 适合真实网络实验

---

# 2. 当前协议定位

当前协议更适合作为：

- Experimental Message Format
- P2P Agent Invocation Format
- Relay-aware Agent Messaging
- libp2p Agent Networking 实验层

而不是：

- 行业标准
- 通用 Agent 基础设施
- 生产级互操作协议

---

# 3. 消息结构（当前实验版本）

当前实验版本使用 8 字段轻量消息结构：

```json
{
  "protocol_version": "0.1",
  "type": "task.request",
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": 1736000000000,
  "from": "peer_a",
  "to": "peer_b",
  "payload": {},
  "extensions": {}
}
```

字段说明：

| 字段 | 必填 | 说明 |
|------|------|------|
| protocol_version | ✅ | 当前协议版本 |
| type | ✅ | 消息类型 |
| id | ✅ | 消息唯一 ID |
| timestamp | ✅ | 毫秒时间戳 |
| from | ✅ | 发送节点 |
| to | ❌ | 目标节点（为空表示广播） |
| payload | ✅ | 消息内容 |
| extensions | ❌ | 扩展字段 |

---

# 4. 当前消息类型

当前实验版本仅保留最小消息集合：

| 类型 | 用途 |
|------|------|
| invoke | 调用目标节点上的能力 |
| register | 注册 Agent 及其能力 |
| discover | 查询节点的身份和支持的能力 |
| get_status | 获取异步任务的状态 |
| system/list_agents | 列出所有已注册的 Agent |

> **注**：早期 v0.1 草案定义了 `task.request`、`task.result` 和 `agent.capabilities`。  
> 当前实现使用上述 JSON-RPC 风格的方法名，两者语义等价。  
> 未来版本可能根据实际使用反馈统一命名约定。

---

# 5. Timestamp 规则（实验约束）

为降低消息重放与乱序问题，当前实验版本建议：

- 消息 timestamp 与本地时间偏差不超过允许窗口
- 过期消息可被直接丢弃
- 节点可根据 timestamp 做简单幂等判断

当前规则仍可能调整。

---

# 6. ID 幂等规则

建议节点：

- 对已处理消息 ID 做短期缓存
- 重复消息直接忽略
- 网络重试不得重复执行副作用操作

此规则主要用于：

- Relay 重试
- 网络波动
- 移动网络切换
- 短时断连恢复

---

# 7. 广播限制

广播能力当前仅用于实验。

建议：

- 限制 TTL
- 限制广播频率
- 禁止无限转发
- 避免消息风暴

OpenAFP 当前不尝试构建复杂广播系统。

---

# 8. 扩展机制

扩展字段建议使用命名空间：

```json
{
  "extensions": {
    "openafp.trace": {},
    "openafp.progress": {},
    "custom.vendor.feature": {}
  }
}
```

当前原则：

- 核心字段保持最小化
- 扩展能力通过 extensions 承载
- 未识别扩展应被安全忽略

---

# 9. Agent 身份（当前实验阶段）

当前仅使用：

- peer_id
- libp2p identity
- agent_id

进行节点标识。

复杂认证体系（DID / PKI / Trust Network）暂不在当前实验范围内。

---

# 10. 与其他协议的关系

OpenAFP 当前不试图替代：

- MCP
- A2A
- 现有 RPC 系统

当前关注点主要是：

- NAT
- Relay
- 节点发现
- 动态网络连接
- Agent P2P 联网行为

---

# 11. 当前已验证场景

已完成部分真实网络实验：

- 家庭宽带 ↔ 公网 Relay
- 5G 热点 ↔ 云节点
- DHT 自动发现
- Relay 中继调用
- 跨 NAT 能力调用
- 动态网络重连
- pull.file 跨节点读取
- shell 能力受控实验

---

# 12. 已知问题

当前仍存在：

- 部分 NAT 下 DHT 同步较慢
- Relay 重连存在短暂延迟
- 移动网络切换可能导致 stream 重建
- 某些 CGNAT 环境稳定性一般
- 实验能力存在安全风险

---

# 13. 当前项目阶段

OpenAFP 当前更接近：

**"Agent P2P Networking Lab"**

而不是：

- 企业产品
- 行业标准
- 商业平台

项目主要价值在于：

- 真实网络实验
- libp2p + Agent 工程实践
- Relay/NAT/DHT 踩坑记录
- Agent 网络行为探索

---

# 14. 后续方向（可能变化）

未来可能继续探索：

- Relay 稳定性
- NAT 穿透优化
- 节点恢复
- 广播控制
- 流式消息
- 更简单的 SDK
- 最小 Demo 网络

是否演化为更正式协议，将取决于真实使用情况与外部反馈。

---

# 15. 文档状态

本协议文档当前为：

**实验性协议草案（Experimental Draft）**

接口、字段、行为均可能调整。  
请勿直接用于生产环境。
