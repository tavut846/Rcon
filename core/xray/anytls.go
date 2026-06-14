package xray

import (
	"github.com/tavut846/Rcon/api/panel"
	"github.com/tavut846/Rcon/common/format"
	"github.com/xtls/xray-core/common/protocol"
	"github.com/xtls/xray-core/common/serial"
	"github.com/xtls/xray-core/proxy/anytls"
)

func buildAnyTLSUsers(tag string, userInfo []panel.UserInfo) []*protocol.User {
	users := make([]*protocol.User, len(userInfo))
	for i := range userInfo {
		users[i] = buildAnyTLSUser(tag, &userInfo[i])
	}
	return users
}

func buildAnyTLSUser(tag string, userInfo *panel.UserInfo) *protocol.User {
	return &protocol.User{
		Level: 0,
		Email: format.UserTag(tag, userInfo.Uuid),
		Account: serial.ToTypedMessage(&anytls.Account{
			Password: userInfo.Uuid,
		}),
	}
}
