{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.nixfiles.common.busybox;
in {
  options.nixfiles.common.busybox.enable =
    lib.mkEnableOption ""
    // {
      description = ''
        Whether to install Busybox into the system environment as a very low
        priority fallback for common commands. This should *never* override a
        user-installed package.
      '';
    };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      lib.mkOrder 50 [
        busybox
      ];
  };
}
