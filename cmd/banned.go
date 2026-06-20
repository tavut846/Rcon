package cmd

import (
	"bufio"
	"fmt"
	"os"

	"github.com/tavut846/Rcon/conf"
	"github.com/spf13/cobra"
)

var (
	bannedConfig string
	tailLines    int
)

var bannedCommand = cobra.Command{
	Use:   "banned",
	Short: "View banned IP logs",
	Run:   bannedHandle,
	Args:  cobra.NoArgs,
}

func init() {
	bannedCommand.PersistentFlags().
		StringVarP(&bannedConfig, "config", "c",
			"/etc/rcon/config.json", "config file path")
	bannedCommand.PersistentFlags().
		IntVarP(&tailLines, "tail", "n",
			50, "number of log lines to show")
	command.AddCommand(&bannedCommand)
}

func bannedHandle(_ *cobra.Command, _ []string) {
	logPath := "banned.log"

	// Try to load log path from config
	c := conf.New()
	err := c.LoadFromPath(bannedConfig)
	if err == nil {
		// Try to find if any node has AntiScan log path configured
		for _, node := range c.NodeConfig {
			if node.Options.LimitConfig.EnableAntiScan && node.Options.LimitConfig.AntiScanConfig != nil && node.Options.LimitConfig.AntiScanConfig.LogPath != "" {
				logPath = node.Options.LimitConfig.AntiScanConfig.LogPath
				break
			}
		}
	}

	file, err := os.Open(logPath)
	if err != nil {
		fmt.Println(Err("Failed to open banned log file: ", err))
		return
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		fmt.Println(Err("Error reading log file: ", err))
		return
	}

	start := 0
	if len(lines) > tailLines {
		start = len(lines) - tailLines
	}

	fmt.Println(Ok("=== Banned IP Logs (Last ", len(lines)-start, " entries) ==="))
	for i := start; i < len(lines); i++ {
		fmt.Println(lines[i])
	}
}
