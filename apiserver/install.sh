#!/bin/sh
minions=
while getopt m: option
do	case "$option" in
	m|minions|machines)	
		minions="$OPTARG";;
	[?]) 
		echo <<EOF
Usage: $0 [-m 192.168.1.1,192.168.1.2]

Params
	-m --minions --machines   set minions ips
EOF
		exit 1;;
	esac
done
shift $OPTIND-1

#
# 部署API Server
#

#1. 安裝Kubernetes APIServer
mkdir /tmp/kubernetes
cd /tmp/kubernetes
wget https://github.com/GoogleCloudPlatform/kubernetes/releases/download/v0.11.0/kubernetes.tar.gz
wget https://github.com/coreos/etcd/releases/download/v2.0.3/etcd-v2.0.3-linux-amd64.tar.gz
tar xf kubernetes.tar.gz
tar xf etcd-v2.0.3-linux-amd64.tar.gz
cd ./kubernetes/server
tar xf kubernetes-server-linux-amd64.tar.gz


mkdir -p /data/docker/script/kubernetes/bin/
cd ./kubernetes/server/bin
cp kube-apiserver kube-controller-manager kubecfg kube-scheduler kube-proxy kubelet /bin/
cp etcd etcdctl /bin/

cd /bin/
chmod u+x kube-apiserver kube-controller-manager kubecfg kube-scheduler kube-proxy kubelet etcd etcdctl

SCRIPTDIR=$(cd `dirname $0`;pwd)
sh $SCRIPTDIR/apiserver.sh
sh $SCRIPTDIR/controller-manager.sh -m minions
sh $SCRIPTDIR/etcd.sh
sh $SCRIPTDIR/scheduler.sh

