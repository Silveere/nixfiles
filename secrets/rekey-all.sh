#!/usr/bin/env bash

set -Eeuxo pipefail
cd "$(realpath "$(dirname "$0")")"
ssh_key="${1:-$HOME/.ssh/id_rsa}"

# safely create an in-memory tmpfile for the ssh key
tmpfile="$(mktemp -p "${XDG_RUNTIME_DIR:-/run/user/$UID}")"
chmod 600 "$tmpfile"
exec {tmp_fd}<>"$tmpfile"
rm "$tmpfile"
unset tmpfile
tmp="/dev/fd/$tmp_fd"
unset tmp_fd

cat "$ssh_key" > "$tmp"
ssh-keygen -p -f $tmp -N ""

agenix -i "$tmp" -r
