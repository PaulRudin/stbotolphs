#!/bin/sh
wget https://github.com/bitnami/kubecfg/releases/download/v0.16.0/kubecfg-linux-amd64 -O /tmp/kubecfg
sudo install -m 755 /tmp/kubecfg /usr/local/bin/kubecfg

