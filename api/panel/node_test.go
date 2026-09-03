package panel

import (
	"encoding/json"
	"log"
	"testing"

	"github.com/tavut846/Rcon/conf"
)

var client *Client

func init() {
	c, err := New(&conf.ApiConfig{
		APIHost:  "http://127.0.0.1",
		Key:      "token",
		NodeType: "V2ray",
		NodeID:   1,
	})
	if err != nil {
		log.Panic(err)
	}
	client = c
}

func TestClient_GetNodeInfo(t *testing.T) {
	log.Println(client.GetNodeInfo())
	log.Println(client.GetNodeInfo())
}

func TestClient_ReportUserTraffic(t *testing.T) {
	log.Println(client.ReportUserTraffic([]UserTraffic{
		{
			UID:      10372,
			Upload:   1000,
			Download: 1000,
		},
	}))
}

func TestAnyTLSNode_UnmarshalJSON(t *testing.T) {
	// 1. Test with array padding_scheme
	jsonArray := []byte(`{
		"host": "example.com",
		"server_port": 443,
		"tls": 1,
		"network": "ws",
		"padding_scheme": ["stop=8", "0=30-30", "1=100-400"],
		"tls_settings": {
			"server_name": "example.com"
		}
	}`)
	var node1 AnyTLSNode
	if err := json.Unmarshal(jsonArray, &node1); err != nil {
		t.Fatalf("failed to unmarshal AnyTLSNode with array padding_scheme: %v", err)
	}
	if len(node1.PaddingScheme) != 3 || node1.PaddingScheme[0] != "stop=8" {
		t.Fatalf("unexpected padding scheme: %+v", node1.PaddingScheme)
	}
	if node1.Network != "ws" || node1.Tls != 1 {
		t.Fatalf("unexpected network or tls: %s, %d", node1.Network, node1.Tls)
	}

	// 2. Test with multiline string padding_scheme
	jsonString := []byte(`{
		"host": "example.com",
		"server_port": 443,
		"tls": 2,
		"network": "tcp",
		"padding_scheme": "stop=8\n0=30-30",
		"tls_settings": {
			"server_name": "reality.example.com",
			"dest": "dest.com",
			"short_id": "abcd1234",
			"private_key": "privkey"
		}
	}`)
	var node2 AnyTLSNode
	if err := json.Unmarshal(jsonString, &node2); err != nil {
		t.Fatalf("failed to unmarshal AnyTLSNode with string padding_scheme: %v", err)
	}
	if len(node2.PaddingScheme) != 2 || node2.PaddingScheme[1] != "0=30-30" {
		t.Fatalf("unexpected padding scheme: %+v", node2.PaddingScheme)
	}
	if node2.Tls != 2 || node2.TlsSettings.ShortId != "abcd1234" {
		t.Fatalf("unexpected tls settings: %+v", node2.TlsSettings)
	}
}

func TestTlsSettings_Xver(t *testing.T) {
	// Test int xver
	jsonInt := []byte(`{"server_name": "example.com", "xver": 1}`)
	var s1 TlsSettings
	if err := json.Unmarshal(jsonInt, &s1); err != nil {
		t.Fatalf("failed to unmarshal int xver: %v", err)
	}
	if uint64(s1.Xver) != 1 {
		t.Fatalf("expected xver 1, got %d", s1.Xver)
	}

	// Test string xver
	jsonStr := []byte(`{"server_name": "example.com", "xver": "2"}`)
	var s2 TlsSettings
	if err := json.Unmarshal(jsonStr, &s2); err != nil {
		t.Fatalf("failed to unmarshal string xver: %v", err)
	}
	if uint64(s2.Xver) != 2 {
		t.Fatalf("expected xver 2, got %d", s2.Xver)
	}

	// Test omitted xver
	jsonNone := []byte(`{"server_name": "example.com"}`)
	var s3 TlsSettings
	if err := json.Unmarshal(jsonNone, &s3); err != nil {
		t.Fatalf("failed to unmarshal omitted xver: %v", err)
	}
	if uint64(s3.Xver) != 0 {
		t.Fatalf("expected xver 0, got %d", s3.Xver)
	}
}

func TestTlsSettings_ServerNamesAndDest(t *testing.T) {
	// Test server_names array and dest from dashboard
	jsonData := []byte(`{
		"server_name": "fallback.com",
		"server_names": ["in001.666633.best", "in002.666633.best"],
		"dest": "127.0.0.1",
		"server_port": "8001",
		"short_ids": ["abcdef12", "34567890"]
	}`)
	var s TlsSettings
	if err := json.Unmarshal(jsonData, &s); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}
	if s.Dest != "127.0.0.1" {
		t.Fatalf("expected dest 127.0.0.1, got %s", s.Dest)
	}
	if s.PrimaryServerName() != "in001.666633.best" {
		t.Fatalf("expected primary server name in001.666633.best, got %s", s.PrimaryServerName())
	}
	if len(s.EffectiveServerNames()) != 2 {
		t.Fatalf("expected 2 server names, got %d", len(s.EffectiveServerNames()))
	}
	if len(s.EffectiveShortIds()) != 2 {
		t.Fatalf("expected 2 short ids, got %d", len(s.EffectiveShortIds()))
	}
}



