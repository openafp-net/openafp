# OpenAFP HTTP API 文档

> ⚠️ 部分端点（Market API）对应模块已删除，仅保留文档供参考。

---

## 概述

OpenAFP 网关提供以下 HTTP API：

1. **核心 AFP API** — AFP 协议通信、异步任务查询、节点管理
2. **市场 API** — 代理注册、发现、评分和协商（⚠️ 对应模块已移除，以下文档仅供参考）

所有 API 响应使用统一的 JSON 格式：

```json
{
  "success": true,
  "data": { ... },
  "error": "错误信息（如有）",
  "message": "提示信息（可选）"
}
```

---

## 核心 API

### POST `/afp`

**描述**: 主 AFP JSON-RPC 端点，用于所有 AFP 协议方法调用。

**请求格式**: JSON-RPC 2.0

```json
{
  "jsonrpc": "2.0",
  "method": "method_name",
  "params": { ... },
  "id": 1
}
```

**支持的方法**:

| 方法 | 描述 | 参数 |
|------|------|------|
| `discover` | 获取对端代理能力列表 | 无 |
| `invoke` | 调用一个能力 | `capability`: 能力名称<br>`input`: 输入参数<br>`timeout`: 超时（秒，可选） |
| `register` | 注册代理 | `agent_id`, `name`, `capabilities`, `endpoint` |
| `get_status` | 查询异步任务状态 | `request_id`: 任务 ID |
| `system/list_agents` | 列出本地所有代理 | 无 |

**示例**:
```bash
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"system/list_agents","params":{},"id":1}'
```

---

### GET `/afp/status/{request_id}`

**描述**: 查询异步调用的任务状态。

**路径参数**:
- `request_id` - 异步任务 ID

**响应**:
```json
{
  "success": true,
  "data": {
    "id": "request-id",
    "status": "completed|processing|failed",
    "result": { ... },
    "created_at": "2026-04-23T10:00:00Z"
  }
}
```

---

### GET `/v1/agents`

**描述**: 列出所有已注册的代理及其能力和熔断器状态。

**响应**:
```json
{
  "success": true,
  "agents": [
    {
      "id": "agent-id",
      "name": "Agent Name",
      "endpoint": "p2p://...",
      "enabled": true,
      "capabilities": [{ "name": "...", "description": "..." }]
    }
  ],
  "total": 5
}
```

---

### GET `/health`

**描述**: 健康检查端点。

**响应**:
```json
{"status":"ok","agents":5}
```

---

### GET `/metrics`

**描述**: Prometheus 监控指标端点（需 `observability.metrics.enabled: true`，受认证中间件保护）。

---

## 市场 API (Marketplace) — ⚠️ 已移除

以下端点对应的 `pkg/market/` 模块已删除。文档保留仅供历史参考。

- `POST /market/register` — 注册代理到市场
- `POST /market/deregister/{agent_id}` — 注销代理
- `GET /market/agent/{agent_id}` — 获取代理详情
- `GET /market/search` / `POST /market/search` — 按能力搜索
- `GET /market/agents` — 列出活跃代理（管理接口）
- `POST /market/rating` — 提交评分
- `GET /market/agent/{agent_id}/ratings` — 评分历史
- `POST /market/negotiate` — 价格协商
- `GET /market/health` — 市场健康检查
- `GET /market/stats` — 市场统计

---

## 错误码

| HTTP 状态码 | 含义 |
|-------------|------|
| `200` | 成功 |
| `400` | 请求参数错误 |
| `401` | 未认证 |
| `403` | 无权限 |
| `404` | 资源不存在 |
| `500` | 服务器内部错误 |

---

## 示例用法

### 调用本地能力

```bash
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"capability":"system/hostname"},"id":1}'
```

### 跨节点调用

```bash
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"agent_id":"p2p://<peer_id>","capability":"system/whoami"},"id":2}'
```

### 查看在线节点

```bash
curl http://localhost:51888/v1/agents
```
