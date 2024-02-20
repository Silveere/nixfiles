{ pkgs, lib, config, osConfig ? {}, options, ...}:
let
  cfg = config.nixfiles.common.wm;
  inherit (lib) mkDefault;
in
{
  options.nixfiles.common.wm = {
    enable = lib.mkEnableOption "common window manager config";
  };
  config = lib.mkIf cfg.enable {
    # Common options for standalone window managers; many of these (or
    # alternatives thereof) are pulled in by desktop environments.
    programs = {
      swaylock = {
        enable = true;
      };
    };
    services = {
      udiskie = {
        enable = mkDefault true;
        automount = mkDefault false;
      };
    };
  };
}
