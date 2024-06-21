{ config, lib, ... }:
let
  cfg = config.nixfiles.profile.server;
  inherit (lib) mkEnableOption mkDefault;
  inherit (lib.types) bool int str;
in
{
  options.nixfiles.profile.server.enable = mkEnableOption "server profile";

  config = lib.mkIf cfg.enable {
    nixfiles.profile.base.enable = lib.mkDefault true;
  };
}
