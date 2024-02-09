{ pkgs, config, lib, ...}:
let
  cfg = config.nixfiles.packageSets.fun;
in
{
  
  options.nixfiles.packageSets.fun = {
    enable = lib.mkEnableOption "fun package set";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cowsay
      uwufetch
      fortune
      pipes
      hollywood
      sl
      figlet
      aalib
      asciiquarium
    ] ++ lib.optionals config.services.xserver.enable [
      oneko
      bucklespring
    ] ++ lib.optionals config.sound.enable [
      espeak
    ];
  };
}
