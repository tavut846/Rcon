#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}é”™è¯¯ï¼š${plain} å¿…é¡»ä½¿ç”¨rootç”¨æˆ·è¿è¡Œæ­¤è„šæœ¬ï¼\n" && exit 1

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

arch=$(uname -m)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}æ£€æµ‹æž¶æž„å¤±è´¥ï¼Œä½¿ç”¨é»˜è®¤æž¶æž„: ${arch}${plain}"
fi

echo "æž¶æž„: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "æœ¬è½¯ä»¶ä¸æ”¯æŒ 32 ä½ç³»ç»Ÿ(x86)ï¼Œè¯·ä½¿ç”¨ 64 ä½ç³»ç»Ÿ(x86_64)ï¼Œå¦‚æžœæ£€æµ‹æœ‰è¯¯ï¼Œè¯·è”ç³»ä½œè€…"
    exit 2
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

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release wget curl unzip tar crontabs socat ca-certificates -y >/dev/null 2>&1
        update-ca-trust force-enable >/dev/null 2>&1
    elif [[ x"${release}" == x"alpine" ]]; then
        apk add wget curl unzip tar socat ca-certificates >/dev/null 2>&1
        update-ca-certificates >/dev/null 2>&1
    elif [[ x"${release}" == x"debian" ]]; then
        apt-get update -y >/dev/null 2>&1
        apt install wget curl unzip tar cron socat ca-certificates -y >/dev/null 2>&1
        update-ca-certificates >/dev/null 2>&1
    elif [[ x"${release}" == x"ubuntu" ]]; then
        apt-get update -y >/dev/null 2>&1
        apt install wget curl unzip tar cron socat -y >/dev/null 2>&1
        apt-get install ca-certificates wget -y >/dev/null 2>&1
        update-ca-certificates >/dev/null 2>&1
    elif [[ x"${release}" == x"arch" ]]; then
        pacman -Sy --noconfirm >/dev/null 2>&1
        pacman -S --noconfirm --needed wget curl unzip tar cron socat >/dev/null 2>&1
        pacman -S --noconfirm --needed ca-certificates wget >/dev/null 2>&1
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

install_rcon() {
    if [[ -e /usr/local/rcon/ ]]; then
        rm -rf /usr/local/rcon/
    fi

    mkdir /usr/local/rcon/ -p
    cd /usr/local/rcon/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/wyx2685/rcon/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}æ£€æµ‹ rcon ç‰ˆæœ¬å¤±è´¥ï¼Œå¯èƒ½æ˜¯è¶…å‡º Github API é™åˆ¶ï¼Œè¯·ç¨åŽå†è¯•ï¼Œæˆ–æ‰‹åŠ¨æŒ‡å®š rcon ç‰ˆæœ¬å®‰è£…${plain}"
            exit 1
        fi
        echo -e "æ£€æµ‹åˆ° rcon æœ€æ–°ç‰ˆæœ¬ï¼š${last_version}ï¼Œå¼€å§‹å®‰è£…"
        wget --no-check-certificate -N --progress=bar -O /usr/local/rcon/rcon-linux.zip https://github.com/wyx2685/rcon/releases/download/${last_version}/rcon-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}ä¸‹è½½ rcon å¤±è´¥ï¼Œè¯·ç¡®ä¿ä½ çš„æœåŠ¡å™¨èƒ½å¤Ÿä¸‹è½½ Github çš„æ–‡ä»¶${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/wyx2685/rcon/releases/download/${last_version}/rcon-linux-${arch}.zip"
        echo -e "å¼€å§‹å®‰è£… rcon $1"
        wget --no-check-certificate -N --progress=bar -O /usr/local/rcon/rcon-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}ä¸‹è½½ rcon $1 å¤±è´¥ï¼Œè¯·ç¡®ä¿æ­¤ç‰ˆæœ¬å­˜åœ¨${plain}"
            exit 1
        fi
    fi

    unzip rcon-linux.zip
    rm rcon-linux.zip -f
    chmod +x rcon
    mkdir /etc/rcon/ -p
    cp geoip.dat /etc/rcon/
    cp geosite.dat /etc/rcon/
    if [[ x"${release}" == x"alpine" ]]; then
        rm /etc/init.d/rcon -f
        cat <<EOF > /etc/init.d/rcon
#!/sbin/openrc-run

name="rcon"
description="rcon"

command="/usr/local/rcon/rcon"
command_args="server"
command_user="root"

pidfile="/run/rcon.pid"
command_background="yes"

