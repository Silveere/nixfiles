{ pkgs, config, lib, ... }:
let
  cfg = config.nixfiles.profile.pc;
in
{
  options.nixfiles.profile.pc.enable = lib.mkEnableOption "the personal computer profile";
  config = lib.mkIf cfg.enable {
    nixfiles.profile.base.enable = lib.mkDefault true;
    nixfiles.binfmt.enable = lib.mkDefault true;
  };
}
