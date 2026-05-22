# OpenAFP
Experimental Agent Overlay Network for real-world NAT environments.

## Install

**Linux/macOS**
```bash
curl -fsSL https://install.openafp.net/install.sh | bash
```

**Windows (PowerShell as Administrator)**
```powershell
irm https://install.openafp.net/install.ps1 | iex
```

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
