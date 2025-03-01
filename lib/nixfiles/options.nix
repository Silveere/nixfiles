{pkgs, ...}: let
  inherit (pkgs) lib;
  inherit (lib.types) mkOptionType;
  inherit (lib.options) mkEnableOption;
in {
  mkDisableOption = description: mkEnableOption description // { default = true; example = false; };

  mkReadOnlyOption = {...} @ args:
    lib.mkOption ({
        readOnly = true;
      }
      // args);
}
