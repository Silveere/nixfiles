{ pkgs, config, lib, ... }:
{
  config = {
    networking.hostName = "nixos-wsl";
    nixfiles.profile.base.enable = true;
    networking.networkmanager.enable = false;
    programs.gnupg.agent = {
      enable = true;
      pinentryFlavor = "qt";
    };

    fonts.packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
      noto-fonts
      noto-fonts-cjk
    ];


    fileSystems."/mnt/wsl/instances/NixOS" = {
      device = "/";
      options = [ "bind" ];
    };
  };
}
