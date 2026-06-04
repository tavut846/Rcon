#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}é”™è¯¯: ${plain} å¿…é¡»ä½¿ç”¨rootç”¨æˆ·è¿è¡Œæ­¤è„šæœ¬ï¼\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "alpine"; then
    release="alpine"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux"; then
    release="centos"
elif cat /proc/version | grep -Eqi "arch"; then
    release="arch"
else
    echo -e "${red}æœªæ£€æµ‹åˆ°ç³»ç»Ÿç‰ˆæœ¬ï¼Œè¯·è”ç³»è„šæœ¬ä½œè€…ï¼${plain}\n" && exit 1
fi

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}è¯·ä½¿ç”¨ CentOS 7 æˆ–æ›´é«˜ç‰ˆæœ¬çš„ç³»ç»Ÿï¼${plain}\n" && exit 1
    fi
    if [[ ${os_version} -eq 7 ]]; then
        echo -e "${red}æ³¨æ„ï¼š CentOS 7 æ— æ³•ä½¿ç”¨hysteria1/2åè®®ï¼${plain}\n"
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}è¯·ä½¿ç”¨ Ubuntu 16 æˆ–æ›´é«˜ç‰ˆæœ¬çš„ç³»ç»Ÿï¼${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}è¯·ä½¿ç”¨ Debian 8 æˆ–æ›´é«˜ç‰ˆæœ¬çš„ç³»ç»Ÿï¼${plain}\n" && exit 1
    fi
fi

# æ£€æŸ¥ç³»ç»Ÿæ˜¯å¦æœ‰ IPv6 åœ°å€
check_ipv6_support() {
    if ip -6 addr | grep -q "inet6"; then
        echo "1"  # æ”¯æŒ IPv6
    else
        echo "0"  # ä¸æ”¯æŒ IPv6
    fi
}

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -rp "$1 [é»˜è®¤$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -rp "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "æ˜¯å¦é‡å¯rcon" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}æŒ‰å›žè½¦è¿”å›žä¸»èœå•: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/FNode/Rcon/master/rcon.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -n -e "è¾“å…¥æŒ‡å®šç‰ˆæœ¬(é»˜è®¤æœ€æ–°ç‰ˆ): " && read version
    else
        version=$2
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/wyx2685/rcon-script/master/install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}æ›´æ–°å®Œæˆï¼Œå·²è‡ªåŠ¨é‡å¯ rconï¼Œè¯·ä½¿ç”¨ rcon log æŸ¥çœ‹è¿è¡Œæ—¥å¿—${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "rconåœ¨ä¿®æ”¹é…ç½®åŽä¼šè‡ªåŠ¨å°è¯•é‡å¯"
    vi /etc/rcon/config.json
    sleep 2
    restart
    check_status
    case $? in
        0)
            echo -e "rconçŠ¶æ€: ${green}å·²è¿è¡Œ${plain}"
            ;;
        1)
            echo -e "æ£€æµ‹åˆ°æ‚¨æœªå¯åŠ¨rconæˆ–rconè‡ªåŠ¨é‡å¯å¤±è´¥ï¼Œæ˜¯å¦æŸ¥çœ‹æ—¥å¿—ï¼Ÿ[Y/n]" && echo
            read -e -rp "(é»˜è®¤: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "rconçŠ¶æ€: ${red}æœªå®‰è£…${plain}"
    esac
}

