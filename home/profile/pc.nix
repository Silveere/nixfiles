{ pkgs, config, osConfig ? {}, lib, ...}:
let
  cfg = config.nixfiles.profile.pc;
  default = osConfig ? nixfiles && osConfig.nixfiles.profile.pc.enable;
in
{
  options.nixfiles.profile.pc.enable = lib.mkOption {
    description = "Whether to enable the personal computer profile";
    type = lib.types.bool;
    inherit default;
    example = true;
  };
  config = lib.mkIf cfg.enable {
    nixfiles = {
      profile.base.enable = true;
      programs = {
        mopidy.enable = true;
      };
      packageSets = {
        communication.enable = true;
        dev.enable = true;
      };
    };
  };
}
