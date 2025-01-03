{ config, lib, pkgs, ...}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.nixfiles.programs.syncthing;
in
{
  options.nixfiles.programs.syncthing = {
    enable = mkEnableOption "Syncthing configuration";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = lib.mkDefault true;
      openDefaultPorts = lib.mkDefault true;
      user = lib.mkDefault "nullbite";
      dataDir = let
        user = config.services.syncthing.user;
        dir = config.users.users.${user}.home;
      in lib.mkDefault dir;
    };
  };
}
