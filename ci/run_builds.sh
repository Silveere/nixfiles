#!/usr/bin/env bash

set -Exo pipefail

err=0

set_error () {
	err=1
}

trap set_error ERR

system="$(nix eval --impure --raw --expr 'builtins.currentSystem')"


run_builds () {
	for i in "$@" ; do
		nix-fast-build --eval-workers 1 --no-nom --skip-cache --attic-cache main -f "$i"
	done
}

build_systems () {
	case "$system" in
		x86_64-linux) run_builds \
			.\#nixosConfigurations.nullbox.config.system.build.toplevel \
			.\#nixosConfigurations.slab.config.system.build.toplevel \
			.\#nixosConfigurations.nixos-wsl.config.system.build.toplevel \
			;;

		aarch64-linux) run_builds \
			.\#nixosConfigurations.rpi4.config.system.build.toplevel \
			;;
	esac
}

build_packages () {
	run_builds .\#packages."${system}".redlib
}


if [[ "$#" -ne 0 ]] ; then
	until [[ "$#" -le 0 ]]; do
		case "$1" in
			pkgs|packages) DO_PACKAGES=1;;
			config) DO_CONFIG=1;;
		esac
		shift
	done
else
	DO_PACKAGES=1
	DO_CONFIG=1
fi

if [[ -n "${DO_CONFIG:+x}" ]] ; then build_systems; fi
if [[ -n "${DO_PACKAGES:+x}" ]] ; then build_packages; fi

exit $err
