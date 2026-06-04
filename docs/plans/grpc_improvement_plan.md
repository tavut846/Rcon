# gRPC Camouflage Enhancement Plan

## Objective
Improve the camouflage of the Xray server when using `VLESS + TLS + gRPC` by making the server behave more like a legitimate web server to unauthorized probes, while remaining fully compatible with existing gRPC clients.

## Scope of Update
1.  **Service Name Customization:** Ensure the system supports legitimate-looking gRPC service names (e.g., `grpc.health.v1.Health`) to blend in with standard gRPC traffic.
2.  **Explicit ALPN Settings:** Modify the TLS configuration to explicitly offer both `h2` and `http/1.1`.
3.  **Fallback Integration:** Leverage the existing VLESS/Trojan fallback mechanism to redirect unauthorized HTTP traffic to a legitimate website.

## Current State Analysis
*   **Protocol Support:** VLESS/VMess/Trojan + gRPC is already implemented in `core/xray/inbound.go`.
*   **ALPN Missing:** The current TLS configuration (`TLSConfig`) in `buildInbound` does not explicitly set the `ALPN` field. This can result in the server only offering `h2` or no ALPN at all, which is a fingerprinting risk compared to standard web servers.
*   **Fallback Logic:** The infrastructure for fallbacks exists but is not automatically optimized for gRPC camouflage unless configured manually via the panel.

## Proposed Implementation (Draft)

### 1. Explicit ALPN for TLS
Modify `core/xray/inbound.go` within the `buildInbound` function:
- Locate the `tlsCfg := &coreConf.TLSConfig{...}` initialization.
- Add `ALPN: &coreConf.StringList{"h2", "http/1.1"}`.

### 2. Camouflage Strategy Improvement
- **Server-side Feature:** When a node uses gRPC transport, the server should ideally behave as a standard web server for any request that doesn't match the specific gRPC `serviceName`.
- **Camouflage Mechanism:** By offering both `h2` and `http/1.1`, the initial TLS handshake is indistinguishable from a normal website. If the client is the proxy, it uses gRPC over `h2`. If the client is a probe/browser, it will likely use `http/1.1` or standard `h2` GET requests, which will then trigger the Xray fallback to a real website.

## Verification Plan
1.  **Build Check:** Run `$env:GOEXPERIMENT='jsonv2'; go build ./core/xray/...` to ensure structural compatibility.
2.  **Handshake Test:** Use `openssl s_client -connect <IP>:<PORT> -alpn h2,http/1.1` to verify the server offers both protocols.
3.  **Probe Simulation:** Use a browser or `curl` to access the port and verify it redirects to the fallback destination instead of returning a proxy-specific error.
