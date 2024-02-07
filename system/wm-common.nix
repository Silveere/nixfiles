{ pkgs, lib, config, options, ...}:
let
  inherit (lib) mkDefault;
in
{
  # Common options for standalone window managers; many of these (or
  # alternatives thereof) are pulled in by desktop environments.
  services = {
    power-profiles-daemon.enable = mkDefault true;
    blueman.enable = mkDefault config.hardware.bluetooth.enable;
  };
  programs = {
    nm-applet.enable = mkDefault config.networking.networkmanager.enable;
  };
}
