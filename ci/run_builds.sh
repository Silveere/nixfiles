#!/usr/bin/env bash
# shellcheck disable=SC2317
# ^ SC2317 (Command appears to be unreachable.)

set -Exo pipefail

err=0

set_error () {
	err=1
	pkill -s 0 -9 nix-eval-jobs || true
}

trap set_error ERR

system="$(nix eval --impure --raw --expr 'builtins.currentSystem')"


run_builds () {
	for i in "$@" ; do
		nix-fast-build --eval-workers 1 --no-nom --skip-cache --attic-cache main -f "$i"
		pkill -s 0 -9 nix-eval-jobs || true
	done
}

_build_systems () {
	case "$system" in
		# TODO this is messy and hard-coded, make an attribute set for
		# each system containing the specializations as well as the nospec ver
		x86_64-linux) run_builds \
			.\#nixosConfigurations.nullbox.config.specialisation.hyprland.configuration.system.build.toplevel \
			.\#nospec.nullbox.config.system.build.toplevel \
			.\#nixosConfigurations.slab.config.specialisation.{hyprland,nvidia}.configuration.system.build.toplevel \
			.\#nospec.slab.config.system.build.toplevel \
			.\#nixosConfigurations.nixos-wsl.config.system.build.toplevel \
			;;

		aarch64-linux) run_builds \
			.\#nixosConfigurations.rpi4.config.system.build.toplevel \
			;;
	esac
}



build_systems () {
	# system should be set in `nix develop` but just in case
	local system
	system="${system:-$(nix eval --impure --raw --expr 'builtins.currentSystem')}"
	#nix eval --json .#legacyPackages."${system}".specialisedNixosConfigurations --apply 'builtins.attrNames' \
	#	| jq -c '.[]' \
	#	| while read -r line ; do
	#		local build
	#		build="$(printf '%s' "$line" | jq -r)"
	#		run_builds ".#legacyPackages.${system}.specialisedNixosConfigurations.${build}"
	#	done
	run_builds ".#legacyPackages.${system}.specialisedNixosConfigurations"

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
