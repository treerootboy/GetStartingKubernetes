#!/bin/sh

etcd_server=
while getopts e: option
do	case "$option" in
	e)	
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
KUBE_BIND_ADDRESS=$IP
KUBE_ETCD_SERVERS=$etcd_server

cat <<EOF >/usr/lib/systemd/system/proxy.service
[Unit]
Description=Kubernetes Proxy
# the proxy crashes if etcd isn't reachable.
# https://github.com/GoogleCloudPlatform/kubernetes/issues/1206
After=network.target

[Service]
ExecStart=/opt/kubernetes/bin/kube-proxy \\
    --logtostderr=${KUBE_LOGTOSTDERR} \\
    --v=${KUBE_LOG_LEVEL} \\
    --bind_address=${KUBE_BIND_ADDRESS} \\
    --etcd_servers=${KUBE_ETCD_SERVERS} 
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable proxy
systemctl start proxy