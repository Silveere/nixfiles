{
  self,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (lib) flatten pipe;
  inherit (builtins) map isPath toString fromJSON readFile hashString pathExists;

  # based on <nixpkgs/nixos/lib/systemd-lib.nix:584>
  makeTrigger = x:
    pipe x [
      flatten
      (map (x:
        if isPath x
        then "${x}"
        else x))
      toString
      (hashString "sha256")
    ];

  # lockfile schema:
  # json = {};
  # json.packagename = {};
  # json.packagename.hash = "...";
  # json.packagename.trigger = "(trigger string sha256)";

  lockfile = "${self.outPath}/hashes.lock";
  packageLock =
    if pathExists lockfile
    then fromJSON (readFile lockfile)
    else {};

  fodModule = {
    name,
    config,
    ...
  }: {
    options = {
      hash = mkOption {
        description = "Locked derivation hash";
        # source this from repo root "hashes.json"
        readOnly = true;
        default = packageLock.${name}.hash;
      };

      drvFunction = mkOption {
        description = ''
          Function which takes a hash and produces a fixed-output derivation.
        '';
        type = types.functionTo types.package;
        example = lib.literalExpression ''
          hash: pkgs.fetchFromGitHub {
            inherit hash;
            owner = "example";
            repo = "example";
            rev = "da39a3ee5e6b4b0d3255bfef95601890afd80709";
          }
        '';
      };

      # not sure if defining the package locally will work unless i make a
      # perSystem attribute; i will figure that out later but i needed to get
      # my thoughts out before i can't focus anymore.
      #
      # probably need to update the drv function to include either
      # `system` or `pkgs`.
      drv = mkOption {
        description = ''
          Locked derivation.
        '';
        default = config.drvFunction config.hash;
        readOnly = true;
      };

      fakeDrv = mkOption {
        description = ''
          Derivation with checksum set to lib.fakeHash.
        '';
        default = config.drvFunction lib.fakeHash;
        readOnly = true;
      };

      triggers = mkOption {
        description = ''
          An arbitrary list of items. If any item in the list changes, the package hash will be recomputed.
        '';
        type = types.listOf types.unspecified;
        default = builtins.map (x: config.drv."${x}" or "") ["url" "owner" "repo" "rev"];
        apply = makeTrigger;
      };
    };
  };
in {
  options = {
    fod = mkOption {
      description = ''
        List of fixed-output derivation configurations to track.
      '';
      type = types.attrsOf (types.submodule fodModule);
    };
  };
  config = {
    fod.test = {
    };
  };
}
