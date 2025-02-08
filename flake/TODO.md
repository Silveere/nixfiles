# flake-parts TODO

- Move logic for generating system/home configs to module (most important,
  reason i wanted to use flake-parts)
	- Move common default args from the awful wrapper function to dedicated options:
		- default module imports
		- "common" module
			- currently defines stateVersion, nixpkgs.config.allowUnfree, a few others
		- make default module path configurable, but still default to
		  `./hosts/${hostname}/configuration.nix`
		- make "entrypoint" (`./system`, `./home/standalone.nix`, etc) configurable
		- make nixfiles home manager initialization a configurable option
		- specialArgs (i want to deprecate this but one thing at a time)
		- define system "types" and generate all of them internally using lazy
		  eval. export a specific one to the flake outputs.
			- generate as something like `nixfiles.hosts.<name>.outputs`
			- `flake.nixosConfigurations.<name>` is set from `nixfiles.hosts.<name>.output`
			- default chosen by option like `nixfiles.hosts.<name>.type`
			- types:
				- normal
				- WSL
				- ISO image
	- define deploy-rs outputs in same section as hosts
	- make common, central interface for configuring overlays to be consumed by
	  various parts of flake, move hard-coded overlays out of common module
		- literally just a list, maybe process it using lib.composeManyExtensions
- some top-level config is okay (e.g., defining hosts using nixfiles options).
  hide away all of the internal logic into imported modules.
- move random functions into nixfiles lib
- move top-level universal configs (username, mobileTimeZone) into option
  (honestly, this alone makes flake-parts worth it)
