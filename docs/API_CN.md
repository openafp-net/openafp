# OpenAFP HTTP API 文档

## 概述

基础 URL：`http://localhost:51888`

所有端点返回 JSON。AFP 协议端点使用 JSON-RPC 2.0 格式。

---

## 核心端点

### POST `/afp`

主 AFP JSON-RPC 2.0 端点。

**支持的方法：**

| 方法 | 描述 | 参数 |
|------|------|------|
| `invoke` | 调用能力 | `capability`、`input`、`agent_id`（可选）、`timeout`（可选） |
| `discover` | 发现对端能力 | — |
| `register` | 注册代理 | `agent_id`、`name`、`capabilities`、`endpoint` |
| `get_status` | 查询异步任务状态 | `request_id` |
| `system/list_agents` | 列出所有已注册代理 | — |

**示例：**
```bash
# 本地调用（本地优先）
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"capability":"system/hostname"},"id":1}'

# 跨节点调用
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"agent_id":"p2p://<peer_id>","capability":"system/whoami"},"id":2}'
```

---

### GET `/afp/status/{request_id}`

查询异步任务状态。

```json
{"success":true,"data":{"id":"req-123","status":"completed","result":{...}}}
```

---

### GET `/v1/agents`

列出所有已注册代理，包含能力和熔断器状态。

**查询参数：**
- `capability` — 按能力名称过滤（如 `?capability=system/hostname`）

**响应：**
```json
{
  "success": true,
  "total": 3,
  "agents": [{
    "id": "agent-id",
    "name": "Agent Name",
    "endpoint": "p2p://...",
    "enabled": true,
    "capabilities": [{"name": "system/hostname", "description": "获取主机名"}],
    "circuit_state": "closed",
    "failure_threshold": 5,
    "timeout_seconds": 60,
    "consecutive_failures": 0,
    "total_invocations": 42
  }]
}
```

---

### GET `/health`

健康检查。

```json
{"status":"ok","agents":3}
```

---

### GET `/metrics`

Prometheus 监控指标（需启用 `observability.metrics.enabled: true`，受认证中间件保护）。

---

## Inspect 调试端点

用于网络故障排查。受认证中间件保护。

### GET `/v1/inspect/peers`

列出已连接的 P2P 对等节点。

```json
{
  "peers": [{
    "id": "12D3KooW...",
    "addresses": ["/ip4/121.199.174.198/tcp/51890"],
    "protocols": ["/ipfs/kad/1.0.0", "/ipfs/id/1.0.0"],
    "connected": true,
    "direction": "outbound",
    "latency": "35ms"
  }]
}
```

### GET `/v1/inspect/self`

查看本节点 P2P 身份信息。

```json
{
  "peer_id": "12D3KooWH...",
  "addresses": ["/ip4/180.98.68.3/tcp/51890", "/ip4/127.0.0.1/tcp/51890"],
  "protocols": ["/ipfs/kad/1.0.0", "/ipfs/id/1.0.0", "/libp2p/dcutr", "..."]
}
```

### GET `/v1/inspect/dht`

查看 DHT 路由表（最多 50 条，不含已连接节点）。

```json
{"size": 42, "peers": [{"peer_id": "12D3KooX...", "addresses": ["/ip4/..."]}]}
```

---

## 错误码

| HTTP | 含义 |
|------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未认证 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |
