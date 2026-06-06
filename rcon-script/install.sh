#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

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

arch=$(uname -m)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}Failed to detect architecture, using default architecture: ${arch}${plain}"
fi

echo "Architecture: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "This software does not support 32-bit systems (x86), please use a 64-bit system (x86_64). If this is a misdetection, please contact the author."
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
        echo -e "${red}Please use CentOS 7 or higher!${plain}\n" && exit 1
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
        last_version=$(curl -Ls "https://api.github.com/repos/tavut846/Rcon/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Failed to detect rcon version, possibly due to GitHub API limits. Please try again later or manually specify a version for installation.${plain}"
            exit 1
        fi
        echo -e "Latest rcon version detected: ${last_version}, starting installation..."
        wget --no-check-certificate -N --progress=bar -O /usr/local/rcon/rcon-linux.zip https://github.com/tavut846/Rcon/releases/download/${last_version}/rcon-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Failed to download rcon, please ensure your server can download files from GitHub.${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/tavut846/Rcon/releases/download/${last_version}/rcon-linux-${arch}.zip"
        echo -e "Starting installation of rcon $1..."
        wget --no-check-certificate -N --progress=bar -O /usr/local/rcon/rcon-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Failed to download rcon $1, please ensure this version exists.${plain}"
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
        echo -e "${green}rcon ${last_version}${plain} installation complete, set to start on boot."
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
        echo -e "${green}rcon ${last_version}${plain} installation complete, set to start on boot."
    fi

    if [[ ! -f /etc/rcon/config.json ]]; then
        cp config.json /etc/rcon/
        echo -e ""
        echo -e "New installation, please refer to the tutorial: https://github.com/tavut846/Rcon to configure the necessary content."
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
            echo -e "${green}rcon restarted successfully${plain}"
        else
            echo -e "${red}rcon may have failed to start, please use 'rcon log' later to view the logs. If it cannot start, the configuration format may have changed; please check the wiki: https://github.com/tavut846/Rcon/wiki${plain}"
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
    curl -o /usr/bin/rcon -Ls https://raw.githubusercontent.com/tavut846/Rcon/master/rcon-script/rcon.sh
    chmod +x /usr/bin/rcon
    cd $cur_dir
    rm -f install.sh
    echo -e ""
    echo "rcon management script usage (compatible with 'rcon' command, case-insensitive): "
    echo "------------------------------------------"
    echo "rcon              - Show management menu (more features)"
    echo "rcon start        - Start rcon"
    echo "rcon stop         - Stop rcon"
    echo "rcon restart      - Restart rcon"
    echo "rcon status       - Check rcon status"
    echo "rcon enable       - Enable rcon on boot"
    echo "rcon disable      - Disable rcon on boot"
    echo "rcon log          - Check rcon logs"
    echo "rcon x25519       - Generate x25519 key"
    echo "rcon generate     - Generate rcon configuration file"
    echo "rcon update       - Update rcon"
    echo "rcon update x.x.x - Update rcon to specified version"
    echo "rcon install      - Install rcon"
    echo "rcon uninstall    - Uninstall rcon"
    echo "rcon version      - Check rcon version"
    echo "------------------------------------------"
    # Ask whether to generate a configuration file during first-time installation
    if [[ $first_install == true ]]; then
        read -rp "First-time installation detected, do you want to automatically generate a configuration file? (y/n): " if_generate
        if [[ $if_generate == [Yy] ]]; then
            curl -o ./initconfig.sh -Ls https://raw.githubusercontent.com/tavut846/Rcon/master/rcon-script/initconfig.sh
            source initconfig.sh
            rm initconfig.sh -f
            generate_config_file
            if [[ x"${release}" == x"alpine" ]]; then
                service rcon restart
            else
                systemctl restart rcon
            fi
            echo -e "${green}rcon has been started/restarted.${plain}"
        fi
    fi
}

echo -e "${green}Starting installation...${plain}"
install_base
install_rcon $1
