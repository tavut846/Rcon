#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

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
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
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
    echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi

echo "架构: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
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
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
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
            echo -e "${red}检测 rcon 版本失败，可能是超出 Github API 限制，请稍后再试，或手动指定 rcon 版本安装${plain}"
            exit 1
        fi
        echo -e "检测到 rcon 最新版本：${last_version}，开始安装"
        wget --no-check-certificate -N --progress=bar -O /usr/local/rcon/rcon-linux.zip https://github.com/tavut846/Rcon/releases/download/${last_version}/rcon-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 rcon 失败，请确保你的服务器能够下载 Github 的文件${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/tavut846/Rcon/releases/download/${last_version}/rcon-linux-${arch}.zip"
        echo -e "开始安装 rcon $1"
        wget --no-check-certificate -N --progress=bar -O /usr/local/rcon/rcon-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 rcon $1 失败，请确保此版本存在${plain}"
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
        echo -e "${green}rcon ${last_version}${plain} 安装完成，已设置开机自启"
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
        echo -e "${green}rcon ${last_version}${plain} 安装完成，已设置开机自启"
    fi

    if [[ ! -f /etc/rcon/config.json ]]; then
        cp config.json /etc/rcon/
        echo -e ""
        echo -e "全新安装，请先参看教程：https://github.com/tavut846/Rcon，配置必要的内容"
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
            echo -e "${green}rcon 重启成功${plain}"
        else
            echo -e "${red}rcon 可能启动失败，请稍后使用 rcon log 查看日志信息，若无法启动，则可能更改了配置格式，请前往 wiki 查看：https://github.com/tavut846/Rcon/wiki${plain}"
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
    if [ ! -L /usr/bin/rcon ]; then
        ln -s /usr/bin/rcon /usr/bin/rcon
        chmod +x /usr/bin/rcon
    fi
    cd $cur_dir
    rm -f install.sh
    echo -e ""
    echo "rcon 管理脚本使用方法 (兼容使用rcon执行，大小写不敏感): "
    echo "------------------------------------------"
    echo "rcon              - 显示管理菜单 (功能更多)"
    echo "rcon start        - 启动 rcon"
    echo "rcon stop         - 停止 rcon"
    echo "rcon restart      - 重启 rcon"
    echo "rcon status       - 查看 rcon 状态"
    echo "rcon enable       - 设置 rcon 开机自启"
    echo "rcon disable      - 取消 rcon 开机自启"
    echo "rcon log          - 查看 rcon 日志"
    echo "rcon x25519       - 生成 x25519 密钥"
    echo "rcon generate     - 生成 rcon 配置文件"
    echo "rcon update       - 更新 rcon"
    echo "rcon update x.x.x - 更新 rcon 指定版本"
    echo "rcon install      - 安装 rcon"
    echo "rcon uninstall    - 卸载 rcon"
    echo "rcon version      - 查看 rcon 版本"
    echo "------------------------------------------"
    # 首次安装询问是否生成配置文件
    if [[ $first_install == true ]]; then
        read -rp "检测到你为第一次安装rcon,是否自动直接生成配置文件？(y/n): " if_generate
        if [[ $if_generate == [Yy] ]]; then
            curl -o ./initconfig.sh -Ls https://raw.githubusercontent.com/tavut846/Rcon/master/rcon-script/initconfig.sh
            source initconfig.sh
            rm initconfig.sh -f
            generate_config_file
        fi
    fi
}

echo -e "${green}开始安装${plain}"
install_base
install_rcon $1
