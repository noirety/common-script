#!/bin/bash

Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_Cyan="\033[36m"
Font_White="\033[37m"
Back_Black="\033[40m"
Back_Red="\033[41m"
Back_Green="\033[42m"
Back_Yellow="\033[43m"
Back_Blue="\033[44m"
Back_Purple="\033[45m"
Back_Cyan="\033[46m"
Back_White="\033[47m"
Font_Suffix="\033[0m"

echo_info(){
    local info="$1"
    echo -e "${Font_Blue}$info${Font_Suffix}"
}

echo_red(){
    local info="$1"
    echo -e "${Font_Red}$info${Font_Suffix}"
}

echo_yellow(){
    local info="$1"
    echo -e "${Font_Yellow}$info${Font_Suffix}"
}

# 函数：检查错误并退出
# 参数 $1: 错误消息
check_error() {
    if [ $? -ne 0 ]; then
        echo_red "发生错误： $1"
        exit 1
    fi
}

# 函数：检查是否具有 root 权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo_red "需要 root 权限来运行此脚本。请使用sudo或以root用户身份运行。"
        exit 1
    fi
}

# 函数：校验密码是否符合规则：12位包含字符、数字、特殊字符，首和末不能是特殊字符
# 参数 $1: 生成的密码
is_valid_password() {
    local password="$1"
    local special_chars='!#$%^&*()_-'
    if [[ "${password:0:1}" == *["$special_chars"*] ]]; then
        return 1
    fi
    if [[ "${password: -1}" == *["$special_chars"*] ]]; then
        return 1
    fi
    if [[ $password =~ [$special_chars] ]]; then
        return 0
    fi
    return 1
}

# 生成密码，直到符合要求
generate_valid_password() {
    while true; do
        # 生成12位随机密码
        local candidate=$(tr -dc 'a-zA-Z0-9!#$%^&*()_-' < /dev/urandom | fold -w 12 | head -n 1)
        if is_valid_password "$candidate"; then
            echo "$candidate"
            break
        fi
    done
}

modify_sshd_port() {
    local new_port="$1"

    port_regex="^([1-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$"

    if ! [[ $new_port =~ $port_regex ]]; then
        echo_red "输入端口不合法，跳过设置端口"
        return 1
    fi

    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    check_error "备份 sshd_config 文件时出错"

    if grep -q '^Port' /etc/ssh/sshd_config; then
        sed -i 's/^Port .*/Port '"$new_port"'/g' /etc/ssh/sshd_config
        check_error "修改 Port 时出错"
    else
        echo 'Port '"$new_port"'' | tee -a /etc/ssh/sshd_config > /dev/null
        check_error "修改 Port 时出错"
    fi

    echo_info "修改端口号完成，ssh端口号：$new_port"

    # 重启sshd服务
    restart_sshd_service
}

# 函数：修改 sshd_config 文件
# 参数 $1: 输入的端口
forbidden_root_login() {

    # 注释掉 Include /etc/ssh/sshd_config.d/*.conf 行
    sed -i 's/^Include \/etc\/ssh\/sshd_config.d\/\*\.conf/# &/' /etc/ssh/sshd_config
    check_error "注释掉 Include 行时出错"
    
    # 修改为PermitRootLogin no
    if grep -q '^PermitRootLogin' /etc/ssh/sshd_config; then
        sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        check_error "修改 PermitRootLogin 时出错"
    else
        echo 'PermitRootLogin no' | tee -a /etc/ssh/sshd_config > /dev/null
        check_error "追加 PermitRootLogin 时出错"
    fi
    echo_info "禁止 Root 用户登录完成"
    # 修改为PasswordAuthentication yes
    if grep -q '^PasswordAuthentication' /etc/ssh/sshd_config; then
        sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
        check_error "修改 PasswordAuthentication 时出错"
    else
        echo 'PasswordAuthentication yes' | tee -a /etc/ssh/sshd_config > /dev/null
        check_error "追加 PasswordAuthentication 时出错"
    fi
    echo_info "开启密码登录完成"
}

# 函数：重启 SSHD 服务
restart_sshd_service() {
    echo_info "重启sshd服务"
    systemctl restart sshd
    check_error "重启 SSHD 服务时出错"
}

# 更新软件
update_install_software() {
    echo_info "正在更新软件包"
    apt update
    check_error "更新软件包列表时出错"

    apt install -y vim nano net-tools inetutils-ping telnet ufw
    check_error "安装软件包时出错"
    echo_info "更新软件包完成"
    echo ""
}

# 修改hostname
# 参数 $1: 新的主机名
modify_hostname() {
    local newhostname="$1"
    # 检查输入是否为空
    if [ -z "$newhostname" ]
    then
        echo_red "主机名输入无效,跳过更改"
        return 1
    fi

    # 修改主机名
    hostnamectl set-hostname $newhostname

    # 根据主机名修改相关文件
    sed -i "s/^\(127.0.0.1\s*\)\(.*\)/\1$newhostname/g" /etc/hosts

    systemctl restart systemd-hostnamed

    echo -e "${Font_Blue}主机名已修改为: ${Font_Suffix}${Font_Red}$newhostname${Font_Suffix}"
}

