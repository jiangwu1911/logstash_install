#!/bin/sh

if [ $# != 1 ]; then
    echo "Usage: $0 <remote_node_name>"
    exit
fi

scp -r fuel root@$1:
ssh $1 <<EOF
hostname=`hostname`
rpm -ivh fuel/collectd-4.10.9-1.el6.x86_64.rpm
/bin/cp fuel/collectd.conf /etc
sed -i "s/Hostname.*/Hostname $hostname/" /etc/collectd.conf
chkconfig collectd on
service collectd start
EOF

