{ pkgs, config, lib, options, ... }@args:
let
  cfg = config.nixfiles;
in
{
  imports = [
  ];
  config = {};
  options.nixfiles = {
  };
}
