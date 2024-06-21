{ pkgs, config, lib, ... }:
let
  cfg = config.nixfiles.profile.pc;
in
{
  options.nixfiles.profile.pc.enable = lib.mkEnableOption "the personal computer profile";
  config = lib.mkIf cfg.enable {
    nixfiles.profile.base.enable = lib.mkDefault true;
    nixfiles.binfmt.enable = lib.mkDefault true;

    # networking.hostName = "nixos"; # Define your hostname.
    # Pick only one of the below networking options.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # FIXME find somewhere else to put this
    networking.networkmanager.enable = lib.mkDefault true;  # Easiest to use and most distros use this by default.
  };
}
