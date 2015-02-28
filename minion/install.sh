#!/bin/sh

etcd_server=
while getopts -o e: --long etcdapi: option
do	case "$option" in
	e|etcdapi)	
		etcd_server="$OPTARG";;
	[?]) 
		echo <<EOF
Usage: $0 [-e http://192.168.1.1:4001]

Params
	-e --etcdapi   set etcd server api address
EOF
		exit 1;;
	esac
done
shift $OPTIND-1

#
# 部署Minion
#

#1. Open vSwitch解決跨機器Pod之間的通訊問題

	#製作Open vSwitch rpm
	yum -y install wget openssl-devel kernel-devel
	adduser ovswitch
	su - ovswitch
	wget http://openvswitch.org/releases/openvswitch-2.3.0.tar.gz
	tar xzf openvswitch-2.3.0.tar.gz
	sed 's/openvswitch-kmod, //g' openvswitch-2.3.0/rhel/openvswitch.spec > openvswitch-2.3.0/rhel/openvswitch_no_kmod.spec
	mkdir -p ~/rpmbuild/SOURCE
	cp openvswitch-2.3.0.tar.gz ~/rpmbuild/SOURCE
	rpmbuild -bb --without check ~/openvswitch-2.3.0/rhel/openvswitch_no_kmod.spec
	cp /home/ovswitch/rpmbuild/RPMS/x86_64/openvswitch-2.3.0-1.x86_64.rpm /data/
	
	#安裝Open vSwitch
	yum localinstall /data/openvswitch-2.3.0-1.x86_64.rpm


	#啟動openvswitch服務
	systemctl start openvswitch
	systemctl status openvswitch

	#若開啓一直無法完成，status提示以下錯誤
		#openvswitch[19393]: /etc/openvswitch/conf.db does not exist ... (warning).
		#openvswitch[19393]: Creating empty database /etc/openvswitch/conf.db ovsdb-tool: I/O error: /etc/openvswitch/conf.db: failed to lock lockfile (Resource temporarily unavailable)	
		#openvswitch[19393]: [FAILED]
		#openvswitch[19393]: Inserting openvswitch module [  OK  ]

	#則運行下面指令修復，上面錯誤是由於SELinux開啓後，讀寫權限不足
	yum -y install policycoreutils-python
	mkdir /etc/openvswitch
	restorecon -Rv /etc/openvswitch
	semanage fcontext -a -t openvswitch_rw_t "/etc/openvswitch(/.*)?"
	restorecon -Rv /etc/openvswitch

	systemctl restart openvswitch
	systemctl status openvswitch





#2. 建立通訊隧道
	IP=$(hostname -I | awk '{print $1}')
	ovs-vsctl add-br obr0
	ovs-vsctl add-port obr0 gre0 -- set interface gre0 type=gre options:remote_ip=${IP}
	
	#創建網橋kbr0，橋接通訊隧道obr0，並替換docker0原生網橋
	brctl addbr kbr0
	brctl addif kbr0 obr0
        ip link set dev docker0 down
	ip link del dev docker0
	
	IPPATH=$(hostname -I | awk '{print $1}' | awk -F'.' '{print $4}')
	echo "DEVICE=kbr0
ONBOOT=yes
BOOTPROTO=static
IPADDR=172.17.${IPPATH}.1
NETMASK=255.255.255.0
GATEWAY=172.17.${IPPATH}.0
USERCTL=no
TYPE=Bridge
IPV6INIT=no" > /etc/sysconfig/network-scripts/ifcfg-kbr0

	systemctl reload network

	#建立路由
	ip route add 172.17.${IPPATH}.0/24 via $IP dev eno1

	echo "172.17.${IPPATH}.0/24 via $IP dev eno1" > /etc/sysconfig/network-scripts/route-eno1





#3. 創建unit守恆腳本
SCRIPTDIR=$(cd `dirname $0`;pwd)
sh $SCRIPTDIR/docker.sh
sh $SCRIPTDIR/kubelet.sh -e $etcd_server
sh $SCRIPTDIR/proxy.sh -e $etcd_server

































