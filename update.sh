#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update

set -Eeuxo pipefail

if [[ "$#" -ne 0 ]] ; then
	until [[ "$#" -le 0 ]]; do
		case "$1" in
			pkgs|packages) DO_PACKAGES=1;;
			flake) DO_FLAKE=1;;
		esac
		shift
	done
else
	DO_PACKAGES=1
	DO_FLAKE=1
fi

cd "$(dirname "$0")"


[[ -n "${DO_FLAKE:+x}" ]] && nix flake update || true

if [[ -n "${DO_PACKAGES:+x}" ]] ; then
	nix-update --flake redlib --version=branch=main
fi
