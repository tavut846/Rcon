package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/FNode/Rcon/common/exec"
	"github.com/spf13/cobra"
)

var targetVersion string

var (
	updateCommand = cobra.Command{
		Use:   "update",
		Short: "Update rcon version",
		Run: func(_ *cobra.Command, _ []string) {
			exec.RunCommandStd("bash",
				"<(curl -Ls https://raw.githubusercontents.com/InazumaV/rcon-script/master/install.sh)",
				targetVersion)
		},
		Args: cobra.NoArgs,
	}
	uninstallCommand = cobra.Command{
		Use:   "uninstall",
		Short: "Uninstall rcon",
		Run:   uninstallHandle,
	}
)

func init() {
	updateCommand.PersistentFlags().StringVar(&targetVersion, "version", "", "update target version")
	command.AddCommand(&updateCommand)
	command.AddCommand(&uninstallCommand)
}

func uninstallHandle(_ *cobra.Command, _ []string) {
	var yes string
	fmt.Println(Warn("ç¡®å®šè¦å¸è½½ rcon å—?(Y/n)"))
	fmt.Scan(&yes)
	if strings.ToLower(yes) != "y" {
		fmt.Println("å·²å–æ¶ˆå¸è½½")
	}
	_, err := exec.RunCommandByShell("systemctl stop rcon&&systemctl disable rcon")
	if err != nil {
		fmt.Println(Err("exec cmd error: ", err))
		fmt.Println(Err("å¸è½½å¤±è´¥"))
		return
	}
	_ = os.RemoveAll("/etc/systemd/system/rcon.service")
	_ = os.RemoveAll("/etc/rcon/")
	_ = os.RemoveAll("/usr/local/rcon/")
	_ = os.RemoveAll("/bin/rcon")
	_, err = exec.RunCommandByShell("systemctl daemon-reload&&systemctl reset-failed")
	if err != nil {
		fmt.Println(Err("exec cmd error: ", err))
		fmt.Println(Err("å¸è½½å¤±è´¥"))
		return
	}
	fmt.Println(Ok("å¸è½½æˆåŠŸ"))
}

