{ pkgs, lib, config, ... }:
let
  cfg = config.nixfiles.programs.unbound;
in
{
  options.nixfiles.programs.unbound = {
    enable = lib.mkEnableOption "unbound DNS server configuration";
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.dns = lib.mkDefault "none";
    services.unbound = {
      enable = true;
      settings = {
        server = {
          prefetch = true;
        };
      };
    };
  };
}
