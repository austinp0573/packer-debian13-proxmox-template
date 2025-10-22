#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# let cloud-init finish first (often running apt)
cloud-init status --wait || true

# stop/disable apt timers that grab locks at boot
systemctl stop apt-daily.service apt-daily-upgrade.service || true
systemctl disable --now apt-daily.timer apt-daily-upgrade.timer || true

# wait for locks to clear
while pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null || \
      pgrep -x unattended-upgrade >/dev/null || \
      fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
      fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
  sleep 3
done

# recover any half-configured packages
dpkg --configure -a || true

# retry wrapper for apt-get
retry() { n=0; until "$@"; do n=$((n+1)); [ $n -ge 5 ] && exit 1; sleep 5; done; }

retry apt-get update -y
retry apt-get dist-upgrade -y
retry apt-get install -y qemu-guest-agent curl wget git htop tmux vim ca-certificates

systemctl enable qemu-guest-agent || true

apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*