uninstall() {
    confirm "ç¡®å®šè¦å¸è½½ rcon å—?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    if [[ x"${release}" == x"alpine" ]]; then
        service rcon stop
        rc-update del rcon
        rm /etc/init.d/rcon -f
    else
        systemctl stop rcon
        systemctl disable rcon
        rm /etc/systemd/system/rcon.service -f
        systemctl daemon-reload
        systemctl reset-failed
    fi
    rm /etc/rcon/ -rf
    rm /usr/local/rcon/ -rf

    echo ""
    echo -e "å¸è½½æˆåŠŸï¼Œå¦‚æžœä½ æƒ³åˆ é™¤æ­¤è„šæœ¬ï¼Œåˆ™é€€å‡ºè„šæœ¬åŽè¿è¡Œ ${green}rm /usr/bin/rcon -f${plain} è¿›è¡Œåˆ é™¤"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}rconå·²è¿è¡Œï¼Œæ— éœ€å†æ¬¡å¯åŠ¨ï¼Œå¦‚éœ€é‡å¯è¯·é€‰æ‹©é‡å¯${plain}"
    else
        if [[ x"${release}" == x"alpine" ]]; then
            service rcon start
        else
            systemctl start rcon
        fi
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}rcon å¯åŠ¨æˆåŠŸï¼Œè¯·ä½¿ç”¨ rcon log æŸ¥çœ‹è¿è¡Œæ—¥å¿—${plain}"
        else
            echo -e "${red}rconå¯èƒ½å¯åŠ¨å¤±è´¥ï¼Œè¯·ç¨åŽä½¿ç”¨ rcon log æŸ¥çœ‹æ—¥å¿—ä¿¡æ¯${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    if [[ x"${release}" == x"alpine" ]]; then
        service rcon stop
    else
        systemctl stop rcon
    fi
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}rcon åœæ­¢æˆåŠŸ${plain}"
    else
        echo -e "${red}rconåœæ­¢å¤±è´¥ï¼Œå¯èƒ½æ˜¯å› ä¸ºåœæ­¢æ—¶é—´è¶…è¿‡äº†ä¸¤ç§’ï¼Œè¯·ç¨åŽæŸ¥çœ‹æ—¥å¿—ä¿¡æ¯${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    if [[ x"${release}" == x"alpine" ]]; then
        service rcon restart
    else
        systemctl restart rcon
    fi
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}rcon é‡å¯æˆåŠŸï¼Œè¯·ä½¿ç”¨ rcon log æŸ¥çœ‹è¿è¡Œæ—¥å¿—${plain}"
    else
        echo -e "${red}rconå¯èƒ½å¯åŠ¨å¤±è´¥ï¼Œè¯·ç¨åŽä½¿ç”¨ rcon log æŸ¥çœ‹æ—¥å¿—ä¿¡æ¯${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    if [[ x"${release}" == x"alpine" ]]; then
        service rcon status
    else
        systemctl status rcon --no-pager -l
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    if [[ x"${release}" == x"alpine" ]]; then
        rc-update add rcon
    else
        systemctl enable rcon
    fi
    if [[ $? == 0 ]]; then
        echo -e "${green}rcon è®¾ç½®å¼€æœºè‡ªå¯æˆåŠŸ${plain}"
    else
        echo -e "${red}rcon è®¾ç½®å¼€æœºè‡ªå¯å¤±è´¥${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    if [[ x"${release}" == x"alpine" ]]; then
        rc-update del rcon
    else
        systemctl disable rcon
    fi
    if [[ $? == 0 ]]; then
        echo -e "${green}rcon å–æ¶ˆå¼€æœºè‡ªå¯æˆåŠŸ${plain}"
    else
        echo -e "${red}rcon å–æ¶ˆå¼€æœºè‡ªå¯å¤±è´¥${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    if [[ x"${release}" == x"alpine" ]]; then
        echo -e "${red}alpineç³»ç»Ÿæš‚ä¸æ”¯æŒæ—¥å¿—æŸ¥çœ‹${plain}\n" && exit 1
    else
        journalctl -u rcon.service -e --no-pager -f
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh)
}

