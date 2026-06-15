package node

import (
	"encoding/json"
	"fmt"
	"os"
	"sync"

	"github.com/tavut846/Rcon/api/panel"
)

const nodeStatusFile = "/etc/rcon/node_status.json"

type NodeStatusEntry struct {
	NodeID              int    `json:"node_id"`
	NodeType            string `json:"node_type"`
	Tag                 string `json:"tag"`
	Port                int    `json:"port"`
	Network             string `json:"network"`
	Security            string `json:"security"`
	HasDownloadSettings bool   `json:"has_download_settings"`
	DownloadDest        string `json:"download_dest,omitempty"`
}

var (
	statusMu      sync.Mutex
	allNodeStatus = map[int]*NodeStatusEntry{}
)

func (c *Controller) updateStatusFile(node *panel.NodeInfo) {
	entry := buildStatusEntry(c.tag, node)

	statusMu.Lock()
	defer statusMu.Unlock()
	allNodeStatus[node.Id] = entry
	writeStatusFile()
}

func (c *Controller) removeFromStatusFile(nodeID int) {
	statusMu.Lock()
	defer statusMu.Unlock()
	delete(allNodeStatus, nodeID)
	writeStatusFile()
}

func buildStatusEntry(tag string, node *panel.NodeInfo) *NodeStatusEntry {
	entry := &NodeStatusEntry{
		NodeID:   node.Id,
		NodeType: node.Type,
		Tag:      tag,
	}
	if node.Common != nil {
		entry.Port = node.Common.ServerPort
	}
	switch node.Security {
	case panel.Tls:
		entry.Security = "tls"
	case panel.Reality:
		entry.Security = "reality"
	default:
		entry.Security = "none"
	}
	if node.VAllss != nil {
		entry.Network = node.VAllss.Network
		if len(node.VAllss.NetworkSettings) > 0 {
			var ns struct {
				DownloadSettings *struct {
					Address string `json:"address"`
					Port    int    `json:"port"`
				} `json:"downloadSettings"`
			}
			if json.Unmarshal(node.VAllss.NetworkSettings, &ns) == nil && ns.DownloadSettings != nil {
				entry.HasDownloadSettings = true
				entry.DownloadDest = fmt.Sprintf("%s:%d", ns.DownloadSettings.Address, ns.DownloadSettings.Port)
			}
		}
	} else if node.Trojan != nil {
		entry.Network = node.Trojan.Network
		if entry.Network == "" {
			entry.Network = "tcp"
		}
	} else if node.Shadowsocks != nil || node.AnyTLS != nil {
		entry.Network = "tcp"
	}
	return entry
}

func writeStatusFile() {
	entries := make([]*NodeStatusEntry, 0, len(allNodeStatus))
	for _, v := range allNodeStatus {
		entries = append(entries, v)
	}
	data, err := json.MarshalIndent(entries, "", "  ")
	if err != nil {
		return
	}
	_ = os.WriteFile(nodeStatusFile, data, 0644)
}
