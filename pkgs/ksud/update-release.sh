#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl
# shellcheck shell=bash

set -Eeuxo pipefail

cd "$(realpath "$(dirname "$0")")"

# https://github.com/tiann/KernelSU/releases/download/v1.0.5/ksud-x86_64-linux-android

json_tmp="$(mktemp)"

base_url="https://github.com/tiann/KernelSU/releases/latest/download/"

for i in x86_64-unknown-linux-musl aarch64-unknown-linux-musl ; do
	file=ksud-"$i"
	release="$(curl -s -o /dev/null -w "%{redirect_url}\n" "$base_url$file")"
	hash="$(nix store prefetch-file --json "${release}" --option extra-experimental-features nix-command | jq .hash)"
	jq -n --arg release "${release}" --argjson hash "${hash}" --arg name "$i" \
		'{
			key: {
				"x86_64-unknown-linux-musl": "x86_64-linux",
				"aarch64-unknown-linux-musl": "aarch64-linux"
			}[$name],
			value: {
				url: $release,
				hash: $hash,
				version: (
					$release | match("releases/download/([^/]+)/").captures[0].string
				)
			}
		}' 
done | jq -s 'from_entries' > "$json_tmp"

mv -f "$json_tmp" lock.json
