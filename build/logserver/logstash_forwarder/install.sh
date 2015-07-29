#!/bin/sh

NTPSERVER="1.cn.pool.ntp.org"
LOGSERVER_IP="192.168.206.164"
LOGSERVER_PORT="5000"

dt=`date '+%Y%m%d-%H%M%S'`
currentdir=`pwd`
logfile="$currentdir/install_$dt.log"

function install_logstash_forwarder() {
    ntpdate $NTPSERVER >/dev/null; clock -w >/dev/null
    rpm -ivh logstash-forwarder-0.4.0-1.x86_64.rpm >> $logfile 2>&1
}

function config_logstash_forwarder() {
    if [ ! -e /etc/pki/tls/certs ]; then
        mkdir -p /etc/pki/tls/certs
    fi
    cp logstash-forwarder.crt /etc/pki/tls/certs

    cat > /etc/logstash-forwarder.conf <<EOF
{
  "network": {
    "servers": [ "$LOGSERVER_IP:$LOGSERVER_PORT" ],
    "timeout": 15,
    "ssl ca": "/etc/pki/tls/certs/logstash-forwarder.crt"
  },

  "files": [
    {
      "paths": [
        "/var/log/nginx/access.log"
       ],
      "fields": { "type": "nginx-access",
                   "catalog": "web" }
    }
  ]
}
EOF
}

function start_logstash_forwarder() {
    chkconfig logstash-forwarder on >> $logfile 2>&1
    service logstash-forwarder restart >> $logfile 2>&1
}

echo -ne "\n正在安装logstash-forwarder......      "
install_logstash_forwarder
config_logstash_forwarder
start_logstash_forwarder
echo -e "安装完毕."
