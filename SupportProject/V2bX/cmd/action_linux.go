package cmd

import (
	"fmt"
	"time"

	"github.com/tavut846/Rcon/common/exec"
	"github.com/spf13/cobra"
)

var (
	startCommand = cobra.Command{
		Use:   "start",
		Short: "Start rcon service",
		Run:   startHandle,
	}
	stopCommand = cobra.Command{
		Use:   "stop",
		Short: "Stop rcon service",
		Run:   stopHandle,
	}
	restartCommand = cobra.Command{
		Use:   "restart",
		Short: "Restart rcon service",
		Run:   restartHandle,
	}
	logCommand = cobra.Command{
		Use:   "log",
		Short: "Output rcon log",
		Run: func(_ *cobra.Command, _ []string) {
			exec.RunCommandStd("journalctl", "-u", "rcon.service", "-e", "--no-pager", "-f")
		},
	}
)

func init() {
	command.AddCommand(&startCommand)
	command.AddCommand(&stopCommand)
	command.AddCommand(&restartCommand)
	command.AddCommand(&logCommand)
}

func startHandle(_ *cobra.Command, _ []string) {
	r, err := checkRunning()
	if err != nil {
		fmt.Println(Err("check status error: ", err))
		fmt.Println(Err("rconå¯åŠ¨å¤±è´¥"))
		return
	}
	if r {
		fmt.Println(Ok("rconå·²è¿è¡Œï¼Œæ— éœ€å†æ¬¡å¯åŠ¨ï¼Œå¦‚éœ€é‡å¯è¯·é€‰æ‹©é‡å¯"))
	}
	_, err = exec.RunCommandByShell("systemctl start rcon.service")
	if err != nil {
		fmt.Println(Err("exec start cmd error: ", err))
		fmt.Println(Err("rconå¯åŠ¨å¤±è´¥"))
		return
	}
	time.Sleep(time.Second * 3)
	r, err = checkRunning()
	if err != nil {
		fmt.Println(Err("check status error: ", err))
		fmt.Println(Err("rconå¯åŠ¨å¤±è´¥"))
	}
	if !r {
		fmt.Println(Err("rconå¯èƒ½å¯åŠ¨å¤±è´¥ï¼Œè¯·ç¨åŽä½¿ç”¨ rcon log æŸ¥çœ‹æ—¥å¿—ä¿¡æ¯"))
		return
	}
	fmt.Println(Ok("rcon å¯åŠ¨æˆåŠŸï¼Œè¯·ä½¿ç”¨ rcon log æŸ¥çœ‹è¿è¡Œæ—¥å¿—"))
}

func stopHandle(_ *cobra.Command, _ []string) {
	_, err := exec.RunCommandByShell("systemctl stop rcon.service")
	if err != nil {
		fmt.Println(Err("exec stop cmd error: ", err))
		fmt.Println(Err("rconåœæ­¢å¤±è´¥"))
		return
	}
	time.Sleep(2 * time.Second)
	r, err := checkRunning()
	if err != nil {
		fmt.Println(Err("check status error:", err))
		fmt.Println(Err("rconåœæ­¢å¤±è´¥"))
		return
	}
	if r {
		fmt.Println(Err("rconåœæ­¢å¤±è´¥ï¼Œå¯èƒ½æ˜¯å› ä¸ºåœæ­¢æ—¶é—´è¶…è¿‡äº†ä¸¤ç§’ï¼Œè¯·ç¨åŽæŸ¥çœ‹æ—¥å¿—ä¿¡æ¯"))
		return
	}
	fmt.Println(Ok("rcon åœæ­¢æˆåŠŸ"))
}

func restartHandle(_ *cobra.Command, _ []string) {
	_, err := exec.RunCommandByShell("systemctl restart rcon.service")
	if err != nil {
		fmt.Println(Err("exec restart cmd error: ", err))
		fmt.Println(Err("rconé‡å¯å¤±è´¥"))
		return
	}
	r, err := checkRunning()
	if err != nil {
		fmt.Println(Err("check status error: ", err))
		fmt.Println(Err("rconé‡å¯å¤±è´¥"))
		return
	}
	if !r {
		fmt.Println(Err("rconå¯èƒ½å¯åŠ¨å¤±è´¥ï¼Œè¯·ç¨åŽä½¿ç”¨ rcon log æŸ¥çœ‹æ—¥å¿—ä¿¡æ¯"))
		return
	}
	fmt.Println(Ok("rconé‡å¯æˆåŠŸ"))
}

