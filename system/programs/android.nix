{
  config,
  lib,
  pkgs,
  flakeConfig,
  ...
} @ args: let
  inherit (flakeConfig.nixfiles) vars;
  cfg = config.nixfiles.programs.adb;
in {
  options.nixfiles.programs.adb = {
    enable = lib.mkEnableOption "adb configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.adb.enable = true;
    users.users.${vars.username}.extraGroups = ["adbusers"];
  };
}
