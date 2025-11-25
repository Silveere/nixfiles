{...} @ flakeArgs: let
  module = {
    config,
    lib,
    ...
  } @ nixosArgs: let
    cfg = config.nixfiles.filesystems.btrfs;
    inherit (lib) mkIf mkOption types;
    compressType = types.either types.bool (types.enum [
      "zlib"
      "lzo"
      "zstd"
    ]);

    fsModule = {config, ...}: {
      options.btrfs = {
        compress = mkOption {
          description = ''
            Whether to enable compression on this btrfs filesystem.
          '';
          default = cfg.compress;
          type = compressType;
        };
      };
      config = mkIf ((config.fsType == "btrfs")
        # this is not "bad programming" this is "it might not be a bool"
        && (config.btrfs.compress != false)) {
        options = let
          arg =
            if config.btrfs.compress == true
            then ""
            else "=${config.btrfs.compress}";
        in ["compress${arg}"];
      };
    };
  in {
    options.fileSystems = mkOption {
      type = types.attrsOf (types.submodule fsModule);
    };

    options.nixfiles.filesystems.btrfs = {
      compress = mkOption {
        description = ''
          Whether to enable compression on all mounted btrfs filesystems by default.
        '';
        type = compressType;
        default = false;
        example = "zstd";
      };
    };
  };
in {
  config.flake.modules.nixos.nixfiles = module;
}
