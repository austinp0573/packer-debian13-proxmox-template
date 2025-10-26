#!/usr/bin/env bash
set -euo pipefail

# htop config
install -d -m 0755 /home/debian/.config/htop
install -m 0644 /tmp/htoprc /home/debian/.config/htop/htoprc
chown -R debian:debian /home/debian/.config

# aliases
install -D -m 0644 /tmp/.bash_aliases /home/debian/.bash_aliases
chown debian:debian /home/debian/.bash_aliases

# uncomment below to include for all users
# install -D -m 0644 /tmp/.bash_aliases /etc/skel/.bash_aliases

mv /tmp/set-hostname-once.sh /usr/local/sbin/set-hostname-once.sh
chmod 755 /usr/local/sbin/set-hostname-once.sh
mv /tmp/set-hostname-once.service /etc/systemd/system/set-hostname-once.service
systemctl daemon-reload
systemctl enable set-hostname-once.service

