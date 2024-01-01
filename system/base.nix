{ config, lib, pkgs, ...}:
{
  imports = [
    ./fragments/base.nix
    ./fragments/me.nix
  ];
}
