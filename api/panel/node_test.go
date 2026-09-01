package panel

import (
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


