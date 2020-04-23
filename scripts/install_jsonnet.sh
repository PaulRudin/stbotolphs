#!/usr/bin/bash
cd /tmp
wget https://github.com/google/jsonnet/releases/download/v0.15.0/jsonnet-bin-v0.15.0-linux.tar.gz
tar xzf jsonnet-bin-v0.15.0-linux.tar.gz
rm jsonnet-bin-v0.15.0-linux.tar.gz
chmod a+x jsonnet
sudo install jsonnet /usr/local/bin/jsonnet
        
