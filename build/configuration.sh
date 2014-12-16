#!/bin/sh

function get_input() {
    read -p "$1 (缺省: $2): " VAR
    if [ -z $VAR ]; then
        VAR=$2
    fi
    eval $3=$VAR
}

function answer_yes_or_no() {
    while :
    do
        read -p "$1 (yes/no): " VAR
        if [ "$VAR" = "yes" -o "$VAR" = "no" ]; then
            break
        fi
    done
    eval $2=$VAR
}

function splash_screen() {
    clear
    echo -e "\n            欢迎使用logstash日志服务器\n"
}

function config_network() {
    while :
    do
        splash_screen

        echo -e "开始配置网络:\n"
        default_route=$(ip route show)
        default_interface=$(echo $default_route | sed -e 's/^.*dev \([^ ]*\).*$/\1/' | head -n 1)
        address=$(ip addr show label $default_interface scope global | awk '$1 == "inet" { print $2,$4}')
        ip=$(echo $address | awk '{print $1 }')
        ip=${ip%%/*}
        broadcast=$(echo $address | awk '{print $2 }')
        netmask=$(route -n |grep 'U[ \t]' | head -n 1 | awk '{print $3}')
        gateway=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
        hostname=`hostname`
        dns=$(cat /etc/resolv.conf | grep nameserver | head -n 1 | awk '{print $2}')

        get_input '请输入Hostname' $hostname HOSTNAME 
        get_input '选择提供日志服务的网卡' $default_interface INTERFACE
        get_input 'IP地址' $ip IPADDR
        get_input '掩码' $netmask NETMASK
        get_input '网关地址' $gateway GATEWAY
        SUBNET=$(echo $IPADDR | cut -d. -f1-3)'.0'
        dhcp_start=$(echo $IPADDR | cut -d. -f1-3)'.100'
        dhcp_end=$(echo $IPADDR | cut -d. -f1-3)'.254'
        get_input 'DHCP起始地址' $dhcp_start DHCP_START
        get_input 'DHCP结束地址' $dhcp_end DHCP_END

        echo -e "\n输入的网络配置参数:" 
        echo "    Hostname: $HOSTNAME" 
        echo "    IP地址: $IPADDR" 
        echo "    掩码: $NETMASK" 
        echo "    网关地址: $GATEWAY" 
        echo "    DHCP起始地址: $DHCP_START" 
        echo -e "    DHCP结束地址: $DHCP_END\n" 

        answer_yes_or_no "请确认以上信息是否正确:" ANSWER
        if [ "$ANSWER" = "yes" ]; then
            break
        fi
    done

    cat > /etc/sysconfig/network-scripts/ifcfg-$INTERFACE <<EOF
DEVICE="$INTERFACE"
BOOTPROTO="static"
GATEWAY="$GATEWAY"
IPADDR="$IPADDR"
NETMASK="$NETMASK"
ONBOOT="yes"
EOF
    cat > /etc/sysconfig/network <<EOF
NETWORKING=yes
HOSTNAME=$HOSTNAME
GATEWAY=$GATEWAY
EOF
    sed -i "s/^hosts:.*/hosts: files/" /etc/nsswitch.conf
    service network restart    
}

config_network
