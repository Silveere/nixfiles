{ lib, pkgs, config, inputs, ... } @args:
let
  cfg = config.nixfiles.programs.comma;
in
{
  imports = [
    inputs.nix-index-database.hmModules.nix-index
  ];

  options.nixfiles.programs.comma = {
    enable = lib.mkEnableOption "comma";
  };

  config = {
    programs.nix-index.symlinkToCacheHome = lib.mkDefault cfg.enable;
    home.packages = with pkgs; lib.optionals cfg.enable [
      comma
    ];
  };
}
