{ pkgs, lib, config, ... }:
let
  cfg = config.nixfiles.programs.unbound;
in
{
  options.nixfiles.programs.unbound = {
    enable = lib.mkEnableOption "unbound DNS server configuration";
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.dns = "none";
    services.unbound.enable = true;
  };
}
