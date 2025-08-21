# Hyprland TODO

## better power management
- write a daemon that listens for power events (`acpi_listen | grep
  '^ac_adapter'` and dispatches things
	- hibernate at 10%, 5% with cancellable prompt

## session
- better logouts
	- attempt to close all windows normally
	- after delay, show dialog with report of non-closed windows, ask if it is
	  fine to force close them
	- also make script callable manually, sometimes i just want to wipe my
	  session 
	  
# bar
## eww
- important widgets to keep:
	- power profile switcher
	- 
- widgets/functionality to add:
	- show workspaces
		- enumerate if possible. hardcoding is yucky but nix makes it better if
		  i have to