# 添加用户，自动生成密码
add_user() {
    local newuser="$1"

    if [ -z "$newuser" ]; then
        echo_red "输入用户为空，跳过新建用户"
        return 1
    fi

    if id "$newuser" &>/dev/null; then
        echo_red "用户：$newuser 已存在，跳过新建用户"
        return 1
    fi

    local password=$(generate_valid_password)
    
    # 创建用户
    adduser --disabled-password --gecos "" $newuser
    echo "$newuser:$password" | chpasswd
    check_error "创建用户时出错"

    # 添加用户到 sudo 组
    echo "$newuser ALL=(ALL:ALL) NOPASSWD: ALL" | EDITOR='tee -a' visudo

    echo_info "新建用户完成"
    echo -e "${Font_Blue}用户名:${Font_Suffix} ${Font_Red}$newuser${Font_Suffix}"
    echo -e "${Font_Blue}密  码:${Font_Suffix} ${Font_Red}$password${Font_Suffix}"

    # 修改sshd配置文件
    forbidden_root_login
    # 重启sshd服务
    restart_sshd_service
}

# 设置时区
set_timezone_shanghai(){
    echo_info '修改时区为上海开始'
    timedatectl set-timezone Asia/Shanghai
    current_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo_info "当前时间：$current_time"
    echo_info '修改时区为上海完成'
    echo ""
}

# 开启bbr
enable_bbr(){
    echo_info "开启bbr开始"
    if ! grep -q '^net\.core\.default_qdisc=fq' /etc/sysctl.conf; then
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    fi

    if ! grep -q '^net\.ipv4\.tcp_congestion_control=bbr' /etc/sysctl.conf; then
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    fi

    sysctl -p
    echo_info "开启bbr完成"
    echo ""
}

# 设置ipv4优先
set_ipv4_priority(){
    echo_info '设置IPv4优先开始'
    if ! grep -q '^precedence ::ffff:0:0/96 100' /etc/gai.conf; then
        echo 'precedence ::ffff:0:0/96 100' >> /etc/gai.conf
    fi
    echo_info '测试IPv4优先度:'
    curl -s --connect-timeout 3 -m 5 ip.p3terx.com | head -n 1
    ipv4=$(curl -s --connect-timeout 3 -m 5 ip.gs)
    ipv6=$(curl -6 -s --connect-timeout 3 -m 5 ip.gs)
    echo_info '设置IPv4优先完成'
    echo -e "${Font_Blue}当前主机ipv4地址: ${Font_Suffix}${Font_Red}${ipv4}${Font_Suffix}"
    echo -e "${Font_Blue}当前主机ipv6地址: ${Font_Suffix}${Font_Red}${ipv6}${Font_Suffix}"
    echo ""
}

base_setting() {
    # 更新软件
    update_install_software

    # 开启BBR
    enable_bbr

    # 设置时区为上海
    set_timezone_shanghai

    # 设置IPV4优先
    set_ipv4_priority

    # 修改hostname
    read -p "请输入新的主机名(输入为空跳过): " newHostname
    modify_hostname $newHostname

    # 创建新用户
    read -p "请输入新的用户名(输入为空跳过): " newUser
    add_user $newUser

    # 修改ssh端口
    read -p "请输入新的ssh端口(输入为空跳过): " sshPort
    modify_sshd_port $sshPort
}

main_option(){
    while true; do
        echo ""
        echo ""
        echo "请选择要执行的操作："
        echo "---------------基础设置---------------------------"
        echo_red "1. 初始化设置（修改主机名、创建用户、修改ssh端口...）"
        echo "---------------常用功能---------------------------"
        echo "2. 安装Xray"
        echo "3. 添加Swap"
        echo "4. 安装iperf3"
        echo "5. 安装&检测nexttrace"
        echo "6. 清除默认防火墙规则(oracle)"
        echo "---------------常用检测----------------------------"
        echo "7. 三网回程检测"
        echo "8. IP质量检测(执行前记得保存屏幕中的信息)"
        echo "9. 流媒体解锁检测(执行前记得保存屏幕中的信息)"
        echo "--------------------------------------------------"
        echo_yellow "0. 退出脚本"
        echo ""
        read -p "请输入数字 (0-9): " user_input

        case $user_input in
            1)
                base_setting
                ;;
            2)
                echo_info "安装Xray..."
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
                echo_info "Xray安装完成"
                ;;
            3)
                # 添加Swap
                wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh
                ;;
            4)
                echo_info "安装iperf3..."
                apt install iperf3 -y
                echo_info "iperf3安装完成"
                ;;
            5)
                echo_info "安装&检测nxtrace..."
                curl nxtrace.org/nt | bash
                echo_info "nxtrace安装完成"

                echo_info "检测重庆电信..."
                nexttrace 219.153.159.189
                echo_info "检测重庆联通..."
                nexttrace 113.207.90.56
                echo_info "检测重庆移动..."
                nexttrace 111.10.61.226
                ;;
            6)
                echo_info "清除默认防火墙规则(oracle)开始..."
                iptables -F
                echo_info "清除默认防火墙规则(oracle)完成"
                ;;
            7)
                echo_info "三网回程检测开始..."
                curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh -sSf | sh
                echo_info "三网回程检测完成"
                ;;
            8)
                echo_info "IP质量检测开始..."
                bash <(curl -Ls ip.check.place)
                echo_info "检测IP质量完成"
                ;;
            9)
                echo_info "流媒体解锁检测开始..."
                bash <(curl -L -s media.ispvps.com)
                echo_info "流媒体解锁检测完成"
                ;;
            0)
                echo "退出脚本"
                exit 0
                ;;
            *)
                echo "无效的输入"
                echo ""
                ;;
        esac
    done
}

# 主函数
main() {

    main_option

    # 删除下载的脚本
    rm -f "$0"
}

# 执行主函数
main