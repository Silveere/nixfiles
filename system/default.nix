{ pkgs, config, lib, options, ... }@args:
let
  cfg = config.nixfiles;
in
{
  imports = [
    ./temp-new
  ];
  config = {};
  options.nixfiles = {
  };
}