depend() {
        need net
}
EOF
        chmod +x /etc/init.d/rcon
        rc-update add rcon default
        echo -e "${green}rcon ${last_version}${plain} å®‰è£…å®Œæˆï¼Œå·²è®¾ç½®å¼€æœºè‡ªå¯"
    else
        rm /etc/systemd/system/rcon.service -f
        cat <<EOF > /etc/systemd/system/rcon.service
[Unit]
Description=rcon Service
After=network.target nss-lookup.target
Wants=network.target

[Service]
User=root
Group=root
Type=simple
LimitAS=infinity
LimitRSS=infinity
LimitCORE=infinity
LimitNOFILE=999999
WorkingDirectory=/usr/local/rcon/
ExecStart=/usr/local/rcon/rcon server
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl stop rcon
        systemctl enable rcon
        echo -e "${green}rcon ${last_version}${plain} å®‰è£…å®Œæˆï¼Œå·²è®¾ç½®å¼€æœºè‡ªå¯"
    fi

    if [[ ! -f /etc/rcon/config.json ]]; then
        cp config.json /etc/rcon/
        echo -e ""
        echo -e "å…¨æ–°å®‰è£…ï¼Œè¯·å…ˆå‚çœ‹æ•™ç¨‹ï¼šhttps://rcon.v-50.me/ï¼Œé…ç½®å¿…è¦çš„å†…å®¹"
        first_install=true
    else
        if [[ x"${release}" == x"alpine" ]]; then
            service rcon start
        else
            systemctl start rcon
        fi
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}rcon é‡å¯æˆåŠŸ${plain}"
        else
            echo -e "${red}rcon å¯èƒ½å¯åŠ¨å¤±è´¥ï¼Œè¯·ç¨åŽä½¿ç”¨ rcon log æŸ¥çœ‹æ—¥å¿—ä¿¡æ¯ï¼Œè‹¥æ— æ³•å¯åŠ¨ï¼Œåˆ™å¯èƒ½æ›´æ”¹äº†é…ç½®æ ¼å¼ï¼Œè¯·å‰å¾€ wiki æŸ¥çœ‹ï¼šhttps://github.com/rcon-project/rcon/wiki${plain}"
        fi
        first_install=false
    fi

    if [[ ! -f /etc/rcon/dns.json ]]; then
        cp dns.json /etc/rcon/
    fi
    if [[ ! -f /etc/rcon/route.json ]]; then
        cp route.json /etc/rcon/
    fi
    if [[ ! -f /etc/rcon/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/rcon/
    fi
    if [[ ! -f /etc/rcon/custom_inbound.json ]]; then
        cp custom_inbound.json /etc/rcon/
    fi
    curl -o /usr/bin/rcon -Ls https://raw.githubusercontent.com/wyx2685/rcon-script/master/rcon.sh
    chmod +x /usr/bin/rcon
    if [ ! -L /usr/bin/rcon ]; then
        ln -s /usr/bin/rcon /usr/bin/rcon
        chmod +x /usr/bin/rcon
    fi
    cd $cur_dir
    rm -f install.sh
    echo -e ""
    echo "rcon ç®¡ç†è„šæœ¬ä½¿ç”¨æ–¹æ³• (å…¼å®¹ä½¿ç”¨rconæ‰§è¡Œï¼Œå¤§å°å†™ä¸æ•æ„Ÿ): "
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
    echo "rcon update       - æ›´æ–° rcon"
    echo "rcon update x.x.x - æ›´æ–° rcon æŒ‡å®šç‰ˆæœ¬"
    echo "rcon install      - å®‰è£… rcon"
    echo "rcon uninstall    - å¸è½½ rcon"
    echo "rcon version      - æŸ¥çœ‹ rcon ç‰ˆæœ¬"
    echo "------------------------------------------"
    curl -fsS --max-time 10 "https://api.v-50.me/counter_rcon" || true
    # é¦–æ¬¡å®‰è£…è¯¢é—®æ˜¯å¦ç”Ÿæˆé…ç½®æ–‡ä»¶
    if [[ $first_install == true ]]; then
        read -rp "æ£€æµ‹åˆ°ä½ ä¸ºç¬¬ä¸€æ¬¡å®‰è£…rcon,æ˜¯å¦è‡ªåŠ¨ç›´æŽ¥ç”Ÿæˆé…ç½®æ–‡ä»¶ï¼Ÿ(y/n): " if_generate
        if [[ $if_generate == [Yy] ]]; then
            curl -o ./initconfig.sh -Ls https://raw.githubusercontent.com/wyx2685/rcon-script/master/initconfig.sh
            source initconfig.sh
            rm initconfig.sh -f
            generate_config_file
        fi
    fi
}

echo -e "${green}å¼€å§‹å®‰è£…${plain}"
install_base
install_rcon $1

