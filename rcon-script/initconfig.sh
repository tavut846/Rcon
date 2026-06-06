#!/bin/bash
# One-click configuration

# Check if the system has an IPv6 address
check_ipv6_support() {
    if ip -6 addr | grep -q "inet6"; then
        echo "1"  # Supports IPv6
    else
        echo "0"  # Does not support IPv6
    fi
}

add_node_config() {
    while true; do
        read -rp "Please enter the Node ID: " NodeID
        if [[ "$NodeID" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Error: Please enter a valid number for Node ID."
        fi
    done

    echo -e "${yellow}Please select the node transport protocol:${plain}"
    echo -e "${green}1. Shadowsocks${plain}"
    echo -e "${green}2. Vless${plain}"
    echo -e "${green}3. Vmess${plain}"
    echo -e "${green}6. Trojan${plain}"
    read -rp "Please enter: " NodeType
    case "$NodeType" in
        1 ) NodeType="shadowsocks" ;;
        2 ) NodeType="vless" ;;
        3 ) NodeType="vmess" ;;
        6 ) NodeType="trojan" ;;
        * ) NodeType="shadowsocks" ;;
    esac

    isreality=""
    istls=""
    if [ "$NodeType" == "vless" ]; then
        read -rp "Is this a Reality node? (y/n) " isreality
    fi

    if [[ "$NodeType" != "shadowsocks" && "$isreality" != "y" && "$isreality" != "Y" ]]; then
        read -rp "Do you want to configure TLS? (y/n) " istls
    fi

    certmode="none"
    certdomain="example.com"
    if [[ "$isreality" != "y" && "$isreality" != "Y" && ( "$istls" == "y" || "$istls" == "Y" ) ]]; then
        echo -e "${yellow}Please select the certificate application mode:${plain}"
        echo -e "${green}1. HTTP mode: Automatic application, node domain must be correctly resolved${plain}"
        echo -e "${green}2. DNS mode: Automatic application, requires correct DNS provider API parameters${plain}"
        echo -e "${green}3. Self mode: Self-signed certificate or provide existing certificate files${plain}"
        read -rp "Please enter: " certmode
        case "$certmode" in
            1 ) certmode="http" ;;
            2 ) certmode="dns" ;;
            3 ) certmode="self" ;;
        esac
        read -rp "Please enter the node certificate domain (example.com): " certdomain
        if [ "$certmode" != "http" ]; then
            echo -e "${red}Please manually modify the configuration file and restart rcon!${plain}"
        fi
    fi

    node_config=$(cat <<EOF
{
            "Core": "xray",
            "ApiHost": "$ApiHost",
            "ApiKey": "$ApiKey",
            "NodeID": $NodeID,
            "NodeType": "$NodeType",
            "Timeout": 30,
            "ListenIP": "0.0.0.0",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 200,
            "ReportMinTraffic": 0,
            "XrayOptions": {
                "EnableProxyProtocol": false,
                "EnableUot": true,
                "EnableTFO": true,
                "DNSType": "UseIPv4"
            },
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
    nodes_config+=("$node_config")
}

generate_config_file() {
    echo -e "${yellow}rcon Configuration File Generation Wizard${plain}"
    echo -e "${red}Please read the following notes:${plain}"
    echo -e "${red}1. This feature is currently in the testing stage${plain}"
    echo -e "${red}2. The generated configuration file will be saved to /etc/rcon/config.json${plain}"
    echo -e "${red}3. The original configuration file will be saved to /etc/rcon/config.json.bak${plain}"
    echo -e "${red}4. The configuration file generated using this feature will include auditing. Are you sure you want to continue? (y/n)${plain}"
    read -rp "Please enter: " continue_prompt
    if [[ "$continue_prompt" =~ ^[Nn][Oo]? ]]; then
        exit 0
    fi

    nodes_config=()
    first_node=true
    fixed_api_info=false

    while true; do
        if [ "$first_node" = true ]; then
            read -rp "Please enter the panel website URL (https://example.com): " ApiHost
            read -rp "Please enter the panel API Key: " ApiKey
            read -rp "Do you want to set a fixed panel URL and API Key? (y/n) " fixed_api
            if [ "$fixed_api" = "y" ] || [ "$fixed_api" = "Y" ]; then
                fixed_api_info=true
                echo -e "${red}Successfully fixed the address${plain}"
            fi
            first_node=false
            add_node_config
        else
            read -rp "Do you want to continue adding node configurations? (Enter to continue, n or no to exit) " continue_adding_node
            if [[ "$continue_adding_node" =~ ^[Nn][Oo]? ]]; then
                break
            elif [ "$fixed_api_info" = false ]; then
                read -rp "Please enter the panel website URL (https://example.com): " ApiHost
                read -rp "Please enter the panel API Key: " ApiKey
            fi
            add_node_config
        fi
    done

    cores_config='[
    {
        "Type": "xray",
        "Log": {
            "Level": "error",
            "ErrorPath": "/etc/rcon/error.log"
        },
        "OutboundConfigPath": "/etc/rcon/custom_outbound.json",
        "RouteConfigPath": "/etc/rcon/route.json"
    }]'

    # Change to configuration file directory
    cd /etc/rcon

    # Backup old configuration file
    mv config.json config.json.bak
    nodes_config_str="${nodes_config[*]}"
    formatted_nodes_config="${nodes_config_str%,}"

    # Create config.json file
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

    # Create custom_outbound.json file
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

    # Create route.json file
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

    echo -e "${green}rcon configuration file generation complete.${plain}"
}
