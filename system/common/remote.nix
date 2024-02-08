{ config, lib, pkgs, ... }:
let
  cfg = config.nixfiles.common.remoteAccess;
in
{
  config = lib.mkIf cfg.enable {
    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {

      };
    };

    services.tailscale.enable = true;

    networking.wireguard.enable = true;
  };
  options = {
    nixfiles.common.remoteAccess = lib.mkEnableOption "remote access options" ; };
}
