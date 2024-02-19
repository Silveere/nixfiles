{ pkgs, lib, config, ... }:
let
  cfg = config.nixfiles.cachix;
in
{
  options.nixfiles.cachix.enable = lib.mkOption {
    description = "Whether to enable the Cachix derivation cache";
    type = lib.types.bool;
    default = true;
    example = false;
  };
  config = lib.mkIf cfg.enable {
    nix.settings = {
      substituters = [
        "https://hyprland.cachix.org"
      ];

      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };
}
