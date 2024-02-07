{ pkgs, lib, config, osConfig, options, ...}:
let
  inherit (lib) mkDefault;
in
{
  # Common options for standalone window managers; many of these (or
  # alternatives thereof) are pulled in by desktop environments.
  services = {
    udiskie = {
      enable = mkDefault true;
      automount = mkDefault false;
    };
  };
}
