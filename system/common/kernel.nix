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
    boot.kernelParams = lib.optionals cfg.zswap.enable [
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.shrinker_enabled=1"
    ];
  };
}
