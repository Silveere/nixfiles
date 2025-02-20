{ config, lib, ... }:
{
  imports = [ ./legacy-module.nix ];
  config = {
    perSystem = { system, inputs', self', pkgs, ...}: {
      packages = {
        lucem = pkgs.callPackage ./lucem { };
      };
    };
  };
}
