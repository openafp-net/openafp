# OpenAFP HTTP API

## Overview

Base URL: `http://localhost:51888`

All endpoints return JSON. AFP protocol endpoints use JSON-RPC 2.0 format.

---

## Core Endpoints

### POST `/afp`

Main AFP JSON-RPC 2.0 endpoint.

**Methods:**

| Method | Description | Parameters |
|--------|-------------|------------|
| `invoke` | Invoke a capability | `capability`, `input`, `agent_id` (optional), `timeout` (optional) |
| `discover` | Discover peer capabilities | — |
| `register` | Register an agent | `agent_id`, `name`, `capabilities`, `endpoint` |
| `get_status` | Query async task status | `request_id` |
| `system/list_agents` | List all registered agents | — |

**Example:**
```bash
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"capability":"system/hostname"},"id":1}'

# Cross-node invocation
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"agent_id":"p2p://<peer_id>","capability":"system/whoami"},"id":2}'
```

---

### GET `/afp/status/{request_id}`

Query async task status.

**Response:**
```json
{"success":true,"data":{"id":"req-123","status":"completed","result":{...}}}
```

---

### GET `/v1/agents`

List all registered agents with capabilities and circuit breaker state.

**Query parameters:**
- `capability` — filter agents by capability name (e.g. `?capability=system/hostname`)

**Response:**
```json
{
  "success": true,
  "total": 3,
  "agents": [{
    "id": "agent-id",
    "name": "Agent Name",
    "endpoint": "p2p://...",
    "enabled": true,
    "capabilities": [{"name": "system/hostname", "description": "Get hostname"}],
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

Health check.

```json
{"status":"ok","agents":3}
```

---

### GET `/metrics`

Prometheus metrics (requires `observability.metrics.enabled: true`, auth-protected).

---

## Inspect Endpoints

Debug endpoints for network troubleshooting. Auth-protected.

### GET `/v1/inspect/peers`

List connected P2P peers with protocols, addresses, and direction.

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

Show this node's P2P identity.

```json
{
  "peer_id": "12D3KooWH...",
  "addresses": ["/ip4/180.98.68.3/tcp/51890", "/ip4/127.0.0.1/tcp/51890"],
  "protocols": ["/ipfs/kad/1.0.0", "/ipfs/id/1.0.0", "/libp2p/dcutr", "..."]
}
```

### GET `/v1/inspect/dht`

Show DHT routing table entries (up to 50, excluding connected peers).

```json
{
  "size": 42,
  "peers": [{"peer_id": "12D3KooX...", "addresses": ["/ip4/..."]}]
}
```

---

## Error Codes

| HTTP | Meaning |
|------|---------|
| 200 | Success |
| 400 | Bad request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not found |
| 500 | Internal server error |
