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

sudo sed -i -E '/^Components:.*\bmain\b/ s/\bmain\b/& contrib/' /etc/apt/sources.list.d/debian.sources

retry apt-get update -y
retry apt-get dist-upgrade -y
retry apt-get install -y qemu-guest-agent curl wget git htop tmux vim-nox ca-certificates

systemctl enable qemu-guest-agent || true

# htop configuration for debian user
install -d -m 0755 /home/debian/.config/htop
install -m 0644 /tmp/htoprc /home/debian/.config/htop/htoprc
chown -R debian:debian /home/debian/.config

# Add useful aliases for debian user
cat <<'EOF' >> /home/debian/.bash_aliases
# -----------------------
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# -----------------------
# File listing
alias ls='ls --color=auto'
alias ll='ls -lArthR'
alias la='ls -A'
alias l='ls -Alrth'

# -----------------------
# System info
alias cpu='lscpu | grep "Model name"'
alias mem='free -h'
alias disk='df -hT --total | grep -E "Filesystem|total"'
alias ports='sudo ss -tuln'
alias uptime='uptime -p'

# -----------------------
# Package management
alias update='sudo apt update && sudo apt full-upgrade -y'
alias cleanapt='sudo apt autoremove -y && sudo apt clean'
alias pkglist='dpkg --get-selections | grep -v deinstall'

# -----------------------
# Services / journal
alias syslog='sudo journalctl -p 3 -xb'
alias logs='sudo journalctl -xe'
alias s='sudo systemctl'
alias sc='sudo systemctl status'
alias sre='sudo systemctl restart'

# -----------------------
# Networking
alias myip="ip -brief address show"
alias pingg="ping -c 4 8.8.8.8"
alias netcheck='ping -c 1 1.1.1.1 && echo OK || echo FAIL'

# -----------------------
# Git shortcuts
#alias gs='git status'
#alias ga='git add .'
#alias gc='git commit -m'
#alias gp='git push'

# -----------------------
# Convenience
alias grep='grep --color=auto'
alias cls='clear'
alias please='sudo $(fc -ln -1)'
EOF

chown debian:debian /home/debian/.bash_aliases


apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*