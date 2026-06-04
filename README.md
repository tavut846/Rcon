# Rcon

Network course

## Features

* **Xray-core only:** Focused and lightweight.
* **Protocols:** 
* **Xboard Integration:** 
* **Multi-Node Support:** 
* **Advanced Features:**


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

Rcon is a fork and simplification of [V2bX](https://google.com), which in turn was inspired by [XrayR](https://google.com).


