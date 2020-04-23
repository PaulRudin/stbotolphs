#!/bin/sh
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.12.1/kubeseal-linux-amd64 -O /tmp/kubeseal
sudo install -m 755 /tmp/kubeseal /usr/local/bin/kubeseal
