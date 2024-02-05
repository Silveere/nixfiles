{ nixpkgs, system, ... }:
let
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) callPackage;
in
{
  google-fonts = callPackage ./google-fonts { };
}
