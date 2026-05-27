[中文](README_CN.md) | English

OpenAFP — Free Interconnection for AI Agents

No public IP required. Agents behind NAT can be discovered and invoked.

OpenAFP is a decentralized connectivity layer purpose-built for AI Agents, enabling auto-discovery and collaboration across home, office, and cloud — even under complex network conditions.

![Topology](https://openafp.net/topology-en.svg)

---

📦 One-Line Install

Linux / macOS

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://install.openafp.net/install.sh | bash
```

Windows (PowerShell as Administrator)

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
irm https://install.openafp.net/install.ps1 | iex
```

After installation, the gateway starts automatically and joins the OpenAFP public bootstrap network for peer discovery and connectivity.

Wait about 30 seconds, then verify your node is running:

```bash
curl http://localhost:51888/health
```

If you see `{"status":"ok"}`, your node is up and running.

Ready to test cross-node invocation?

```bash
curl -X POST http://localhost:51888/afp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"invoke","params":{"capability":"system/hostname"},"id":1}'
```

You'll see hostnames from other nodes on the network — proof that your Agent has successfully joined OpenAFP.

💡 For cloud server users: some cloud platforms (e.g., Alibaba Cloud) may flag the one-line install script as a security alert. This is normal behavior for automated script execution. If blocked, whitelist `install.openafp.net` in your security center, or manually download the Release binary.

---

🚀 What Can You Do with OpenAFP?

Scenario 1: Multi-Agent Auto-Discovery & Collaboration

Agents on your home lab, office network, and cloud VMs automatically discover each other and collaborate on tasks. For example: Node A fetches data → Node B analyzes → Node C pushes results.

No public IPs. No manual port configuration. Nodes maintain persistent connections across different ISPs, countries, and network environments.

Ideal for:

- Multi-node AI workflows
- Distributed Agent collaboration
- Home / office / cloud hybrid networks

✅ Verified — heterogeneous nodes across multiple regions, stable long-term operation

---

Scenario 2: Mobile Hotspot / 5G / Temporary Network Environments

Agents running behind mobile hotspots, carrier-grade NAT, or temporary office networks can still connect to home devices and cloud servers automatically.

Ideal for:

- 5G / mobile hotspot environments
- Temporary or pop-up office networks
- Remote access to home NAS / mini-PCs

✅ Verified — stable connectivity under complex network conditions

---

Scenario 3: Access Corporate Intranet Tools from Home AI (Planned)

Deploy MCP Servers, internal APIs, and database tools inside the corporate network; your home AI Agent or Claude Desktop can access them through OpenAFP directly.

Ideal for:

- Corporate intranet tool access
- Home-office setups
- Remote AI tool collaboration

🚧 Planned — MCP over OpenAFP Prototype

---

🔐 Security & Design Principles

OpenAFP defaults to the principle of *least capability exposure*.

Currently exposed capabilities are strictly limited:

- No arbitrary shell execution
- No system-level remote control
- File reads are path- and size-capped by default
- All capabilities must be explicitly registered
- Nodes establish connectivity only; no automatic privilege sharing

The goal: safety, stability, and out-of-the-box success on the real Internet.

---

📢 We Want to Hear About Your Real-World Use Case

If you're dealing with:

- Home devices that can't be reached from outside
- Cross-region AI Agent collaboration challenges
- Multi-node auto-connectivity problems
- Home / office / cloud device interconnection
- Or any "Agent connectivity" challenge

Please open an Issue and share your real-world scenario. Your feedback directly shapes OpenAFP's roadmap.

---

🧭 Resources

- [Live network status](https://status.openafp.net)
- [Full capability list](docs/CAPABILITIES.md)
- [Protocol specification (experimental draft)](protocol/SPEC.md)
- [FAQ & networking pitfalls](docs/NETWORKING_PITFALLS.md)

---

🤝 Contributing

OpenAFP is still experimental. We welcome:

- Bug reports
- Real-world usage feedback
- Capability & protocol proposals
- Testing & documentation improvements

Connect with us:

- [GitHub Discussions (Forum)](https://github.com/openafp-net/openafp/discussions) – technical discussions, roadmap, use-case sharing (global audience)
- [Gitee Issues (Discussions)](https://gitee.com/openafp/openafp-public/issues) – questions, use-case sharing (recommended for Chinese-speaking users)
- GitHub Issues
- Gitee Issues
- Discord (planned)
- Email: 2727989@qq.com

---

📄 License

Apache 2.0 — see [LICENSE](LICENSE)

---

OpenAFP — Let AI Agents Connect Freely.