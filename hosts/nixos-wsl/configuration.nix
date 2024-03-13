{ pkgs, config, lib, ... }:
{
  config = {
    networking.hostName = "nixos-wsl";

    nixfiles = {
      profile.base.enable = true;
      binfmt.enable = true;
    };

    networking.networkmanager.enable = false;
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-qt;
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
