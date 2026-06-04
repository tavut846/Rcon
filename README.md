# Rcon

A lightweight Xboard node backend based exclusively on Xray-core.

## Features

* **Xray-core only:** Focused and lightweight.
* **Protocols:** Supports VMess, VLESS (including Vision/Reality), Trojan, and Shadowsocks.
* **Xboard Integration:** Fully compatible with Xboard admin manager using the V1 UniProxy API.
* **Multi-Node Support:** Manage multiple nodes with a single Rcon instance.
* **Advanced Features:**
    * Automated TLS certificate management (HTTP/DNS/Self-signed).
    * Real-time online user tracking and IP limits.
    * Per-user and per-node speed limiting.
    * Built-in audit rules.
    * Configuration auto-reload.

## Installation

### One-click Install

```bash
wget -N https://raw.githubusercontent.com/FNode/Rcon/master/rcon.sh && bash rcon.sh
```

## Build

To build the Rcon binary manually:

```bash
GOEXPERIMENT=jsonv2 go build -v -o rcon -tags "xray with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" -trimpath -ldflags "-s -w -buildid="
```

## Acknowledgments

Rcon is a fork and simplification of [V2bX](https://github.com/wyx2685/V2bX), which in turn was inspired by [XrayR](https://github.com/XrayR-project/XrayR).

Special thanks to:
* [Project X (Xray-core)](https://github.com/XTLS/Xray-core)
* [Xboard](https://github.com/cedar2025/Xboard)
* [V2bX](https://github.com/wyx2685/V2bX)
