#!bin/sh
IP=$(hostname -I | awk '{print $1}')

KUBE_LOGTOSTDERR=true
KUBE_LOG_LEVEL=4
KUBE_MASTER=${IP}:8080

cat <<EOF >/usr/lib/systemd/system/scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/bin/kube-scheduler \\
    --logtostderr=${KUBE_LOGTOSTDERR} \\
    --v=${KUBE_LOG_LEVEL} \\
    --master=${KUBE_MASTER}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable scheduler
systemctl start scheduler