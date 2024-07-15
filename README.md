# NullBite's NixOS Config
This is my personal NixOS config. Right now, it's just a <del>basic</del>
extremely overengineered flake which imports a (mostly) normal stock NixOS configuration.

Now that I have used NixOS for a month, I have learned a fair bit and have made
some organizational changes. <del>Currently, the repository is organized as
such</del> (I am in the process of migrating my config to this format, some
stuff may not match yet):

- Like any other Nix flake, `flake.nix` is the entrypoint for this repository.
	- The flake output has the following attributes, among others:
		- nixosModules: standard flake output
		- homeManagerModules: standard flake output
		- nixosConfigurations: standard flake output
		- inputs: all specified flake inputs
		- vars: attrset of variables that are passed to modules
	- The flake also has multiple helper functions:
		- `eachSystem :: (system -> attrset) -> attrset`: Generate an attrset
		  of default systems (used for packages)
		- `homeManagerInit`: Generate a NixOS Module that initializes
		  home-manager for a given user(s).
		- `mkSystem`: Generate a nixosConfiguration definition with some preset
		  options
		- `mkWSLSystem`: generate a system using `mkSystem` that has WSL
		  related options and modules enabled
	- The flake also defines a few options in the `let` clause that should be
	  shared and updated among multiple hosts.
- The repository is split into several directories:
	- The `hosts` directory contains configurations for each host, with a
	  layout similar to that of a flake-less `/etc/nixos/`. Additionally, each
	  host's unique modules can be placed in here however desired. There is
	  also a `home.nix` which specifies the home-manager configuration for the
	  main user.
	- The `system` and `home` directories respectively specify NixOS and
	  home-manager modules that are *not* portable. The default module for each
	  directory does not change any configuration by default, it just
	  introduces options, most of which configure larger sets of options.
		- Each directory may also contain smaller module "fragments"; small
		  chunks of config not worth creating an entire option for, and which
		  will not automatically be imported by `default.nix`.
	- The `pkgs` directory contains standard Nix packages which can be used in
	  any other configuration.
	- The `modules` directory contains portable modules which can be used in
	  any other configuration.
	- The `extras` directory contains random odds and ends which are not
	  directly related to the flake, but may come in handy when setting up a
	  new system or a non-NixOS system
- Custom options will be organized as follows:
	- All options apply to both NixOS and home-manager, unless otherwise
	  specified.
	- This seection is not extremely strict, but more of a general suggestion.
	  These option names may be subject to change.
	- "Private" options (non-portable options defined in `home/` and `system/`)
	  will be in the `nixfiles` "namespace", and will be divided into several
	  categories:
		- `nixfiles.desktopSession.<name>`: configuration for a desktop session
		  display (e.g., KDE Plasma, Hyprland, GNOME, Xfce)
		- `nixfiles.program.<name>`: configuration for a specific program
		- `nixfiles.profile.<name>`: general config sets
	- "Public" options (those for portable flake modules) follow standard
	  nixpkgs option naming conventions (e.g., services.<service>.enable).
	  These options are not namespaced.

## TODO

- Reorganize repo to use a more "standard" module layout.
	- [github:Misterio77/nix-config](https://github.com/Misterio77/nix-config) might be a good reference for a better module layout.
- Select entire desktop configuration via a single option and make bootable with specialisation.
	- Give each desktop a modularized configuration that can be enabled with an option.
	- figure out nixpkgs.lib.options.mkOption and add a string option that picks a desktop to use.
	- add Plasma, Hyprland, and maybe GNOME if I'm feeling silly (I'd probably never actually use it).
- make more things configurable as options once I figure out the above, it's probably cleaner than importing modules.
- Reorganize README bullets into headings
- make system ephemeral/stateless
	- The following command is able to successfully show any accumulated state on my system: <pre><code>sudo find  / -xdev \( -path /home -o -path /nix -o -path /boot \)  -prune -o \( -name flatpak -o -name boot.bak -o -path /var/log -o -name .cache \) \( -prune -print \) -o \( -type f \) -print</code></pre>
	- everything on my system should be declared in this repository or explicitly excluded from the system state
	- caches should probably be excluded, they exist for a reason and are essentially harmless compared to other forms of state
		- /var/cache
		- ~/.cache
	- logs should also be excluded (/var/log)
	- network configuration (wireguard, networkmanager, bluetooth) should be excluded
	- ssh host keys
	- print configuration
	- tailscale keys
	- coredumps
	- /root user and /home
	- /etc/machine-id
- configure /etc/supergfxd.conf with a oneshot systemd unit on boot bsaed on selected specialisation (should still be modifiable with supergfxctl but should be ephemeral)
