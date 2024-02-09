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
    standalone = lib.mkOption {
      default = isStandalone;
      description = "Whether or not the home-manager installation is standalone (standalone installations don't have access to osConfig).";
      type = lib.types.bool;
      readOnly = true;
      internal = true;
    };
  };
}
