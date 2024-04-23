{ pkgs, ... }:
let
  inherit (pkgs) lib;
in
{
  types = (import ./types.nix) { inherit pkgs; };
  minecraft = (import ./minecraft.nix) { inherit pkgs; };
}
