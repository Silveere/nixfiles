pkgs:
let
  inherit (pkgs) lib;
in
{
  types = (import ./types.nix) pkgs;
}
