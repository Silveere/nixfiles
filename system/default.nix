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
  };
}
