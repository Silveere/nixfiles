{ pkgs, config, lib, options, ... }@args:
let
  cfg = config.nixfiles;
in
{
  imports = [
    ./common
    ./hardware
    ./package-sets
    ./profile
    ./programs
    ./sessions
    ./testing
  ];
  config = {};
  options.nixfiles = {
    meta.wayland = lib.mkOption {
      description = "Whether to prefer wayland applications and configuration";
      default = false;
      example = true;
      type = lib.types.bool;
    };
  };
}
