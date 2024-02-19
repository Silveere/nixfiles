#!/usr/bin/env bash

state_gd_rebind=0

log() {
	echo "$@" >&2
}

handle_active_window() {
	case "$1" in 
		# geometry dash
		*'>>'steam_app_322170,*) log matched Geometry Dash ;;
	esac
}

handle() {
	case "$1" in
		activewindow*) handle_active_window "$1" ;;
	esac
};

socat - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | \
	while read -r line ; do handle "$line"; done
