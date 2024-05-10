{ pkgs, config, lib, options, osConfig ? { }, nixpkgs, home-manager, inputs, ... }@args:
let
  isStandalone = osConfig ? home-manager;
  cfg = config.nixfiles;
  flakeType = cfg.lib.types.flake;
in
{
  imports = [
    ./common
    ./package-sets
    ./profile
    ./programs
    ./sessions
  ];
  config = {};
  options.nixfiles = {
    options = lib.mkOption {
      description = "home-manager options attrset for repl";
      default = options;
      readOnly = true;
    };

    lib = lib.mkOption {
      description = "nixfiles library";
      default = (import ../lib/nixfiles) { inherit pkgs; };
      readOnly = true;
    };

    nixpkgs = lib.mkOption {
      description = "nixpkgs flake";
      type = flakeType;
      default = nixpkgs;
      example = "inputs.nixpkgs";
    };

    home-manager = lib.mkOption {
      description = "home-manager flake";
      type = flakeType;
      default = home-manager;
      example = "inputs.home-manager";
    };

    meta.standalone = lib.mkOption {
      default = isStandalone;
      description = "Whether or not the home-manager installation is standalone (standalone installations don't have access to osConfig).";
      type = lib.types.bool;
      readOnly = true;
      internal = true;
    };
    meta.graphical = lib.mkOption {
      description = "Whether to enable graphical home-manager applications";
      type = lib.types.bool;
      default = (osConfig ? services && osConfig.services.xserver.enable);
      example = true;
    };
    meta.wayland = lib.mkOption {
      description = "Whether to prefer wayland packages and configuration";
      type = lib.types.bool;
      default = (lib.hasAttrByPath [ "nixfiles" "meta" "wayland" ] osConfig) && osConfig.nixfiles.meta.wayland;
      example = true;
    };
    path = lib.mkOption {
      description = "The absolute path of the nixfiles flake";
      type = lib.types.str;
      default = "${config.home.homeDirectory}/nixfiles";
      defaultText = "\${config.home.homeDirectory}/nixfiles";
      example = "/etc/nixos";
    };
  };
}
