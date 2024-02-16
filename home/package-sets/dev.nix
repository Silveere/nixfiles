{ pkgs, lib, config, osConfig ? {}, ... }:
let
  cfg = config.nixfiles.packageSets.dev;
in
{
  options.nixfiles.packageSets.dev = {
    enable = lib.mkEnableOption "development package set";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      neovim
      ripgrep
      fd
      bat

      # none of these need to be in my PATH since i can use nix shells but it's
      # nice to have a repl and some generic tools globally available
      rust-bin.stable.latest.default
      python311Packages.ptpython
      python311
      lua
    ];
  };
}
