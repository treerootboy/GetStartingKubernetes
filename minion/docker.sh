#!/bin/sh

DOCKER_REAL_HOME=/home/docker_not_delete

#1. 由於新系統硬盤/較小，將docker目錄改到/home
test ! -e $DOCKER_REAL_HOME && mkdir $DOCKER_REAL_HOME
ln -s $DOCKER_REAL_HOME /var/lib/docker

DOCKER_BRIDGE=kbr0
DOCKER_CONFIG=/etc/sysconfig/docker
 
## Install Docker
wget https://get.docker.com/builds/Linux/x86_64/docker-latest -O /usr/bin/docker
chmod +x /usr/bin/docker

cat <<EOF >$DOCKER_CONFIG
OPTIONS=--selinux-enabled=false
EOF

cat <<EOF >/usr/lib/systemd/system/docker.socket
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

source $DOCKER_CONFIG
cat <<EOF >/usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target docker.socket
Requires=docker.socket

[Service]
Type=notify
EnvironmentFile=-$DOCKER_CONFIG
ExecStart=/usr/bin/docker -d --bridge=$DOCKER_BRIDGE -H fd:// $OPTIONS
LimitNOFILE=1048576
LimitNPROC=1048576

[Install]
Also=docker.socket
EOF

systemctl daemon-reload
systemctl enable docker
systemctl start docker
