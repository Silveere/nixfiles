{ config, lib, options, ... }:
let
  inherit (lib) types;
  cfg = config.nixfiles.session;
in
{
  imports = [
  ./hyprland.nix
  ./plasma.nix
  ];

  options.nixfiles.session = lib.mkOption {
    description = ''
      Desktop session to enable. This option serves as a convenient way to
      enable sessions in a mutually exclusive manner, e.g., for use with
      specialisations.
    '';
    type = with types; nullOr (enum (builtins.attrNames options.nixfiles.sessions));
    default = null;
    example = "hyprland";
  };

  config = lib.mkIf (!(builtins.isNull cfg)) {
    nixfiles.sessions.${cfg}.enable = true;
  };
}
