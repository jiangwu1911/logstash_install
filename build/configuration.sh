#!/bin/sh

CLUSTER_NAME="metalog"

function get_input() {
    read -p "$1 (缺省: $3): " VAR
    if [ -z $VAR ]; then
        VAR=$3
    fi
    eval $2=$VAR
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
        default_interface=$(ip link show  | grep -v '^\s' | cut -d':' -f2 | sed 's/ //g' | grep -v lo | head -1)
        address=$(ip addr show label $default_interface scope global | awk '$1 == "inet" { print $2,$4}')
        ip=$(echo $address | awk '{print $1 }')
        ip=${ip%%/*}
        broadcast=$(echo $address | awk '{print $2 }')
        netmask=$(route -n |grep 'U[ \t]' | head -n 1 | awk '{print $3}')
        gateway=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
        hostname=`hostname`
        dns=$(cat /etc/resolv.conf | grep nameserver | head -n 1 | awk '{print $2}')

        get_input '请输入Hostname' HOSTNAME $hostname 
        get_input '选择提供日志服务的网卡' INTERFACE $default_interface 
        get_input 'IP地址' IPADDR $ip
        get_input '掩码' NETMASK $netmask
        get_input '网关地址' GATEWAY $gateway
        get_input 'DNS服务器地址' DNS1 $gateway

        echo -e "\n输入的网络配置参数:" 
        echo "    Hostname: $HOSTNAME" 
        echo "    IP地址: $IPADDR" 
        echo "    掩码: $NETMASK" 
        echo "    网关地址: $GATEWAY" 
        echo "    DNS服务器地址: $DNS1"
        echo ""

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
DNS1="$DNS1"
EOF
    cat > /etc/sysconfig/network <<EOF
NETWORKING=yes
GATEWAY=$GATEWAY
EOF
    cat > /etc/hostname <<EOF
$HOSTNAME
EOF
    cat >> /etc/hosts <<EOF
$IPADDR $HOSTNAME
EOF

    hostname $HOSTNAME
    service network restart    
}


function install_and_config_logstash() {
    pushd ~/logstash >/dev/null

    # Modify node.name in elasticsearch's config file
    sed -i "s/^cluster.name:.*/cluster.name: $CLUSTER_NAME/" files/elasticsearch.yml
    sed -i "s/^node.name:.*/node.name: \"$HOSTNAME\"/" files/elasticsearch.yml

    # Modify redis IP address in logstash config file
    sed -i "s/host => .*REDIS_IP/host => \"$IPADDR\" # REDIS_IP/"  files/central.conf
    sed -i "s/cluster => .*/cluster => \"$CLUSTER_NAME\"/"  files/central.conf

    # Install elasticsearch
    yum install -y elasticsearch
    cp -f files/elasticsearch.yml /etc/elasticsearch
    systemctl enable elasticsearch
    systemctl restart elasticsearch
 
    # Install logstash 
    yum install -y logstash
    cp -f files/central.conf /etc/logstash/conf.d
    systemctl enable logstash 
    systemctl restart logstash

    # Install redis
    yum install -y redis
    cp files/redis.conf /etc 
    systemctl enable redis
    systemctl restart redis

    # Install kibana 4.1
    if [ ! -e /opt/kibana ]; then
        pushd /opt >/dev/null
        tar zvxf packages/kibana-4.1.1-linux-x64.tar.gz >/dev/null
        mv kibana-4.1.1-linux-x64 kibana
        popd > /dev/null
    fi
    chown -R logstash:logstash /opt/kibana
    cp -f files/logstash-web /etc/init.d
    chkconfig logstash-web on
    service logstash-web restart

    popd >/dev/null
}

function redirect_syslog_to_logstash() {
    sed -i "s/#\*\.\* @@remote-host:514/*.* @@127.0.0.1:5514/" /etc/rsyslog.conf
    systemctl restart rsyslog
}

config_network
install_and_config_logstash
redirect_syslog_to_logstash
