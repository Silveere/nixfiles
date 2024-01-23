{ lib, pkgs, config, inputs, ... } @args:
{
  imports = [
    inputs.nix-index-database.hmModules.nix-index
  ];

  home.packages = with pkgs; [
    comma
  ];
}
