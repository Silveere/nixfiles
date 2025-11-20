{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfiles.programs.dunst;
  mkd = lib.mkDefault;

  dmenuCondition = config.programs.rofi.enable;
  dmenu =
    if config.programs.rofi.enable
    then "${lib.getExe' config.programs.rofi.package "rofi"} -dmenu"
    else null;
in {
  options.nixfiles.programs.dunst = {
    enable = lib.mkOption {
      description = "Whether to enable the dunst configuration";
      type = lib.types.bool;
      default = false;
      example = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.dunst = {
      enable = mkd true;
      settings = {
        global = {
          # behavior
          monitor = mkd 1;
          markup = mkd "full";
          show_age_threshold = mkd "60";
          dmenu = lib.mkIf dmenuCondition (mkd "${dmenu} -p dunst");

          # appearance
          follow = mkd "none";
          font = mkd "Ubuntu 10";
          alignment = mkd "left";
          word_wrap = mkd true;
        };
      };
    };
  };
}
