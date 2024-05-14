{ lib, pkgs, config, outputs, osConfig ? {}, ... }:
let
  cfg = config.nixfiles.programs.mopidy;
in
{
  options.nixfiles.programs.mopidy = {
    enable = lib.mkEnableOption "mopidy configuration";
  };
  config = lib.mkIf cfg.enable {
    systemd.user.services = lib.mkIf config.services.mopidy.enable {
      mopidy.Service = {
        TimeoutStopSec = lib.mkDefault 10;
        ExecStartPre = pkgs.writeShellScript "mopidy-wait-net" ''
          until ${pkgs.curl}/bin/curl -fs https://www.google.com &>/dev/null ; do
            sleep 5
            ((counter++)) && ((counter==60)) && break
          done || true
          # don't know why i need a true here
        '';
      };
    };

    xdg.configFile."mopidy/mopidy.conf".enable = lib.mkForce false;
    services.mopidy = {
      enable = lib.mkDefault true;
      extensionPackages = with pkgs; [
        mopidy-mpd
        mopidy-iris
        mopidy-mpris
        mopidy-local
        mopidy-jellyfin
        mopidy-bandcamp
        mopidy-ytmusic
        mopidy-soundcloud
        mopidy-scrobbler
        # outputs.packages.${pkgs.system}.mopidy-autoplay
        mopidy-autoplay
      ];
    };
    home.packages = with pkgs; [
      (ncmpcpp.override { visualizerSupport = true; })
    ];
  };
}
