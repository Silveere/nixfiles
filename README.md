# NullBite's NixOS Config
This is my personal NixOS config. Right now, it's just a basic flake which imports a (mostly) normal stock NixOS configuration. The plan is to have three separate levels of organization:
- **Fragments**: Configure one specific service/app/setting/etc.
- **Roles**: Define a "purpose" and import relevant fragments.
    - Roles aren't mutually exclusive; one system could pull in roles for, e.g., desktop environment, gaming, and server
	- This is inspired by the concept of roles in Ansible
- **Devices**: Configuration for individual devices (obviously).
	- I might decide to define this within flake.nix

At first I am going to migrate configuration into roles, and then as the configuration evolves, I will start to create fragments.
