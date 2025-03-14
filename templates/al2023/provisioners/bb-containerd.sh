#!/bin/bash

set -o pipefail
set -o nounset
set -o errexit

MACHINE=$(uname -m)
if [ "$MACHINE" == "x86_64" ]; then
  ARCH="amd64"
elif [ "$MACHINE" == "aarch64" ]; then
  ARCH="arm64"
else
  echo "Unknown machine architecture '$MACHINE'" >&2
  exit 1
fi

# install containerd v2
curl -OL "https://github.com/containerd/containerd/releases/download/v2.0.2/containerd-2.0.2-linux-$ARCH.tar.gz"
sudo tar Cxzvf /usr/local "containerd-2.0.2-linux-$ARCH.tar.gz"

SERVICE_PATH="/lib/systemd/system/containerd.service"

sudo sed -i '/^After=/ s/$/ containerd-storage-setup.service/' $SERVICE_PATH
sudo sed -i 's|^ExecStart=.*|ExecStart=/usr/local/bin/containerd|' $SERVICE_PATH
