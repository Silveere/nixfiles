{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.hardware.opengl;
in
{
  options.nixfiles.hardware.opengl.enable = lib.mkEnableOption "OpenGL configuration";
  config = lib.mkIf cfg.enable {
    # Enable OpenGL
    hardware.opengl = {
      enable = true;
      driSupport = lib.mkDefault true;
      driSupport32Bit = lib.mkDefault config.hardware.opengl.driSupport;
    };
  };
}
