{
  pkgs,
  lib,
  config,
  osConfig ? {},
  options,
  nixpkgs,
  ...
}: let
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
            url = "file://${config.nixfiles.path}";
          };
        };
      };

      # lorri enhances direnv with a background daemon
      # (so i don't have to WAIT A YEAR FOR MY DEVSHELL)
      services.lorri = {
        enable = lib.mkDefault true;
      };

      # direnv is a tool to automatically load shell environments upon entering
      # a directory. nix-direnv has an extensionn to keep nix shells in the
      # system's gcroots so shells can be used after a gc without rebuilding.
      programs.direnv = {
        enable = lib.mkDefault true;
        nix-direnv.enable = lib.mkDefault true;
      };
    }

    (lib.mkIf standalone {
      home.sessionVariables.NIX_PATH = "nixpkgs=${nixpkgs}\${NIX_PATH:+:\${NIX_PATH}}";
      nix.registry = {
        nixpkgs-local = {
          exact = true;
          from = {
            id = "nixpkgs-local";
            type = "indirect";
          };
          to = {
            type = "path";
            path = "${nixpkgs.outPath}";
          };
        };
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
