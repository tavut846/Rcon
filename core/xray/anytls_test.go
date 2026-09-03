package xray

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"math/big"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/tavut846/Rcon/api/panel"
	"github.com/tavut846/Rcon/conf"
)

func createTestCertFiles(t *testing.T) (certFile string, keyFile string) {
	priv, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("failed to generate private key: %v", err)
	}

	template := x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject: pkix.Name{
			Organization: []string{"Test Org"},
		},
		NotBefore:             time.Now().Add(-time.Hour),
		NotAfter:              time.Now().Add(time.Hour * 24),
		KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
		DNSNames:              []string{"example.com"},
	}

	derBytes, err := x509.CreateCertificate(rand.Reader, &template, &template, &priv.PublicKey, priv)
	if err != nil {
		t.Fatalf("failed to create certificate: %v", err)
	}

	tempDir := t.TempDir()
	certPath := filepath.Join(tempDir, "cert.pem")
	keyPath := filepath.Join(tempDir, "key.pem")

	certOut, err := os.Create(certPath)
	if err != nil {
		t.Fatalf("failed to open cert.pem for writing: %v", err)
	}
	_ = pem.Encode(certOut, &pem.Block{Type: "CERTIFICATE", Bytes: derBytes})
	_ = certOut.Close()

	keyOut, err := os.Create(keyPath)
	if err != nil {
		t.Fatalf("failed to open key.pem for writing: %v", err)
	}
	privBytes, err := x509.MarshalECPrivateKey(priv)
	if err != nil {
		t.Fatalf("failed to marshal private key: %v", err)
	}
	_ = pem.Encode(keyOut, &pem.Block{Type: "EC PRIVATE KEY", Bytes: privBytes})
	_ = keyOut.Close()

	return certPath, keyPath
}

func TestBuildInbound_AnyTLS_TLS(t *testing.T) {
	certFile, keyFile := createTestCertFiles(t)

	nodeInfo := &panel.NodeInfo{
		Id:       1,
		Type:     "anytls",
		Security: panel.Tls,
		Common: &panel.CommonNode{
			ServerPort: 443,
		},
		AnyTLS: &panel.AnyTLSNode{
			Network:         "ws",
			NetworkSettings: json.RawMessage(`{"path":"/ws","headers":{"Host":"example.com"}}`),
			PaddingScheme:   []string{"stop=8", "0=30-30"},
		},
	}

	opts := &conf.Options{
		ListenIP: "0.0.0.0",
		CertConfig: &conf.CertConfig{
			CertMode: "http",
			CertFile: certFile,
			KeyFile:  keyFile,
		},
	}

	inboundConfig, err := buildInbound(opts, nodeInfo, "anytls-inbound-test")
	if err != nil {
		t.Fatalf("buildInbound failed for AnyTLS with TLS: %v", err)
	}

	if inboundConfig == nil {
		t.Fatal("expected non-nil inboundConfig")
	}
}

func TestBuildInbound_AnyTLS_Reality(t *testing.T) {
	// Generate a 32-byte curve25519 raw base64 private key
	rawKey := make([]byte, 32)
	for i := range rawKey {
		rawKey[i] = byte(i + 1)
	}
	privKey := base64.RawURLEncoding.EncodeToString(rawKey)

	nodeInfo := &panel.NodeInfo{
		Id:       2,
		Type:     "anytls",
		Security: panel.Reality,
		Common: &panel.CommonNode{
			ServerPort: 443,
		},
		AnyTLS: &panel.AnyTLSNode{
			Network:       "tcp",
			PaddingScheme: []string{"stop=8", "0=30-30"},
			TlsSettings: panel.TlsSettings{
				ServerName: "reality.domain.com",
				Dest:       "reality.domain.com",
				ServerPort: "443",
				PrivateKey: privKey,
				ShortId:    "abcdef12",
			},
			RealityConfig: panel.RealityConfig{
				MaxTimeDiff: "0s",
			},
		},
	}

	opts := &conf.Options{
		ListenIP: "0.0.0.0",
	}

	inboundConfig, err := buildInbound(opts, nodeInfo, "anytls-reality-test")
	if err != nil {
		t.Fatalf("buildInbound failed for AnyTLS with Reality: %v", err)
	}

	if inboundConfig == nil {
		t.Fatal("expected non-nil inboundConfig")
	}
}

