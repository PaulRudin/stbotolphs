#!/bin/sh
wget https://github.com/mozilla/sops/releases/download/v3.5.0/sops-v3.5.0.linux -O /tmp/sops
sudo install -m 755 /tmp/sops /usr/local/bin/kubeseal
