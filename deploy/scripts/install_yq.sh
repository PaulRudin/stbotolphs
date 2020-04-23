#!/bin/sh
wget https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64 -O /tmp/yq
sudo install -m 755 /tmp/yq /usr/local/bin/yq

