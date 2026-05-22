# OpenAFP HTTP API 文档

本文档详细描述 OpenAFP 网关提供的所有 HTTP API 端点。

## 概述

OpenAFP 网关提供两类 HTTP API：

1. **核心 AFP API** - 用于 AFP 协议通信和异步任务查询
2. **市场 API** - 用于代理注册、发现、评分和协商（可选，启用市场时可用）

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
| `invoke` | 调用一个能力 | `capability`: 能力名称<br>`input`: 输入参数<br>`callback`: 回调 URL（可选）<br>`timeout`: 超时（秒，可选） |
| `system/list_agents` | 列出本地所有代理 | 无 |

**响应格式**: JSON-RPC 2.0

```json
{
  "jsonrpc": "2.0",
  "result": { ... },
  "id": 1
}
```

**示例**:
```bash
curl -X POST http://localhost:8080/afp \
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

**描述**: 列出所有已注册的代理及其能力。

**响应**:
```json
{
  "success": true,
  "data": {
    "agents": [
      {
        "id": "agent-id",
        "name": "Agent Name",
        "endpoint": "endpoint-url",
        "enabled": true,
        "capabilities": [
          {
            "name": "capability-name",
            "description": "描述",
            "input_schema": { ... },
            "output_schema": { ... }
          }
        ]
      }
    ],
    "total": 5
  }
}
```

---

### GET `/health`

**描述**: 健康检查端点。

**响应**:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2026-04-23T10:00:00Z",
    "version": "v0.4.1"
  }
}

**状态码**: `200` = 健康，`503` = 不健康

---

### GET `/metrics`

**描述**: Prometheus 监控指标端点（仅当 `observability.metrics.enabled: true` 时可用）。

---

## 市场 API (Marketplace)

当启用市场功能时，以下端点可用，所有端点路径前缀为 `/market`。

### POST `/market/register`

**描述**: 注册一个新代理到市场。

**请求头**:
- `X-Provider-ID` - 提供者 ID（必需）

**请求体**:
```json
{
  "agent_id": "afp://example/diagnostic",
  "capabilities": ["diagnostic", "analysis"],
  "pricing": {
    "model": "per_call",
    "price": 0.50,
    "currency": "CNY",
    "min_price": 0.10,
    "max_price": 1.00,
    "free_tier": 5
  },
  "contact_info": "contact@example.com",
  "metadata": "{}"
}
```

**响应**: 注册成功返回代理信息。

---

### POST `/market/deregister/{agent_id}`

**描述**: 从市场注销一个代理。

**请求头**:
- `X-Provider-ID` - 提供者 ID（必需，必须是所有者）

**路径参数**:
- `agent_id` - 代理 ID

---

### GET `/market/agent/{agent_id}`

**描述**: 获取代理详细信息。

**路径参数**:
- `agent_id` - 代理 ID

**响应**: 返回完整的代理信息包括定价、评分、能力等。

---

### GET `/market/search` / POST `/market/search`

**描述**: 按能力搜索代理。

**GET 查询参数**:
- `capability` - 能力名称（必需）
- `max_price` - 最高价格（可选）
- `min_rating` - 最低评分（可选）
- `provider_id` - 提供者 ID 过滤（可选）
- `limit` - 结果数量限制（默认 20，最大 100）
- `offset` - 分页偏移（可选）

**POST 请求体**: 同上述参数 JSON 格式。

**响应**:
```json
{
  "success": true,
  "data": {
    "agents": [...],
    "total_count": 10,
    "criteria": { ... }
  }
}
```

---

### GET `/market/agents`

**描述**: 列出所有活跃代理（管理接口）。

**请求头**:
- `Authorization: Bearer <token>` - 管理员认证（必需）

---

### POST `/market/rating`

**描述**: 提交对代理的评分。

**请求体**:
```json
{
  "agent_id": "agent-id",
  "rating": 4.5,
  "comment": "很好的服务",
  "caller_id": "caller-agent-id"
}
```

**评分范围**: `0.0` - `5.0`

---

### GET `/market/agent/{agent_id}/ratings`

**描述**: 获取代理的所有评分历史。

**路径参数**:
- `agent_id` - 代理 ID

**说明**: 当前版本评分历史仅存储在 SQLite 中，此端点返回完整列表。

---

### POST `/market/negotiate`

**描述**: 发起价格协商。

**请求体**:
```json
{
  "agent_id": "agent-id",
  "caller_id": "caller-id",
  "capability": "capability-name",
  "parameters": { ... },
  "budget": 0.50,
  "duration": 60,
  "priority": "medium",
  "deadline": "2026-04-24T10:00:00Z"
}
```

---

### GET `/market/health`

**描述**: 市场模块健康检查。

---

### GET `/market/stats`

**描述**: 获取市场统计信息。

**响应**:
```json
{
  "success": true,
  "data": {
    "total_agents": 100,
    "active_agents": 85,
    "average_rating": 4.2,
    "capabilities": {
      "translate": 25,
      "summarize": 18
    },
    "timestamp": "2026-04-23T10:00:00Z"
  }
}
```

---

## 错误码

| HTTP 状态码 | 含义 |
|-------------|------|
| `200` | 成功 |
| `201` | 创建成功（注册）|
| `400` | 请求参数错误 |
| `401` | 未认证 |
| `403` | 无权限 |
| `404` | 资源不存在 |
| `405` | 方法不允许 |
| `500` | 服务器内部错误 |

---

## 示例用法

### 搜索代理

```bash
curl "http://localhost:8080/market/search?capability=translate&max_price=1.0&min_rating=4.0"
```

### 注册代理

```bash
curl -X POST http://localhost:8080/market/register \
  -H "X-Provider-ID: my-provider-id" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_id": "my-translate-agent",
    "capabilities": ["translate"],
    "pricing": {
      "model": "per_call",
      "price": 0.30,
      "currency": "CNY"
    }
  }'
```

### 调用 AFP 方法

```bash
curl -X POST http://localhost:8080/afp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "invoke",
    "params": {
      "capability": "echo",
      "input": {
        "message": "Hello OpenAFP!"
      }
    },
    "id": 1
  }'
```

---

## 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-04-23 | v0.4.1 | 初始版本，完整记录所有 API |
