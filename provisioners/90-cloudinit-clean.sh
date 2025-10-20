#!/usr/bin/env bash
set -euo pipefail

# reset cloud-init so clones run first-boot config
cloud-init clean --logs
rm -rf /var/lib/cloud/*

# ensure unique machine-id on first boot
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id || true
sync