{
  pkgs,
  config,
  lib,
  options,
  nixpkgs,
  home-manager,
  inputs,
  utils,
  ...
} @ args:
# ^ all these args are yucky and non-portable, replace them with a module
# called from the scope of the flake that brings relevant
# inputs/outputs/overlays/etc into scope. this might even make nixfiles
# portable (it still shouldn't be imported by other flakes probably)
let
  cfg = config.nixfiles;
  flakeType = cfg.lib.types.flake;
in {
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
    ./minecraft.nix # imports inputs.nix-minecraft
    inputs.impermanence.nixosModules.impermanence
    inputs.agenix.nixosModules.default
    inputs.lanzaboote.nixosModules.lanzaboote
    ./stylix.nix # imports inputs.stylix
  ];
  config = {};
  options.nixfiles = {
    meta.wayland = lib.mkOption {
      description = "Whether to prefer wayland applications and configuration";
      default = false;
      example = true;
      type = lib.types.bool;
    };

    utils = lib.mkOption {
      description = "nixpkgs `utils` argument passthrough";
      default = utils;
      readOnly = true;
    };

    workarounds.nvidiaPrimary = lib.mkOption {
      description = "Whether to enable workarounds for NVIDIA as the primary GPU";
      default = false;
      example = true;
      type = lib.types.bool;
    };

    lib = lib.mkOption {
      description = "nixfiles library";
      default = (import ../lib/nixfiles) {inherit pkgs;};
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