func TestBuildAnyTLSUsers(t *testing.T) {
	users := []panel.UserInfo{
		{
			Id:   101,
			Uuid: "a8098c1a-f86e-11da-bd1a-00112444be1e",
		},
	}

	protoUsers := buildAnyTLSUsers("test-tag", users)
	if len(protoUsers) != 1 {
		t.Fatalf("expected 1 user, got %d", len(protoUsers))
	}
	memUser, err := protoUsers[0].ToMemoryUser()
	if err != nil {
		t.Fatalf("failed to convert to memory user: %v", err)
	}
	if memUser == nil {
		t.Fatal("expected non-nil memory user")
	}
}

func TestBuildInbound_Reality_DestHandling(t *testing.T) {
	rawKey := make([]byte, 32)
	for i := range rawKey {
		rawKey[i] = byte(i + 1)
	}
	privKey := base64.RawURLEncoding.EncodeToString(rawKey)

	// Case 1: Non-443 server_port (8001) with empty Dest -> auto-defaults to 127.0.0.1:8001
	nodeInfoAuto := &panel.NodeInfo{
		Id:       10,
		Type:     "vless",
		Security: panel.Reality,
		Common: &panel.CommonNode{
			ServerPort: 443,
		},
		VAllss: &panel.VAllssNode{
			CommonNode: panel.CommonNode{ServerPort: 443},
			Tls:        2,
			TlsSettings: panel.TlsSettings{
				ServerName: "in001.666633.best",
				ServerPort: "8001",
				Dest:       "",
				PrivateKey: privKey,
				ShortId:    "abcdef12",
			},
			RealityConfig: panel.RealityConfig{
				MaxTimeDiff: "0s",
			},
		},
	}

	optsAuto := &conf.Options{
		ListenIP:    "0.0.0.0",
		XrayOptions: &conf.XrayOptions{Xver: 1},
	}

	inboundAuto, err := buildInbound(optsAuto, nodeInfoAuto, "reality-auto-steal-test")
	if err != nil {
		t.Fatalf("buildInbound failed for auto steal-oneself: %v", err)
	}
	if inboundAuto == nil {
		t.Fatal("expected non-nil inboundConfig")
	}

	// Case 2: Explicit XrayOptions.Dest set to "127.0.0.1"
	optsExplicit := &conf.Options{
		ListenIP: "0.0.0.0",
		XrayOptions: &conf.XrayOptions{
			Xver: 1,
			Dest: "127.0.0.1",
		},
	}
	inboundExplicit, err := buildInbound(optsExplicit, nodeInfoAuto, "reality-explicit-dest-test")
	if err != nil {
		t.Fatalf("buildInbound failed for explicit XrayOptions.Dest: %v", err)
	}
	if inboundExplicit == nil {
		t.Fatal("expected non-nil inboundConfig")
	}

	// Case 3: Explicit XrayOptions.Dest already with port "127.0.0.1:9000"
	optsExplicitPort := &conf.Options{
		ListenIP: "0.0.0.0",
		XrayOptions: &conf.XrayOptions{
			Xver: 1,
			Dest: "127.0.0.1:9000",
		},
	}
	inboundExplicitPort, err := buildInbound(optsExplicitPort, nodeInfoAuto, "reality-explicit-port-test")
	if err != nil {
		t.Fatalf("buildInbound failed for explicit XrayOptions.Dest with port: %v", err)
	}
	if inboundExplicitPort == nil {
		t.Fatal("expected non-nil inboundConfig")
	}
}
