{ config, lib, pkgs, ...}:
let
  sleep = "${pkgs.coreutils}/bin/sleep";
  systemctl = "${pkgs.systemd}/bin/systemctl";
in
{
  imports = [
    ./desktop-common.nix
  ];

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.displayManager.defaultSession = "plasmawayland";
  programs.kdeconnect.enable = true;

  systemd.user = {
    services.restart-xdg-desktop-portal-kde = {
      enable = true;
      description = "hack to fix xdg-desktop-portal on kde";
      wantedBy = [ "graphical-session.target" ];
      after = [ "plasma-core.target" "xdg-desktop-portal.service" ];
      requisite = [ "plasma-core.target" ];

      serviceConfig = {
        ExecStart = [
          "${sleep} 5"
          "${systemctl} --user restart xdg-desktop-portal.service"
        ];
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # this fixes tiny file dialogs for Minecraft
    libsForQt5.kdialog
  ];
}
