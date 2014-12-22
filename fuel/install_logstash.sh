#!/bin/sh

if [ $# != 1 ]; then
    echo "Usage: $0 <remote_node_name>"
    exit
fi

scp -r fuel root@$1:
ssh $1 <<EOF
yum install -y java-1.6.0-openjdk
rpm -ivh fuel/logstash-1.4.2-1_2c0f5a1.noarch.rpm
rpm -ivh fuel/logstash-contrib-1.4.2-1_efd53ef.noarch.rpm
/bin/cp fuel/agent.conf /etc/logstash/conf.d

sed -i "s/LS_USER=.*/LS_USER=root/" /etc/init.d/logstash
sed -i "s/LS_GROUP=.*/LS_GROUP=root/" /etc/init.d/logstash

chkconfig logstash on
service logstash start
EOF

