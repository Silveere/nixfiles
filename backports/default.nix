final: prev:
let
  inherit (final) callPackage fetchFromGitHub;
  inherit (final.lib) recurseIntoAttrs;

  gimpPlugins-gap = let
    src = fetchFromGitHub {
      owner = "Scrumplex";
      repo = "nixpkgs";
      rev = "cca25fd345f2c48de66ff0a950f4ec3f63e0420f";
      hash="sha256-oat4TwOorFevUMZdBFgaQHx/UKqGW7CGMoOHVgQxVdM="; 
    };
  in recurseIntoAttrs (callPackage "${src}/pkgs/applications/graphics/gimp/plugins" {});
in {
  gimpPlugins = if prev.gimpPlugins.gap.version == "2.6.0" then gimpPlugins-gap else prev.gimpPlugins;
}
