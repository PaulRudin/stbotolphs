#!/bin/sh
wget https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl -O /tmp/kubectl
sudo install -m 755 /tmp/kubectl /usr/local/bin/kubectl

