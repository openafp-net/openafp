# OpenAFP 网络踩坑记录

> 记录我们在 P2P Agent 网络中踩过的每一个坑，供后来者参考。

---

## 1. libp2p Circuit Relay 60 秒硬编码超时

**现象**：中继连接总是 60 秒超时，日志显示 `circuit relay reservation failed`。

**根因**：go-libp2p circuitv2 协议内部有 60 秒硬编码超时（`ReservationRequestTimeout`），无法通过配置修改。

**修复**：在中继节点启动时提前建立 reservation，客户端设置合理的 `reservation_ttl_seconds`（3600s）。中继节点需要公网可达 IP。

**教训**：libp2p 的默认超时不是为 WAN 场景设计的，慢网络上需要耐心等待。

---

## 2. 端口不统一导致连接失败

**现象**：配置中中继端口混用 51889 和 51890，部分节点连不上。

**根因**：不同版本的配置模板端口不一致，手动编辑时遗漏。

**修复**：统一所有节点 P2P 端口为 51890。HTTP 端口 51888 保持不变。

**教训**：引导节点地址应作为代码常量（`DefaultBootstrapPeers()`），不在 config.yaml 中手写。

---

## 3. DHT 幽灵节点

**现象**：`/v1/agents` 中出现没有 IP 地址、没有能力的空节点，调用时 `no addresses`。

**根因**：DHT Provider 记录默认 TTL 为 24 小时。节点下线后 DHT 仍保留其 Peer ID，直到 TTL 过期。

**修复**：
- 注册表中添加 `LastSeen` 时间戳，`RemoveStaleAgents(1h)` 定期清理
- 配置 `Registry.LastSeen` 淘汰到 `StartCleanupLoop` 中

**教训**：DHT 发现 ≠ 在线。必须配合 Identify 确认节点可达且有实际能力。

---

## 4. Auto-Discover 自拨号

**现象**：自动发现能力时偶尔 `skip self connection: peer ID is our own node ID`。

**根因**：`FindFirstByCapability` 使用 `s.agentID`（`afp://openafp/gateway1`）排除自己，但注册表中还存在 `p2p://<localPeerID>` 格式的本地 agent，未被排除。

**修复**（两个 commit）：
1. `76e369b`：在 `FindFirstByCapability` 结果中额外检查 `localP2PID`
2. `10e78a5`：auto-discover 转发时清空 `agent_id`（让接收方本地执行而不继续路由）

**教训**：同一节点在注册表中有多个 ID（`afp://` 和 `p2p://`），排除逻辑要覆盖所有形式。

---

## 5. Identify 时序问题

**现象**：`/v1/agents` 显示某些节点能力为 0。

**根因**：DHT 先发现节点并注册（空能力），然后 Identify 协议完成。旧代码在 Identify 完成时跳过已注册的 agent。

**修复**：Identify 回调对已注册 agent 改为**更新**能力，而非跳过。

**教训**：libp2p 的发现和能力同步是异步的，必须处理"先发现、后补全"的时序。

---

## 6. go build 缓存陷阱

**现象**：协议格式升级（JSON-RPC → 8 字段）后部分节点 `Method not found`。

**根因**：`go build` 使用缓存，源码更新后未用 `-a` 或 `go clean -cache`，编译出旧二进制。

**修复**：
```bash
git pull && go clean -cache && go build -o openafp-gateway ./cmd/gateway/
```

**教训**：协议升级这种 Breaking Change 必须全员同步 `go clean -cache`。

---

## 7. 公网 IP 检测

**现象**：云服务器节点无法检测到自己的公网 IP。

**根因**：`net.Dial("udp", "8.8.8.8:80")` 返回的是私有接口 IP，不是公网 IP。`IsPrivate()` 过滤掉了云服务器的 NAT 公网 IP。

**修复**：改用 `https://icanhazip.com` HTTP 请求获取真实公网 IP，UDP dial 作为 fallback。

**教训**：云服务器的公网 IP 不在本地接口上（NAT），不能用 `LocalAddr()` 获取。

---

## 8. AdvertiseCapability 阻塞启动

**现象**：网关启动后 DHT 发现永远不开始。

**根因**：`AdvertiseCapability` 在 routing table 为空时会等待重试，而单节点 DHT 的 routing table 始终为空，导致无限阻塞。由于 advertise 是同步调用，后续的 `startDHTDiscovery` 永远得不到执行。

**修复**：routing table 为空时直接 skip（`return nil`），不等待。

**教训**：单节点 DHT 的 routing table 永远为空，advertise 必然失败。设计重试逻辑时必须考虑"永远无法成功"的场景。

---

## 9. 日志洪泛导致磁盘写满

**现象**：`AdvertiseCapability` 每次重试都打印日志，20 分钟产生 16GB 日志。

