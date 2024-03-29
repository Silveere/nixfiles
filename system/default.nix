{ pkgs, config, lib, options, nixpkgs, home-manager, inputs, ... }@args:
let
  cfg = config.nixfiles;
  flakeType = cfg.lib.types.flake;
in
{
  imports = [
    ./common
    ./hardware
    ./package-sets
    ./profile
    ./programs
    ./sessions
    ./testing
    ./cachix.nix
    ./mitigations.nix

    # modules
    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];
  config = {};
  options.nixfiles = {
    meta.wayland = lib.mkOption {
      description = "Whether to prefer wayland applications and configuration";
      default = false;
      example = true;
      type = lib.types.bool;
    };

    lib = lib.mkOption {
      description = "nixfiles library";
      default = (import ../lib/nixfiles) pkgs;
      readOnly = true;
      type = lib.types.attrs;
    };

    nixpkgs = lib.mkOption {
      description = "nixpkgs flake";
      default = nixpkgs;
      type = flakeType;
      example = "nixpkgs";
    };

    home-manager = lib.mkOption {
      description = "home-manager flake";
      default = home-manager;
      type = flakeType;
      example = "home-manager";
    };
  };
}
