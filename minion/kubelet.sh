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


IP=$(hostname -I | awk '{print $1}')

KUBE_LOGTOSTDERR=true
KUBE_LOG_LEVEL=4
KUBE_ETCD_SERVERS=$etcd_server
MINION_ADDRESS=$IP
MINION_PORT=10250
MINION_HOSTNAME=$IP
KUBE_ALLOW_PRIV=false

cat <<EOF >/usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.socket cadvisor.service
Requires=docker.socket

[Service]
ExecStart=/opt/kubernetes/bin/kubelet \\
    --logtostderr=${KUBE_LOGTOSTDERR} \\
    --v=${KUBE_LOG_LEVEL} \\
    --etcd_servers=${KUBE_ETCD_SERVERS} \\
    --address=${MINION_ADDRESS} \\
    --port=${MINION_PORT} \\
    --hostname_override=${MINION_HOSTNAME} \\
    --allow_privileged=${KUBE_ALLOW_PRIV}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet