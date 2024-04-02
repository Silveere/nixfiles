nixfiles: final: prev:
let
  inherit (prev) lib callPackage fetchFromGitHub;
  inherit (prev.lib) recurseIntoAttrs optionalAttrs;
  isNewer = ref: ver: (builtins.compareVersions ver ref) == 1;

  gimp-with-plugins-good = let
    badPlugins = [ "gap" ];
    itemInList = list: item: lib.any (x: x==item) list;
    pluginFilter = name: value: (value.type or null == "derivation") && (!(itemInList badPlugins name)) && (!value.meta.broken);
    filteredPlugins = lib.filterAttrs pluginFilter prev.gimpPlugins;
    plugins = lib.mapAttrsToList (_: v: v) filteredPlugins;
  in prev.gimp-with-plugins.override { inherit plugins; };
in {
  gimp-with-plugins = gimp-with-plugins-good;
}
  # # can't optionalAttrs for version checks because it breaks lazy eval and causes infinite recursion
  # // {
  #   obsidian = let
  #     pkg = final.callPackage "${nixfiles.inputs.nixpkgs-unstable}/pkgs/applications/misc/obsidian" { electron = final.electron_28; };
  #   in if isNewer "1.4.16" prev.obsidian.version then prev.obsidian else pkg;
  # }
