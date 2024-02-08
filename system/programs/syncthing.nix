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
      user = lib.mkDefault "nullbite";
      dataDir = lib.mkDefault "/home/nullbite/Documents";
      configDir = lib.mkDefault "/home/nullbite/.config/syncthing";
    };
  };
}
