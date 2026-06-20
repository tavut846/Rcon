package conf

type LimitConfig struct {
	EnableRealtime          bool                     `json:"EnableRealtime"`
	SpeedLimit              int                      `json:"SpeedLimit"`
	IPLimit                 int                      `json:"DeviceLimit"`
	ConnLimit               int                      `json:"ConnLimit"`
	EnableIpRecorder        bool                     `json:"EnableIpRecorder"`
	IpRecorderConfig        *IpReportConfig          `json:"IpRecorderConfig"`
	EnableDynamicSpeedLimit bool                     `json:"EnableDynamicSpeedLimit"`
	DynamicSpeedLimitConfig *DynamicSpeedLimitConfig `json:"DynamicSpeedLimitConfig"`
	EnableAntiScan          bool                     `json:"EnableAntiScan"`
	AntiScanConfig          *AntiScanConfig          `json:"AntiScanConfig"`
}

type AntiScanConfig struct {
	Threshold   int    `json:"Threshold"`
	Window      int    `json:"Window"`
	BanDuration int    `json:"BanDuration"`
	LogPath     string `json:"LogPath"`
}


type RecorderConfig struct {
	Url     string `json:"Url"`
	Token   string `json:"Token"`
	Timeout int    `json:"Timeout"`
}

type RedisConfig struct {
	Address  string `json:"Address"`
	Password string `json:"Password"`
	Db       int    `json:"Db"`
	Expiry   int    `json:"Expiry"`
}

type IpReportConfig struct {
	Periodic       int             `json:"Periodic"`
	Type           string          `json:"Type"`
	RecorderConfig *RecorderConfig `json:"RecorderConfig"`
	RedisConfig    *RedisConfig    `json:"RedisConfig"`
	EnableIpSync   bool            `json:"EnableIpSync"`
}

type DynamicSpeedLimitConfig struct {
	Periodic   int   `json:"Periodic"`
	Traffic    int64 `json:"Traffic"`
	SpeedLimit int   `json:"SpeedLimit"`
	ExpireTime int   `json:"ExpireTime"`
}
