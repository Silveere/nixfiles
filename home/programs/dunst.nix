{ config, lib, pkgs, ... }:
let
  cfg = config.nixfiles.programs.dunst;
  mkd = lib.mkDefault;
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
