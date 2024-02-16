{ lib, pkgs, config, osConfig ? { }, ... }:
let
  cfg = config.nixfiles.profile.base;
in
{
  # imports = [
  #   ./comma.nix
  # ];
  # home.username = "nullbite";
  # home.homeDirectory = "/home/nullbite";

  options.nixfiles.profile.base = {
    enable = lib.mkEnableOption "base profile";
  };

  config = lib.mkIf cfg.enable {
    nixfiles.programs.comma.enable = true;
    home.packages = with pkgs; [
      btop
    ];
  };
}
