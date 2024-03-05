{ pkgs, config, lib, options, osConfig ? { }, ... }@args:
let
  isStandalone = with builtins; !( (typeOf osConfig == "set") && hasAttr "home-manager" osConfig );
  cfg = config.nixfiles;
in
{
  imports = [
    ./common
    ./package-sets
    ./profile
    ./programs
    ./sessions
  ];
  config = {};
  options.nixfiles = {
    options = lib.mkOption {
      description = "home-manager options attrset for repl";
      default = options;
      readOnly = true;
    };
    meta.standalone = lib.mkOption {
      default = isStandalone;
      description = "Whether or not the home-manager installation is standalone (standalone installations don't have access to osConfig).";
      type = lib.types.bool;
      readOnly = true;
      internal = true;
    };
    meta.graphical = lib.mkOption {
      description = "Whether to enable graphical home-manager applications";
      type = lib.types.bool;
      default = (osConfig ? services && osConfig.services.xserver.enable);
      example = true;
    };
    meta.wayland = lib.mkOption {
      description = "Whether to prefer wayland packages and configuration";
      type = lib.types.bool;
      default = (lib.hasAttrByPath [ "nixfiles" "meta" "wayland" ] osConfig) && osConfig.nixfiles.meta.wayland;
      example = true;
    };
  };
}