update_shell() {
    wget -O /usr/bin/rcon -N --no-check-certificate https://raw.githubusercontent.com/wyx2685/rcon-script/master/rcon.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}ä¸‹è½½è„šæœ¬å¤±è´¥ï¼Œè¯·æ£€æŸ¥æœ¬æœºèƒ½å¦è¿žæŽ¥ Github${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/rcon
        echo -e "${green}å‡çº§è„šæœ¬æˆåŠŸï¼Œè¯·é‡æ–°è¿è¡Œè„šæœ¬${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /usr/local/rcon/rcon ]]; then
        return 2
    fi
    if [[ x"${release}" == x"alpine" ]]; then
        temp=$(service rcon status | awk '{print $3}')
        if [[ x"${temp}" == x"started" ]]; then
            return 0
        else
            return 1
        fi
    else
        temp=$(systemctl status rcon | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
        if [[ x"${temp}" == x"running" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

check_enabled() {
    if [[ x"${release}" == x"alpine" ]]; then
        temp=$(rc-update show | grep rcon)
        if [[ x"${temp}" == x"" ]]; then
            return 1
        else
            return 0
        fi
    else
        temp=$(systemctl is-enabled rcon)
        if [[ x"${temp}" == x"enabled" ]]; then
            return 0
        else
            return 1;
        fi
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}rconå·²å®‰è£…ï¼Œè¯·ä¸è¦é‡å¤å®‰è£…${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}è¯·å…ˆå®‰è£…rcon${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "rconçŠ¶æ€: ${green}å·²è¿è¡Œ${plain}"
            show_enable_status
            ;;
        1)
            echo -e "rconçŠ¶æ€: ${yellow}æœªè¿è¡Œ${plain}"
            show_enable_status
            ;;
        2)
            echo -e "rconçŠ¶æ€: ${red}æœªå®‰è£…${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "æ˜¯å¦å¼€æœºè‡ªå¯: ${green}æ˜¯${plain}"
    else
        echo -e "æ˜¯å¦å¼€æœºè‡ªå¯: ${red}å¦${plain}"
    fi
}

generate_x25519_key() {
    echo -n "æ­£åœ¨ç”Ÿæˆ x25519 å¯†é’¥ï¼š"
    /usr/local/rcon/rcon x25519
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_rcon_version() {
    echo -n "rcon ç‰ˆæœ¬ï¼š"
    /usr/local/rcon/rcon version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

add_node_config() {
    echo -e "${green}è¯·é€‰æ‹©èŠ‚ç‚¹æ ¸å¿ƒç±»åž‹ï¼š${plain}"
    echo -e "${green}1. xray${plain}"
    read -rp "è¯·è¾“å…¥ï¼š" core_type
    if [ "$core_type" == "1" ]; then
        core="xray"
        core_xray=true
    else
        echo "æ— æ•ˆçš„é€‰æ‹©ã€‚è¯·é€‰æ‹© 1ã€‚"
        continue
    fi
    while true; do
        read -rp "è¯·è¾“å…¥èŠ‚ç‚¹Node IDï¼š" NodeID
        # åˆ¤æ–­NodeIDæ˜¯å¦ä¸ºæ­£æ•´æ•°
        if [[ "$NodeID" =~ ^[0-9]+$ ]]; then
            break  # è¾“å…¥æ­£ç¡®ï¼Œé€€å‡ºå¾ªçŽ¯
        else
            echo "é”™è¯¯ï¼šè¯·è¾“å…¥æ­£ç¡®çš„æ•°å­—ä½œä¸ºNode IDã€‚"
        fi
    done

    if [ "$core_hysteria2" = true ] && [ "$core_xray" = false ] && [ "$core_sing" = false ]; then
        NodeType="hysteria2"
    else
        echo -e "${yellow}è¯·é€‰æ‹©èŠ‚ç‚¹ä¼ è¾“åè®®ï¼š${plain}"
        echo -e "${green}1. Shadowsocks${plain}"
        echo -e "${green}2. Vless${plain}"
        echo -e "${green}3. Vmess${plain}"
        echo -e "${green}6. Trojan${plain}"  
        read -rp "è¯·è¾“å…¥ï¼š" NodeType
        case "$NodeType" in
            1 ) NodeType="shadowsocks" ;;
            2 ) NodeType="vless" ;;
            3 ) NodeType="vmess" ;;
            6 ) NodeType="trojan" ;;
            * ) NodeType="shadowsocks" ;;
        esac
    fi
    fastopen=true
    isreality=""
    istls=""
    if [ "$NodeType" == "vless" ]; then
        read -rp "è¯·é€‰æ‹©æ˜¯å¦ä¸ºrealityèŠ‚ç‚¹ï¼Ÿ(y/n)" isreality
    fi

    if [[ "$NodeType" != "shadowsocks" && "$isreality" != "y" && "$isreality" != "Y" ]]; then
        read -rp "è¯·é€‰æ‹©æ˜¯å¦è¿›è¡ŒTLSé…ç½®ï¼Ÿ(y/n)" istls
    fi

    certmode="none"
    certdomain="example.com"
    if [[ "$isreality" != "y" && "$isreality" != "Y" && ( "$istls" == "y" || "$istls" == "Y" ) ]]; then
        echo -e "${yellow}è¯·é€‰æ‹©è¯ä¹¦ç”³è¯·æ¨¡å¼ï¼š${plain}"
        echo -e "${green}1. httpæ¨¡å¼è‡ªåŠ¨ç”³è¯·ï¼ŒèŠ‚ç‚¹åŸŸåå·²æ­£ç¡®è§£æž${plain}"
        echo -e "${green}2. dnsæ¨¡å¼è‡ªåŠ¨ç”³è¯·ï¼Œéœ€å¡«å…¥æ­£ç¡®åŸŸåæœåŠ¡å•†APIå‚æ•°${plain}"
        echo -e "${green}3. selfæ¨¡å¼ï¼Œè‡ªç­¾è¯ä¹¦æˆ–æä¾›å·²æœ‰è¯ä¹¦æ–‡ä»¶${plain}"
        read -rp "è¯·è¾“å…¥ï¼š" certmode
        case "$certmode" in
            1 ) certmode="http" ;;
            2 ) certmode="dns" ;;
            3 ) certmode="self" ;;
        esac
        read -rp "è¯·è¾“å…¥èŠ‚ç‚¹è¯ä¹¦åŸŸå(example.com)ï¼š" certdomain
        if [ "$certmode" != "http" ]; then
            echo -e "${red}è¯·æ‰‹åŠ¨ä¿®æ”¹é…ç½®æ–‡ä»¶åŽé‡å¯rconï¼${plain}"
        fi
    fi
    ipv6_support=$(check_ipv6_support)
    listen_ip="0.0.0.0"
    if [ "$ipv6_support" -eq 1 ]; then
        listen_ip="::"
    fi
    node_config=""
    if [ "$core_type" == "1" ]; then 
    node_config=$(cat <<EOF
{
            "Core": "$core",
            "ApiHost": "$ApiHost",
            "ApiKey": "$ApiKey",
            "NodeID": $NodeID,
            "NodeType": "$NodeType",
            "Timeout": 30,
            "ListenIP": "0.0.0.0",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 200,
            "MinReportTraffic": 0,
            "EnableProxyProtocol": false,
            "EnableUot": true,
            "EnableTFO": true,
            "DNSType": "UseIPv4",
            "CertConfig": {
                "CertMode": "$certmode",
                "RejectUnknownSni": false,
                "CertDomain": "$certdomain",
                "CertFile": "/etc/rcon/fullchain.cer",
                "KeyFile": "/etc/rcon/cert.key",
                "Email": "rcon@github.com",
                "Provider": "cloudflare",
                "DNSEnv": {
                    "EnvName": "env1"
                }
            }
        },
EOF
)
    elif [ "$core_type" == "2" ]; then
    node_config=$(cat <<EOF
{
            "Core": "$core",
            "ApiHost": "$ApiHost",
            "ApiKey": "$ApiKey",
            "NodeID": $NodeID,
            "NodeType": "$NodeType",
            "Timeout": 30,
            "ListenIP": "$listen_ip",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 200,
            "MinReportTraffic": 0,
            "TCPFastOpen": $fastopen,
            "SniffEnabled": true,
            "CertConfig": {
                "CertMode": "$certmode",
                "RejectUnknownSni": false,
                "CertDomain": "$certdomain",
                "CertFile": "/etc/rcon/fullchain.cer",
                "KeyFile": "/etc/rcon/cert.key",
                "Email": "rcon@github.com",
                "Provider": "cloudflare",
                "DNSEnv": {
                    "EnvName": "env1"
                }
            }
        },
EOF
)
    elif [ "$core_type" == "3" ]; then
    node_config=$(cat <<EOF
{
            "Core": "$core",
            "ApiHost": "$ApiHost",
            "ApiKey": "$ApiKey",
            "NodeID": $NodeID,
            "NodeType": "$NodeType",
            "Hysteria2ConfigPath": "/etc/rcon/hy2config.yaml",
            "Timeout": 30,
            "ListenIP": "",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 200,
            "MinReportTraffic": 0,
            "CertConfig": {
                "CertMode": "$certmode",
                "RejectUnknownSni": false,
                "CertDomain": "$certdomain",
                "CertFile": "/etc/rcon/fullchain.cer",
                "KeyFile": "/etc/rcon/cert.key",
                "Email": "rcon@github.com",
                "Provider": "cloudflare",
                "DNSEnv": {
                    "EnvName": "env1"
                }
            }
        },
EOF
)
    fi
    nodes_config+=("$node_config")
}

