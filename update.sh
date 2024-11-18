#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update

set -Eeuxo pipefail

cd "$(dirname "$0")"

nix flake update

nix-update --flake redlib --version=branch=main
