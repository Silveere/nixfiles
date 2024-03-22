{ pkgs, lib, config, ... }:
let
  cfg = config.nixfiles.packageSets.productivity;
  inherit (lib) optionals;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; optionals config.nixfiles.meta.graphical [
      libreoffice-fresh
      obsidian
    ] ++ [
      pandoc
    ];
  };

  options.nixfiles.packageSets.productivity.enable = lib.mkEnableOption "the productivity package set";
}
