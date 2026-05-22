# OpenAFP 能力清单

> 列出 OpenAFP 当前所有可调用的能力（内置 + 脚本）。  
> 调用方式：HTTP `POST /afp` JSON-RPC 2.0，或 P2P 流（自动发现/指定 agent_id）。

---

## 内置能力

| 能力名 | 说明 | 输入 | 输出示例 | 备注 |
|--------|------|------|----------|------|
| `system/discover` | 发现节点信息（ID、版本、能力列表） | 无 | `{"agent_id":"afp://...","version":"0.1.0"}` | - |
| `system/list_agents` | 列出注册表中所有 Agent | 无 | JSON 数组 | - |
| `system/hostname` | 获取节点主机名 | 无 | `"yaoqingya"` | - |
| `system/whoami` | 获取当前用户名 | 无 | `"Administrator"` | - |
| `system/ip` | 获取出口 IP | 无 | `"172.20.10.7"` | UDP 探测 |
| `system/ifconfig` | 获取网卡配置信息 | 无 | 多行文本 | - |
| `system/notify` | 向节点发送通知（写入日志） | `{"message":"...", "from":"..."}` | `{"delivered":true}` | 空 `agent_id` 时广播所有已连接节点 |
| `pull.file` | **实验性**：读取工作目录内文件 | `{"path":"relative/path"}` | 文件内容(base64) | ⚠️ 禁止绝对路径/路径穿越 |
| `shell/*` | **默认禁用**：执行系统命令 | `{"args":[]}` | 命令 stdout | ⚠️ 需手动开启，风险自负 |

---

## 可配置脚本能力

通过 `config.yaml` 声明，无需修改 Go 代码：

```yaml
capabilities:
  - name: my/hello
    script: scripts/hello.sh
    timeout: 30
  - name: gpu/compute
    script: /opt/gpu/compute.sh
    timeout: 60
```

- **路径安全**：脚本必须在 `scripts/` 目录下
- **热重载**：修改 `config.yaml` 后自动生效，无需重启
- **参数**：支持 `args`（字符串数组）和 `stdin`（字符串）
- **超时**：默认 30s，可配置

### 脚本能力调用

```bash
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"capability":"my/hello","input":{"args":["--text","hello"]}},"id":1}'
```

---

## 调用示例

### 本地调用

```bash
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"capability":"system/hostname"},"id":1}'
```

### 指定目标节点

```bash
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"agent_id":"p2p://<peer_id>","capability":"system/whoami"},"id":2}'
```

### 广播通知（不指定 agent_id）

```bash
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"capability":"system/notify","input":{"message":"请更新","from":"盼盼"}},"id":1}'
```

---

## 注意事项

- **`pull.file`**：仅限相对路径，禁止 `/etc/passwd` 等绝对路径。
- **`shell/*`**：默认关闭，手动注册后才能调用。仅用于受控实验环境。
- **`system/notify` 广播**：`agent_id` 为空时向所有已连接节点发送。
- **脚本能力**：即使不指定 `agent_id`，也会因为 `SetLocalHandler` 注册而在本地优先执行。
