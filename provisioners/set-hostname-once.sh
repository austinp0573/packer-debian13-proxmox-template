#!/usr/bin/env bash
set -e

# only run once (service also guards this, but double-safety)
[ -f /etc/hostname.seeded ] && exit 0

# generate randomized hostname
hn="debian13-base-$(tr -dc 'a-z' </dev/urandom | head -c2)$(tr -dc '0-9' </dev/urandom | head -c2)"

# apply it system-wide
hostnamectl set-hostname "$hn"
echo "$hn" > /etc/hostname

# update /etc/hosts to match
if grep -q "^127\.0\.1\.1" /etc/hosts; then
  sed -i -E "s/^127\.0\.1\.1.*/127.0.1.1\t$hn/" /etc/hosts
else
  echo -e "127.0.1.1\t$hn" >> /etc/hosts
fi

# mark as done
touch /etc/hostname.seeded