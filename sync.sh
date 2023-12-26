#!/usr/bin/env bash
sudo rsync -rlptDHAXviP ~/git/nixos-config/ /etc/nixos/ --exclude='*.example' --exclude='.git' --exclude=".gitignore" --exclude="sync.sh"
