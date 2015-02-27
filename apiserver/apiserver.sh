#!/bin/sh

IP=$(hostname -I | awk '{print $1}')

KUBE_LOGTOSTDERR=true
KUBE_LOG_LEVEL=4
KUBE_ETCD_SERVERS=http://${IP}:4001
KUBE_API_ADDRESS=${IP}
KUBE_API_PORT=8080
MINION_PORT=10250
KUBE_ALLOW_PRIV=false
KUBE_SERVICE_ADDRESSES=10.10.10.0/24


cat <<EOF >/usr/lib/systemd/system/apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/bin/kube-apiserver  \\
	--logtostderr=${KUBE_LOGTOSTDERR} \\
	--v=${KUBE_LOG_LEVEL} \\
	--etcd_servers=${KUBE_ETCD_SERVERS} \\
	--address=${KUBE_API_ADDRESS} \\
	--port=${KUBE_API_PORT} \\
	--kubelet_port=${MINION_PORT} \\
	--allow_privileged=${KUBE_ALLOW_PRIV} \\
	--portal_net=${KUBE_SERVICE_ADDRESSES}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable apiserver
systemctl start apiserver