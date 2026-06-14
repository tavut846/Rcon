#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error: ${plain} This script must be run as root!\n" && exit 1

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
    echo -e "${red}OS version not detected, please contact the script author!${plain}\n" && exit 1
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
        echo -e "${red}Please use CentOS 7 or higher!${plain}\n" && exit 1
    fi
    if [[ ${os_version} -eq 7 ]]; then
        echo -e "${red}Note: CentOS 7 cannot use hysteria1/2 protocol!${plain}\n"
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Please use Ubuntu 16 or higher!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please use Debian 8 or higher!${plain}\n" && exit 1
    fi
fi

# Check if the system has an IPv6 address
check_ipv6_support() {
    if ip -6 addr | grep -q "inet6"; then
        echo "1"  # Supports IPv6
    else
        echo "0"  # Does not support IPv6
    fi
}

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -rp "$1 [default $2]: " temp
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
    confirm "Restart rcon?" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Press Enter to return to the main menu: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/tavut846/Rcon/master/rcon-script/install.sh)
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
        echo && echo -n -e "Enter the specified version (default latest): " && read version
    else
        version=$2
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/tavut846/Rcon/master/rcon-script/install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}Update completed, rcon has been automatically restarted, please use 'rcon log' to view the running logs${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "rcon will automatically try to restart after modifying the configuration"
    vi /etc/rcon/config.json
    sleep 2
    restart
    check_status
    case $? in
        0)
            echo -e "rcon status: ${green}Running${plain}"
            ;;
        1)
            echo -e "Detected that you have not started rcon or rcon automatic restart failed, do you want to view the logs? [Y/n]" && echo
            read -e -rp "(default: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "rcon status: ${red}Not installed${plain}"
    esac
}

uninstall() {
    confirm "Are you sure you want to uninstall rcon?" "n"
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
    echo -e "Uninstall successful, if you want to delete this script, exit the script and run ${green}rm /usr/bin/rcon -f${plain} to delete it"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}rcon is already running, no need to start it again, if you need to restart please select restart${plain}"
    else
        if [[ x"${release}" == x"alpine" ]]; then
            service rcon start
        else
            systemctl start rcon
        fi
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}rcon started successfully, please use 'rcon log' to view the running logs${plain}"
        else
            echo -e "${red}rcon may have failed to start, please use 'rcon log' later to view the log information${plain}"
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
        echo -e "${green}rcon stopped successfully${plain}"
    else
        echo -e "${red}rcon failed to stop, possibly because the stop time exceeded two seconds, please check the log information later${plain}"
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
        echo -e "${green}rcon restarted successfully, please use 'rcon log' to view the running logs${plain}"
    else
        echo -e "${red}rcon may have failed to start, please use 'rcon log' later to view the log information${plain}"
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
        echo -e "${green}rcon set to start on boot successfully${plain}"
    else
        echo -e "${red}rcon failed to set to start on boot${plain}"
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
        echo -e "${green}rcon cancelled start on boot successfully${plain}"
    else
        echo -e "${red}rcon failed to cancel start on boot${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    if [[ x"${release}" == x"alpine" ]]; then
        echo -e "${red}Alpine system currently does not support viewing logs${plain}\n" && exit 1
    else
        journalctl -u rcon.service -e --no-pager -f
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

clear_log() {
    echo -e "${yellow}Clearing rcon logs...${plain}"
    if [[ -f /etc/rcon/error.log ]]; then
        > /etc/rcon/error.log
        echo -e "${green}Log file /etc/rcon/error.log cleared${plain}"
    fi
    if [[ x"${release}" != x"alpine" ]]; then
        journalctl --rotate 2>/dev/null
        journalctl --vacuum-time=1s 2>/dev/null
        echo -e "${green}System journal logs cleared${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh)
}

update_shell() {
    wget -O /usr/bin/rcon -N --no-check-certificate https://raw.githubusercontent.com/tavut846/Rcon/master/rcon-script/rcon.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Failed to download the script, please check if this machine can connect to GitHub${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/rcon
        echo -e "${green}Script upgraded successfully, please rerun the script${plain}" && exit 0
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
        echo -e "${red}rcon is already installed, please do not reinstall${plain}"
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
        echo -e "${red}Please install rcon first${plain}"
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
            echo -e "rcon status: ${green}Running${plain}"
            show_enable_status
            ;;
        1)
            echo -e "rcon status: ${yellow}Not running${plain}"
            show_enable_status
            ;;
        2)
            echo -e "rcon status: ${red}Not installed${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Start on boot: ${green}Yes${plain}"
    else
        echo -e "Start on boot: ${red}No${plain}"
    fi
}

generate_x25519_key() {
    echo -n "Generating x25519 key: "
    /usr/local/rcon/rcon x25519
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_rcon_version() {
    echo -n "rcon version: "
    /usr/local/rcon/rcon version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
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
    echo -e "${red}4. Currently only partial TLS is supported${plain}"
    echo -e "${red}5. The configuration file generated using this feature will include auditing. Are you sure you want to continue? (y/n)${plain}"
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
                read -rp "Please enter the panel website URL: " ApiHost
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

    echo -e "${green}rcon configuration file generation complete, restarting rcon service...${plain}"
    restart 0
    before_show_menu
}

# Open firewall ports
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
    echo -e "${green}Firewall ports opened successfully!${plain}"
}

show_usage() {
    echo "rcon management script usage: "
    echo "------------------------------------------"
    echo "rcon              - Show management menu (more features)"
    echo "rcon start        - Start rcon"
    echo "rcon stop         - Stop rcon"
    echo "rcon restart      - Restart rcon"
    echo "rcon status       - Check rcon status"
    echo "rcon enable       - Enable rcon on boot"
    echo "rcon disable      - Disable rcon on boot"
    echo "rcon log          - Check rcon logs"
    echo "rcon clearlog     - Clear rcon logs"
    echo "rcon x25519       - Generate x25519 key"
    echo "rcon generate     - Generate rcon configuration file"
    echo "rcon install      - Install rcon"
    echo "rcon uninstall    - Uninstall rcon"
    echo "rcon version      - Check rcon version"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}rcon Management Script, ${plain}${red}NOT applicable to docker${plain}
--- https://github.com/tavut846/Rcon ---
  ${green}0.${plain} Modify configuration
------------------------------------------
  ${green}1.${plain} Install rcon
  ${green}2.${plain} Update rcon
  ${green}3.${plain} Uninstall rcon
------------------------------------------
  ${green}4.${plain} Start rcon
  ${green}5.${plain} Stop rcon
  ${green}6.${plain} Restart rcon
  ${green}7.${plain} Check rcon status
  ${green}8.${plain} Check rcon logs
------------------------------------------
  ${green}9.${plain} Enable rcon on boot
  ${green}10.${plain} Disable rcon on boot
------------------------------------------
  ${green}11.${plain} One-click install BBR (latest kernel)
  ${green}12.${plain} Check rcon version
  ${green}13.${plain} Generate X25519 key
  ${green}14.${plain} Upgrade rcon maintenance script
  ${green}15.${plain} Generate rcon configuration file
  ${green}16.${plain} Open all network ports on VPS
  ${green}18.${plain} Clear rcon logs
  ${green}17.${plain} Exit script
 "
 # Subsequent updates can be added above
    show_status
    echo && read -rp "Please enter selection [0-18]: " num

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
        18) check_install && clear_log ;;
        *) echo -e "${red}Please enter a correct number [0-18]${plain}" ;;
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
        "clearlog") check_install 0 && clear_log 0 ;;
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

