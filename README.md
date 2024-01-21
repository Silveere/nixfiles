# NullBite's NixOS Config
This is my personal NixOS config. Right now, it's just a basic flake which
imports a (mostly) normal stock NixOS configuration. <del>The plan is to have three
separate levels of organization:</del>

- <del>**Fragments**: Configure one specific service/app/setting/etc., which has the
  potential to be used on more than one machine.</del>
	- <del>Settings that will only ever work on one machine (e.g., settings which
	  include disk UUIDs, PCIe bus IDs, etc) should be placed in a host
	  fragment instead.</del>
- <del>**Roles**: Define a "purpose" and import relevant fragments.</del>
	- <del>Roles aren't mutually exclusive; one system could pull in roles for,
	  e.g., desktop environment, gaming, and server</del>
	- <del>This is inspired by the concept of roles in Ansible</del>
- <del>**Hosts**: Configuration for individual hosts (obviously).
	- Each host shall have a folder containing a `configuration.nix` and a
	  `hardware-configuration.nix`, and possibly a few host-specific fragments.</del>
	- <del>Custom configuration *MUST NOT* be placed in `hardware-configuration.nix`
	  for the same reason one should not directly edit
	  `hardware-configuration.nix` on a stock NixOS system. Most systems,
	  however, generally will have some options exclusive to them, and these
	  should be placed in the host's `configuration.nix` or a host fragment.</del>

<del>At first I am going to migrate configuration into roles, and then as the configuration evolves, I will start to create fragments.</del>

The above is outdated and I will rewrite it once I settle on a better way to organize this repo.

## `flake.nix` schema
`flake.nix` shall contain a "default" configuration for each host (using the
built-in selection of `nixos-rebuild`), as well as alternative config presets
for the host, if applicable.

## TODO

- Reorganize repo to use a more "standard" module layout.
	- [github:Misterio77/nix-config](https://github.com/Misterio77/nix-config) might be a good reference for a better module layout.
- Select entire desktop configuration via a single option and make bootable with specialisation.
	- Give each desktop a modularized configuration that can be enabled with an option.
	- figure out nixpkgs.lib.options.mkOption and add a string option that picks a desktop to use.
	- add Plasma, Hyprland, and maybe GNOME if I'm feeling silly (I'd probably never actually use it).
- make more things configurable as options once I figure out the above, it's probably cleaner than importing modules.
- Rewrite README.
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