generate_config_file() {
    echo -e "${yellow}rcon é…ç½®æ–‡ä»¶ç”Ÿæˆå‘å¯¼${plain}"
    echo -e "${red}è¯·é˜…è¯»ä»¥ä¸‹æ³¨æ„äº‹é¡¹ï¼š${plain}"
    echo -e "${red}1. ç›®å‰è¯¥åŠŸèƒ½æ­£å¤„æµ‹è¯•é˜¶æ®µ${plain}"
    echo -e "${red}2. ç”Ÿæˆçš„é…ç½®æ–‡ä»¶ä¼šä¿å­˜åˆ° /etc/rcon/config.json${plain}"
    echo -e "${red}3. åŽŸæ¥çš„é…ç½®æ–‡ä»¶ä¼šä¿å­˜åˆ° /etc/rcon/config.json.bak${plain}"
    echo -e "${red}4. ç›®å‰ä»…éƒ¨åˆ†æ”¯æŒTLS${plain}"
    echo -e "${red}5. ä½¿ç”¨æ­¤åŠŸèƒ½ç”Ÿæˆçš„é…ç½®æ–‡ä»¶ä¼šè‡ªå¸¦å®¡è®¡ï¼Œç¡®å®šç»§ç»­ï¼Ÿ(y/n)${plain}"
    read -rp "è¯·è¾“å…¥ï¼š" continue_prompt
    if [[ "$continue_prompt" =~ ^[Nn][Oo]? ]]; then
        exit 0
    fi
    
    nodes_config=()
    first_node=true
    core_xray=false
    fixed_api_info=false
    check_api=false
    
    while true; do
        if [ "$first_node" = true ]; then
            read -rp "è¯·è¾“å…¥æœºåœºç½‘å€(https://example.com)ï¼š" ApiHost
            read -rp "è¯·è¾“å…¥é¢æ¿å¯¹æŽ¥API Keyï¼š" ApiKey
            read -rp "æ˜¯å¦è®¾ç½®å›ºå®šçš„æœºåœºç½‘å€å’ŒAPI Keyï¼Ÿ(y/n)" fixed_api
            if [ "$fixed_api" = "y" ] || [ "$fixed_api" = "Y" ]; then
                fixed_api_info=true
                echo -e "${red}æˆåŠŸå›ºå®šåœ°å€${plain}"
            fi
            first_node=false
            add_node_config
        else
            read -rp "æ˜¯å¦ç»§ç»­æ·»åŠ èŠ‚ç‚¹é…ç½®ï¼Ÿ(å›žè½¦ç»§ç»­ï¼Œè¾“å…¥næˆ–noé€€å‡º)" continue_adding_node
            if [[ "$continue_adding_node" =~ ^[Nn][Oo]? ]]; then
                break
            elif [ "$fixed_api_info" = false ]; then
                read -rp "è¯·è¾“å…¥æœºåœºç½‘å€ï¼š" ApiHost
                read -rp "è¯·è¾“å…¥é¢æ¿å¯¹æŽ¥API Keyï¼š" ApiKey
            fi
            add_node_config
        fi
    done

    # åˆå§‹åŒ–æ ¸å¿ƒé…ç½®æ•°ç»„
    cores_config="["

    # æ£€æŸ¥å¹¶æ·»åŠ xrayæ ¸å¿ƒé…ç½®
    if [ "$core_xray" = true ]; then
        cores_config+="
    {
        \"Type\": \"xray\",
        \"Log\": {
            \"Level\": \"error\",
            \"ErrorPath\": \"/etc/rcon/error.log\"
        },
        \"OutboundConfigPath\": \"/etc/rcon/custom_outbound.json\",
        \"RouteConfigPath\": \"/etc/rcon/route.json\"
    }"
    fi

    # å…³é—­æ•°ç»„
    cores_config+="]"

    # åˆ‡æ¢åˆ°é…ç½®æ–‡ä»¶ç›®å½•
    cd /etc/rcon
    
    # å¤‡ä»½æ—§çš„é…ç½®æ–‡ä»¶
    mv config.json config.json.bak
    nodes_config_str="${nodes_config[*]}"
    formatted_nodes_config="${nodes_config_str%,}"

    # åˆ›å»º config.json æ–‡ä»¶
    cat <<EOF > /etc/rcon/config.json
{
    "Log": {
        "Level": "error",
        "Output": ""
    },
    "Cores": $cores_config,
    "Nodes": [$formatted_nodes_config]
}
EOF
    
    # åˆ›å»º custom_outbound.json æ–‡ä»¶
    cat <<EOF > /etc/rcon/custom_outbound.json
    [
        {
            "tag": "IPv4_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv4v6"
            }
        },
        {
            "tag": "IPv6_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv6"
            }
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
EOF
    
    # åˆ›å»º route.json æ–‡ä»¶
    cat <<EOF > /etc/rcon/route.json
    {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "geoip:private"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "domain": [
                    "regexp:(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
                    "regexp:(.+.|^)(360|so).(cn|com)",
                    "regexp:(Subject|HELO|SMTP)",
                    "regexp:(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
                    "regexp:(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
                    "regexp:(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
                    "regexp:(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
                    "regexp:(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
                    "regexp:(.+.|^)(360).(cn|com|net)",
                    "regexp:(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
                    "regexp:(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
                    "regexp:(.*.||)(netvigator|torproject).(com|cn|net|org)",
                    "regexp:(..||)(visa|mycard|gash|beanfun|bank).",
                    "regexp:(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
                    "regexp:(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
                    "regexp:(.*.||)(mycard).(com|tw)",
                    "regexp:(.*.||)(gash).(com|tw)",
                    "regexp:(.bank.)",
                    "regexp:(.*.||)(pincong).(rocks)",
                    "regexp:(.*.||)(taobao).(com)",
                    "regexp:(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
                    "regexp:(flows|miaoko).(pages).(dev)"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "127.0.0.1/32",
                    "10.0.0.0/8",
                    "fc00::/7",
                    "fe80::/10",
                    "172.16.0.0/12"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "protocol": [
                    "bittorrent"
                ]
            }
        ]
    }
