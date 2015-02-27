#!/bin/sh

while getopts -o m: --long minions:,machines: option
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

IP=$(hostname -I | awk '{print $1}')

KUBE_LOGTOSTDERR=true
KUBE_LOG_LEVEL=4
KUBE_MASTER=${IP}:8080
MINION_ADDRESSES=$minions

cat <<EOF >/usr/lib/systemd/system/controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/bin/kube-controller-manager \\
    --logtostderr=${KUBE_LOGTOSTDERR} \\
    --v=${KUBE_LOG_LEVEL} \\
	--machines=${MINION_ADDRESSES} \\
    --master=${KUBE_MASTER}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable controller-manager
systemctl start controller-manager