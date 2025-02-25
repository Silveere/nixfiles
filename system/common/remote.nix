{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfiles.common.remoteAccess;
in {
  config = lib.mkIf cfg.enable {
    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
      };
    };

    programs.mosh = {
      enable = true;
      openFirewall = true;
    };

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    networking.wireguard.enable = true;
  };
  options = {
    nixfiles.common.remoteAccess.enable = lib.mkEnableOption "remote access options";
  };
}
