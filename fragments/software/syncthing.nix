{ config, lib, pkgs, ...}:
{
  services.syncthing = {
    enable = lib.mkDefault true;
    user = lib.mkDefault "nullbite";
    dataDir = lib.mkDefault "/home/nullbite/Documents";
    configDir = lib.mkDefault "/home/nullbite/.config/syncthing";
  };
}
