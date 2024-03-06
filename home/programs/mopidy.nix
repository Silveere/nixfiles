{ lib, pkgs, config, outputs, osConfig ? {}, ... }:
let
  cfg = config.nixfiles.programs.mopidy;
in
{
  options.nixfiles.programs.mopidy = {
    enable = lib.mkEnableOption "mopidy configuration";
  };
  config = lib.mkIf cfg.enable {
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
      ];
    };
    home.packages = with pkgs; [
      (ncmpcpp.override { visualizerSupport = true; })
    ];
  };
}
