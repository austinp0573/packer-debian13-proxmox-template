#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get dist-upgrade -y
apt-get install -y qemu-guest-agent curl wget git htop tmux vim-gtk3 ca-certificates

# enable qemu-guest-agent service
systemctl enable qemu-guest-agent || true

# remove unneccessary dependencies to keep things lean
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*