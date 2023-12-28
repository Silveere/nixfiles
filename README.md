# NullBite's NixOS Config
This is my personal NixOS config. Right now, it's just a basic flake which
imports a (mostly) normal stock NixOS configuration. The plan is to have three
separate levels of organization:

- **Fragments**: Configure one specific service/app/setting/etc., which has the
  potential to be used on more than one machine.
	- Settings that will only ever work on one machine (e.g., settings which
	  include disk UUIDs, PCIe bus IDs, etc) should be placed in a host
	  fragment instead.
- **Roles**: Define a "purpose" and import relevant fragments.
	- Roles aren't mutually exclusive; one system could pull in roles for,
	  e.g., desktop environment, gaming, and server
	- This is inspired by the concept of roles in Ansible
- **Hosts**: Configuration for individual hosts (obviously).
	- Each host shall have a folder containing its hardware-configuration.nix,
	  as well as one or more configurations specific to that machine. These
	  modules will serve the same purpose as fragments, but are exclusive to
	  that host
	- Custom configuration *MUST NOT* be placed in hardware-configuration.nix
	  for the same reason one should not directly edit
	  hardware-configuration.nix on a stock NixOS system. Most systems,
	  however, generally will have some options exclusive to them, and these should be placed in a 

At first I am going to migrate configuration into roles, and then as the configuration evolves, I will start to create fragments.

## `flake.nix` schema
`flake.nix` shall contain a "default" configuration for each host (using the
built-in selection of `nixos-rebuild`), as well as alternative config presets
for the host, if applicable.