EOF

    echo -e "${green}rcon é…ç½®æ–‡ä»¶ç”Ÿæˆå®Œæˆï¼Œæ­£åœ¨é‡æ–°å¯åŠ¨ rcon æœåŠ¡${plain}"
    restart 0
    before_show_menu
}

# æ”¾å¼€é˜²ç«å¢™ç«¯å£
open_ports() {
    systemctl stop firewalld.service 2>/dev/null
    systemctl disable firewalld.service 2>/dev/null
    setenforce 0 2>/dev/null
    ufw disable 2>/dev/null
    iptables -P INPUT ACCEPT 2>/dev/null
    iptables -P FORWARD ACCEPT 2>/dev/null
    iptables -P OUTPUT ACCEPT 2>/dev/null
    iptables -t nat -F 2>/dev/null
    iptables -t mangle -F 2>/dev/null
    iptables -F 2>/dev/null
    iptables -X 2>/dev/null
    netfilter-persistent save 2>/dev/null
    echo -e "${green}æ”¾å¼€é˜²ç«å¢™ç«¯å£æˆåŠŸï¼${plain}"
}

show_usage() {
    echo "rcon ç®¡ç†è„šæœ¬ä½¿ç”¨æ–¹æ³•: "
    echo "------------------------------------------"
    echo "rcon              - æ˜¾ç¤ºç®¡ç†èœå• (åŠŸèƒ½æ›´å¤š)"
    echo "rcon start        - å¯åŠ¨ rcon"
    echo "rcon stop         - åœæ­¢ rcon"
    echo "rcon restart      - é‡å¯ rcon"
    echo "rcon status       - æŸ¥çœ‹ rcon çŠ¶æ€"
    echo "rcon enable       - è®¾ç½® rcon å¼€æœºè‡ªå¯"
    echo "rcon disable      - å–æ¶ˆ rcon å¼€æœºè‡ªå¯"
    echo "rcon log          - æŸ¥çœ‹ rcon æ—¥å¿—"
    echo "rcon x25519       - ç”Ÿæˆ x25519 å¯†é’¥"
    echo "rcon generate     - ç”Ÿæˆ rcon é…ç½®æ–‡ä»¶"
    echo "rcon install      - å®‰è£… rcon"
    echo "rcon uninstall    - å¸è½½ rcon"
    echo "rcon version      - æŸ¥çœ‹ rcon ç‰ˆæœ¬"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}rcon åŽç«¯ç®¡ç†è„šæœ¬ï¼Œ${plain}${red}ä¸é€‚ç”¨äºŽdocker${plain}
