pkgs:
let
  inherit (pkgs) lib;
in
{
  types = (import ./types.nix) pkgs;
  minecraft = (import ./minecraft.nix) pkgs;
}
