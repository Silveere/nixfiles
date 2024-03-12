final: prev:
let
  inherit (final) callPackage;
  inherit (final.lib) recurseIntoAttrs;

  gimpPlugins-gap = recurseIntoAttrs (callPackage ./gimp-gap.nix {});
in {
  gimpPlugins = if prev.gimpPlugins.gap.version == "2.6.0" then gimpPlugins-gap else prev.gimpPlugins;
}