**根因**：retry 循环中无限制地打日志，每次重试 1-3 分钟不等。

**修复**：只在成功时打印日志；retry 循环静默。

**教训**：retry 循环中的日志必须有频率限制或只在状态变化时输出。

---

## 10. gorilla/mux 路由从未挂载

**现象**：`afp.Server.RegisterRoutes()` 注册到 gorilla/mux router，但实际 HTTP 服务使用的是 `http.ServeMux`。

**根因**：v0.13 架构重构后路由统一到 `gateway.BuildHTTPServeMux()`，但旧路由代码未清理。

**修复**：删除 gorilla/mux 依赖，所有路由统一使用 `http.ServeMux`（Go 1.22+ pattern matching）。

**教训**：重构后必须检查旧代码是否已失效，用 grep 验证每个函数的调用链。

---

## 11. mDNS goroutine 无生命周期管理

**现象**：mDNS 发现的每个 peer 都 `go func()` 连接，无 context 控制。

**根因**：使用 `context.Background()` 而非节点的可取消 context。

**修复**：`Node.Close()` 中添加 `n.mdns.Close()`，确保 mDNS 服务被正确关闭。

**教训**：所有后台 goroutine 必须关联到可取消的 context。

---

## 12. DHT 能力广告的空键问题

**现象**：DHT 发现节点后能力为空（0 caps），调用失败。

**根因**：DHT Provider 记录的是 `/openafp/v1` namespace 下的 Peer ID，不包含能力信息。能力信息依赖 Identify 协议交换。

**教训**：DHT 只告诉你"谁在线"，不告诉你"能做什么"。能力发现必须依赖 Identify 或上层注册表。

---

## 13. .gitignore 模式过宽

**现象**：`cmd/gateway/main.go` 的改动从不被 git 追踪。

**根因**：`.gitignore` 中 `gateway` 通配符匹配了 `cmd/gateway/` 目录。

**修复**：改为 `/gateway`（仅匹配根目录的二进制文件）。

**教训**：`.gitignore` 的裸词条会匹配任意深度，必须加 `/` 前缀限制到根目录。

---

## 总结

| 原则 | 说明 |
|------|------|
| DHT ≠ 在线 | 配合 Identify + LastSeen 淘汰 |
| retry 要静默 | 日志只在状态变化时输出 |
| ID 多形式 | afp:// 和 p2p:// 都要考虑 |
| go clean -cache | 协议变更后必做 |
| 路由要验证 | 重构后 grep 确认每个函数被正确挂载 |
| context 要传递 | 所有 goroutine 关联可取消 context |
| .gitignore 要精准 | 裸词条用 `/` 前缀限制根目录 |

---

## 14. 不对称连接（公网 ↔ 私有 IP 各自视角不同）

**现象**：节点 A（公网 IP）看节点 B 走中继（Limited），节点 B 看节点 A 却是直连（Connected）。

**根因**：一方有公网 IP，另一方只有私有 IP。libp2p 连接是非对称的——有公网 IP 的一方可以直接被拨入，私有 IP 的一方只能通过中继被回拨。

**示例**：盼盼 5G 热点（私有 `172.20.10.7`，运营商 NAT 映射公网 `180.98.89.39`），阿福家庭 NAT（私有 `192.168.3.17`）。
- 阿福 → 盼盼：直连。盼盼通过 `icanhazip.com` 获取运营商 NAT 的公网 IP 并宣告到 DHT，阿福拨该公网 IP，运营商 NAT 利用 endpoint‑independent mapping 将流量转发到盼盼的私有 IP。
- 盼盼 → 阿福：中继 Limited（阿福无公网 IP，运营商未映射入站端口）。

**结论**：5G 热点下"阿福→盼盼直连"本质上是运营商 NAT 穿透，利用了 endpoint‑independent mapping 特性，不是传统中继或 DCUtR 打洞。这是正常行为，非 bug。

---

## 15. 双方公网 IP 时直连无打洞过程

**现象**：阿福（电信宽带公网 IP `114.217.10.134`）和盼盼（5G 热点公网 IP `180.98.89.39`）互拨成功，日志中无 `Limited → Connected` 打洞过程，所有能力测试正常。

**根因**：电信宽带动态分配了真实公网 IP（非 `192.168.x.x`），双方都具备全球可路由地址。libp2p 通过 DHT 互相发现公网地址后直接建立 TCP 连接，不经过中继也不触发 DCUtR 打洞。

**关键认知**：
- 同一家庭宽带在不同时间可能表现为私有 IP 或公网 IP（运营商动态分配）。
- libp2p 自动适应：都有公网就直连，一方私有就走中继，不需要人工干预。
- 这不是打洞成功也不是代码改进——纯粹是网络条件变了。

**测试日期**：2026-05-21
