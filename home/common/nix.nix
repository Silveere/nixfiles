{ pkgs, lib, config, osConfig ? { }, options, nixpkgs, ... }:
let
  cfg = config.nixfiles.common.nix;
  standalone = !(osConfig ? home-manager);
in {
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      nix.registry = {
        nixfiles = {
          exact = true;
          from = {
            id = "nixfiles";
            type = "indirect";
          };
          to = {
            type = "git";
            url = "file://${config.home.homeDirectory}/nixfiles";
          };
        };
      };
    }

    (lib.mkIf standalone {
      home.sessionVariables.NIX_PATH = "nixpkgs=${nixpkgs}\${NIX_PATH:+:\${NIX_PATH}}";
      nix.registry = {
        nixpkgs = {
          exact = true;
          from = {
            id = "nixpkgs";
            type = "indirect";
          };
          to = {
            type = "github";
            owner = "NixOS";
            repo = "nixpkgs";
            rev = "${nixpkgs.rev}";
          };
        };
      };
    })
  ]);
  options.nixfiles.common.nix = {
    enable = lib.mkEnableOption "Nix configuration";
  };
}
