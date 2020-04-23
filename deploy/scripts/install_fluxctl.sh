#!/bin/sh
wget https://github.com/fluxcd/flux/releases/download/1.19.0/fluxctl_linux_amd64 -O /tmp/fluxctl
sudo install -m 755 /tmp/fluxctl /usr/local/bin/fluxctl


