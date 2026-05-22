[中文](README_CN.md) | English

# OpenAFP
Experimental Agent Overlay Network for real-world NAT environments.

## Install

**Linux/macOS**
```bash
curl --proto '=https' --tlsv1.2 -fsSL https://install.openafp.net/install.sh | bash
```

**Windows (PowerShell as Administrator)**
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
irm https://install.openafp.net/install.ps1 | iex
```

> **💡 For cloud server users**
>
> When running the one‑line install command on Alibaba Cloud or similar platforms, the security system may trigger an alert (because an automated process is downloading and executing a remote script). This is normal and expected.
>
> **Solutions:**
> - **Option 1 (recommended)**: Add `install.openafp.net` to the whitelist in your cloud security center.
> - **Option 2**: Manually download the binary (see Manual Install Guide, coming soon).
>
> Personal computer users will not encounter this issue.

## Quick Start

After installation, wait 30 seconds for DHT sync, then:

```bash
curl http://localhost:51888/health
curl -X POST http://localhost:51888/afp -d '{"jsonrpc":"2.0","method":"invoke","params":{"capability":"system/hostname"},"id":1}'
```

## Documentation

- [Protocol Specification](protocol/SPEC.md)
- [API Reference](docs/API.md)
- [Capabilities](docs/CAPABILITIES.md)
- [Networking Pitfalls](docs/NETWORKING_PITFALLS.md)

## License

Apache 2.0 — see [LICENSE](LICENSE)
