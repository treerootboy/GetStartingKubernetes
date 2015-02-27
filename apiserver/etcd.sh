#!/bin/sh
IP=$(hostname -I | awk '{print $1}')

ETCD_PEER_ADDR=${IP}:7001
ETCD_ADDR=${IP}:4001
ETCD_DATA_DIR=/var/lib/etcd
ETCD_NAME=kubernetes

! test -d $ETCD_DATA_DIR && mkdir -p $ETCD_DATA_DIR
cat <<EOF >//usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server

[Service]
ExecStart=/bin/etcd \\
	-peer-addr=$ETCD_PEER_ADDR \\
	-addr=$ETCD_ADDR \\
	-data-dir=$ETCD_DATA_DIR \\
	-name=$ETCD_NAME \\
	-bind-addr=0.0.0.0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etcd
systemctl start etcd