--- https://github.com/wyx2685/rcon ---
  ${green}0.${plain} ä¿®æ”¹é…ç½®
â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”
  ${green}1.${plain} å®‰è£… rcon
  ${green}2.${plain} æ›´æ–° rcon
  ${green}3.${plain} å¸è½½ rcon
â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”
  ${green}4.${plain} å¯åŠ¨ rcon
  ${green}5.${plain} åœæ­¢ rcon
  ${green}6.${plain} é‡å¯ rcon
  ${green}7.${plain} æŸ¥çœ‹ rcon çŠ¶æ€
  ${green}8.${plain} æŸ¥çœ‹ rcon æ—¥å¿—
â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”
  ${green}9.${plain} è®¾ç½® rcon å¼€æœºè‡ªå¯
  ${green}10.${plain} å–æ¶ˆ rcon å¼€æœºè‡ªå¯
â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”
  ${green}11.${plain} ä¸€é”®å®‰è£… bbr (æœ€æ–°å†…æ ¸)
  ${green}12.${plain} æŸ¥çœ‹ rcon ç‰ˆæœ¬
  ${green}13.${plain} ç”Ÿæˆ X25519 å¯†é’¥
  ${green}14.${plain} å‡çº§ rcon ç»´æŠ¤è„šæœ¬
  ${green}15.${plain} ç”Ÿæˆ rcon é…ç½®æ–‡ä»¶
  ${green}16.${plain} æ”¾è¡Œ VPS çš„æ‰€æœ‰ç½‘ç»œç«¯å£
  ${green}17.${plain} é€€å‡ºè„šæœ¬
 "
 #åŽç»­æ›´æ–°å¯åŠ å…¥ä¸Šæ–¹å­—ç¬¦ä¸²ä¸­
    show_status
    echo && read -rp "è¯·è¾“å…¥é€‰æ‹© [0-17]: " num

    case "${num}" in
        0) config ;;
        1) check_uninstall && install ;;
        2) check_install && update ;;
        3) check_install && uninstall ;;
        4) check_install && start ;;
        5) check_install && stop ;;
        6) check_install && restart ;;
        7) check_install && status ;;
        8) check_install && show_log ;;
        9) check_install && enable ;;
        10) check_install && disable ;;
        11) install_bbr ;;
        12) check_install && show_rcon_version ;;
        13) check_install && generate_x25519_key ;;
        14) update_shell ;;
        15) generate_config_file ;;
        16) open_ports ;;
        17) exit ;;
        *) echo -e "${red}è¯·è¾“å…¥æ­£ç¡®çš„æ•°å­— [0-16]${plain}" ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0 ;;
        "stop") check_install 0 && stop 0 ;;
        "restart") check_install 0 && restart 0 ;;
        "status") check_install 0 && status 0 ;;
        "enable") check_install 0 && enable 0 ;;
        "disable") check_install 0 && disable 0 ;;
        "log") check_install 0 && show_log 0 ;;
        "update") check_install 0 && update 0 $2 ;;
        "config") config $* ;;
        "generate") generate_config_file ;;
        "install") check_uninstall 0 && install 0 ;;
        "uninstall") check_install 0 && uninstall 0 ;;
        "x25519") check_install 0 && generate_x25519_key 0 ;;
        "version") check_install 0 && show_rcon_version 0 ;;
        "update_shell") update_shell ;;
        *) show_usage
    esac
else
    show_menu
fi

