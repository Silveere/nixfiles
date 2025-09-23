{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfiles.kernel;
  inherit (lib) mkDefault mkOption mkEnableOption;
in {
  options.nixfiles.kernel = {
    zswap.enable =
      mkEnableOption ""
      // {
        description = "Whether to configure zswap";
      };
  };

  config = {
    boot.extraModprobeConfig = lib.mkIf cfg.zswap.enable ''
      options zswap enabled=1 compressor=zstd shrinker_enabled=1
    '';
  };
}
