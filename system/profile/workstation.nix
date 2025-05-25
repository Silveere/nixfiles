{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.nixfiles.profile.workstation;
  inherit (lib) mkDefault;
in {
  options.nixfiles.profile.workstation.enable =
    lib.mkEnableOption "workstation (featureful PC) profile"
    // {
      description = ''
        Whether to enable the workstation (featureful PC) profile. This profile
        enables the base PC profile, as well as installs and configures various
        other programs for a more complete computing experience.
      '';
    };
  config = lib.mkIf cfg.enable {
    nixfiles.profile.pc.enable = lib.mkDefault true;
    nixfiles.packageSets.multimedia.enable = lib.mkDefault true;
    nixfiles.programs.syncthing.enable = lib.mkDefault true;

    # probably unnecessary, this will be enabled by whatever session i use
    # Enable the X11 windowing system.
    # services.xserver.enable = true;

    environment.systemPackages = with pkgs; [
      arc-theme
      wl-clipboard
      xclip
    ];

    # this solves some inconsistent behavior with xdg-open
    xdg.portal.xdgOpenUsePortal = true;

    # Enable flatpak
    services.flatpak.enable = mkDefault true;

    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      font-awesome
      noto-fonts-cjk-sans
      (google-fonts.override {fonts = ["NovaSquare"];})
      twitter-color-emoji
    ];

    hardware.flipperzero.enable = true;

    # TODO this should be defined in home-manager or not at all probably
    # FIXME also my name is hardcoded
    users.users.nullbite = {
      packages = with pkgs; [
        firefox
      ];
    };
  };
}
