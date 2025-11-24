{
  pkgs,
  lib,
  config,
  options,
  inputs, # TODO deprecated
  nixpkgs,
  vars, # TODO deprecated
  ...
}: let
  cfg = config.nixfiles.common.nix;
  inherit (config.age) secrets;

  enableSecrets = config.age.identityPaths != [];
in {
  options.nixfiles.common.nix = {
    enable = lib.mkEnableOption "common Nix configuration";
    registerNixpkgs = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      example = "true";
      description = "Whether to register the Nixpkgs revision used by Nixfiles to the system's flake registry and make it tye system's <nixpkgs> channel";
    };
    /*
       # TODO
    register = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      example = "true";
      description = "Whether to register Nixfiles to the system's flake registry";
    };
    */
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.registerNixpkgs {
      # this makes modern nix tools use the system's version of nixpkgs
      nix.registry = {
        # this keeps nixfiles-assets in the store so i can save some GitHub LFS
        # bandwidth
        nixfiles-assets = {
          exact = true;
          from = {
            id = "nixfiles-assets";
            type = "indirect";
          };
          flake = inputs.nixfiles-assets;
        };
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

          # used instead of `flake` option so produced flake.lock files are
          # portable
          to = {
            type = "github";
            owner = "NixOS";
            repo = "nixpkgs";
            rev = "${nixpkgs.rev}";
          };
        };
      };

      # this makes comma and legacy nix utils use the flake nixpkgs for ABI
      # compatibility becasue once `, vkcube` couldn't find the correct opengl
      # driver or something (also it reduces the download size of temporary shell
      # closures)
      nix.nixPath = ["nixpkgs=${nixpkgs}"] ++ options.nix.nixPath.default;
    })

    # it only makes sense to enable this if the netrc can be decrypted.
    (lib.mkIf enableSecrets {
      age.secrets.attic-netrc = {
        file = ../../secrets/attic-deploy.age;
        mode = "0555";
      };

      nix.settings = {
        inherit (vars.nix) substituters trusted-public-keys;

        netrc-file = secrets.attic-netrc.path;
      };
    })

    (lib.mkIf cfg.enable {
      # direnv is a tool to automatically load shell environments upon entering
      # a directory. nix-direnv has an extensionn to keep nix shells in the
      # system's gcroots so shells can be used after a gc without rebuilding.
      programs.direnv.enable = lib.mkDefault true;

      # fallback to building locally if binary cache fails (home-manager should be
      # able to handle simple rebuilds offline)
      nix.settings.fallback = lib.mkDefault true;

      # Allow use of nix binary cache for every derivation
      nix.settings.always-allow-substitutes = lib.mkDefault true;

      nix.settings = {
        # trust all members of wheel. this technically can give you root power,
        # but if you've compromised a member of wheel, you might as well already
        # be root; you could easily intercept a sudo call.
        trusted-users = [
          "@wheel"
          "root"
        ];
      };
    })
  ];
}
