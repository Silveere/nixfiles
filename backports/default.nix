final: prev:
let
  inherit (final) callPackage;
  inherit (final.lib) recurseIntoAttrs;

  gimpPlugins-gap = recurseIntoAttrs (callPackage ./gimp-gap.nix {});
in {
  # apparently it's still broken. see https://github.com/NixOS/nixpkgs/issues/294707#issuecomment-1989857687
  # gimpPlugins = if prev.gimpPlugins.gap.version == "2.6.0" then gimpPlugins-gap else prev.gimpPlugins;
}
