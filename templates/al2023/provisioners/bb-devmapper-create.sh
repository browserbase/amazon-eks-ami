#!/bin/bash
set -ex

sudo dnf install -y git make

# Block device to use for devmapper thin-pool
BLOCK_DEV=/dev/sdf
POOL_NAME=devpool
VG_NAME=containerd

# Install container-storage-setup tool
git clone https://github.com/projectatomic/container-storage-setup.git
cd container-storage-setup/
sudo make install-core
echo "Using version $(container-storage-setup -v)"

cd ../
rm -rf container-storage-setup

# Create configuration file
# Refer to `man container-storage-setup` to see available options
sudo tee /etc/sysconfig/docker-storage-setup << EOF
DEVS=${BLOCK_DEV}
VG=${VG_NAME}
CONTAINER_THINPOOL=${POOL_NAME}
DATA_SIZE=450G
CHUNK_SIZE=2M
MIN_DATA_SIZE=2G
AUTO_EXTEND_POOL=yes
POOL_AUTOEXTEND_THRESHOLD=80
POOL_AUTOEXTEND_PERCENT=20
EXTRA_STORAGE_OPTIONS="--storage-opt dm.use_deferred_deletion=true --storage-opt dm.use_deferred_removal=true --storage-opt dm.basesize=20G --storage-opt dm.lookahead=512K"
EOF

sudo tee /usr/lib/systemd/system/containerd-storage-setup.service << EOF
[Unit]
Description=Containerd Storage Setup
After=cloud-init.service
Before=containerd.service

[Service]
Type=oneshot
ExecStart=/usr/bin/container-storage-setup
EnvironmentFile=-/etc/sysconfig/docker-storage-setup

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable /usr/lib/systemd/system/containerd-storage-setup.service
