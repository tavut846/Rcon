# rcon

[![](https://img.shields.io/badge/TgChat-UnOfficialV2Board%E4%BA%A4%E6%B5%81%E7%BE%A4-green)](https://t.me/unofficialV2board)
[![](https://img.shields.io/badge/TgChat-YuzukiProjects%E4%BA%A4%E6%B5%81%E7%BE%A4-blue)](https://t.me/YuzukiProjects)

A V2board node server based on multi core, modified from XrayR.  
ä¸€ä¸ªåŸºäºŽå¤šç§å†…æ ¸çš„V2boardèŠ‚ç‚¹æœåŠ¡ç«¯ï¼Œä¿®æ”¹è‡ªXrayRï¼Œæ”¯æŒV2ay,Trojan,Shadowsocksåè®®ã€‚

**æ³¨æ„ï¼š æœ¬é¡¹ç›®éœ€è¦æ­é…[ä¿®æ”¹ç‰ˆV2board](https://github.com/wyx2685/v2board)**

## ç‰¹ç‚¹

* æ°¸ä¹…å¼€æºä¸”å…è´¹ã€‚
* æ”¯æŒVmess/Vless, Trojanï¼Œ Shadowsocks, Hysteria1/2å¤šç§åè®®ã€‚
* æ”¯æŒVlesså’ŒXTLSç­‰æ–°ç‰¹æ€§ã€‚
* æ”¯æŒå•å®žä¾‹å¯¹æŽ¥å¤šèŠ‚ç‚¹ï¼Œæ— éœ€é‡å¤å¯åŠ¨ã€‚
* æ”¯æŒé™åˆ¶åœ¨çº¿IPã€‚
* æ”¯æŒé™åˆ¶Tcpè¿žæŽ¥æ•°ã€‚
* æ”¯æŒèŠ‚ç‚¹ç«¯å£çº§åˆ«ã€ç”¨æˆ·çº§åˆ«é™é€Ÿã€‚
* é…ç½®ç®€å•æ˜Žäº†ã€‚
* ä¿®æ”¹é…ç½®è‡ªåŠ¨é‡å¯å®žä¾‹ã€‚
* æ”¯æŒå¤šç§å†…æ ¸ï¼Œæ˜“æ‰©å±•ã€‚
* æ”¯æŒæ¡ä»¶ç¼–è¯‘ï¼Œå¯ä»…ç¼–è¯‘éœ€è¦çš„å†…æ ¸ã€‚

## åŠŸèƒ½ä»‹ç»

| åŠŸèƒ½        | v2ray | trojan | shadowsocks | hysteria1/2 |
|-----------|-------|--------|-------------|----------|
| è‡ªåŠ¨ç”³è¯·tlsè¯ä¹¦ | âˆš     | âˆš      | âˆš           | âˆš        |
| è‡ªåŠ¨ç»­ç­¾tlsè¯ä¹¦ | âˆš     | âˆš      | âˆš           | âˆš        |
| åœ¨çº¿äººæ•°ç»Ÿè®¡    | âˆš     | âˆš      | âˆš           | âˆš        |
| å®¡è®¡è§„åˆ™      | âˆš     | âˆš      | âˆš           | âˆš         |
| è‡ªå®šä¹‰DNS    | âˆš     | âˆš      | âˆš           | âˆš        |
| åœ¨çº¿IPæ•°é™åˆ¶   | âˆš     | âˆš      | âˆš           | âˆš        |
| è¿žæŽ¥æ•°é™åˆ¶     | âˆš     | âˆš      | âˆš           | âˆš         |
| è·¨èŠ‚ç‚¹IPæ•°é™åˆ¶  |âˆš      |âˆš       |âˆš            |âˆš          |
| æŒ‰ç…§ç”¨æˆ·é™é€Ÿ    | âˆš     | âˆš      | âˆš           | âˆš         |
| åŠ¨æ€é™é€Ÿ(æœªæµ‹è¯•) | âˆš     | âˆš      | âˆš           | âˆš         |

## TODO

- [ ] é‡æ–°å®žçŽ°åŠ¨æ€é™é€Ÿ
- [ ] å®Œå–„ä½¿ç”¨æ–‡æ¡£

## è½¯ä»¶å®‰è£…

### ä¸€é”®å®‰è£…

```
wget -N https://raw.githubusercontent.com/wyx2685/rcon-script/master/install.sh && bash install.sh
```

### æ‰‹åŠ¨å®‰è£…

[æ‰‹åŠ¨å®‰è£…æ•™ç¨‹](https://rcon.v-50.me/rcon/rcon-xia-zai-he-an-zhuang/install/manual)

## æž„å»º
``` bash
# é€šè¿‡-tagsé€‰é¡¹æŒ‡å®šè¦ç¼–è¯‘çš„å†…æ ¸ï¼Œ å¯é€‰ xrayï¼Œ sing, hysteria2
GOEXPERIMENT=jsonv2 go build -v -o build_assets/rcon -tags "sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" -trimpath -ldflags "-X 'github.com/FNode/Rcon/cmd.version=$version' -s -w -buildid="
```

## é…ç½®æ–‡ä»¶åŠè¯¦ç»†ä½¿ç”¨æ•™ç¨‹

[è¯¦ç»†ä½¿ç”¨æ•™ç¨‹](https://rcon.v-50.me/)

## å…è´£å£°æ˜Ž

* æ­¤é¡¹ç›®ç”¨äºŽæœ¬äººè‡ªç”¨ï¼Œå› æ­¤æœ¬äººä¸èƒ½ä¿è¯å‘åŽå…¼å®¹æ€§ã€‚
* ç”±äºŽæœ¬äººèƒ½åŠ›æœ‰é™ï¼Œä¸èƒ½ä¿è¯æ‰€æœ‰åŠŸèƒ½çš„å¯ç”¨æ€§ï¼Œå¦‚æžœå‡ºçŽ°é—®é¢˜è¯·åœ¨Issuesåé¦ˆã€‚
* æœ¬äººä¸å¯¹ä»»ä½•äººä½¿ç”¨æœ¬é¡¹ç›®é€ æˆçš„ä»»ä½•åŽæžœæ‰¿æ‹…è´£ä»»ã€‚
* æœ¬äººæ¯”è¾ƒå¤šå˜ï¼Œå› æ­¤æœ¬é¡¹ç›®å¯èƒ½ä¼šéšæƒ³æ³•æˆ–æ€è·¯çš„å˜åŠ¨éšæ€§æ›´æ”¹é¡¹ç›®ç»“æž„æˆ–å¤§è§„æ¨¡é‡æž„ä»£ç ï¼Œè‹¥ä¸èƒ½æŽ¥å—è¯·å‹¿ä½¿ç”¨ã€‚

## èµžåŠ©

[èµžåŠ©é“¾æŽ¥](https://v-50.me/)

## Thanks

* [Project X](https://github.com/XTLS/)
* [V2Fly](https://github.com/v2fly)
* [VNet-V2ray](https://github.com/ProxyPanel/VNet-V2ray)
* [Air-Universe](https://github.com/crossfw/Air-Universe)
* [XrayR](https://github.com/XrayR/XrayR)
* [sing-box](https://github.com/SagerNet/sing-box)

## Stars å¢žé•¿è®°å½•

[![Stargazers over time](https://starchart.cc/wyx2685/rcon.svg)](https://starchart.cc/wyx2685/rcon)

