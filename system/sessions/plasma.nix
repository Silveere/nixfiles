{ config, lib, pkgs, ...}:
let
  sleep = "${pkgs.coreutils}/bin/sleep";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  inherit (lib) mkIf mkEnableOption mkForce mkDefault;
  cfg = config.nixfiles.sessions.plasma;
in
{
  # imports = [
  #   ./desktop-common.nix
  # ];

  options.nixfiles.sessions.plasma = {
    enable = mkEnableOption "KDE Plasma session";
  };

  config = mkIf cfg.enable {
    services.xserver.enable = true;
    services.displayManager.sddm.enable = mkDefault true;
    services.desktopManager.plasma6.enable = true;
    services.displayManager.defaultSession = "plasma";
    programs.kdeconnect.enable = mkDefault true;
    nixfiles.meta.wayland = true;

    xdg.portal.extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
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
  };
}
