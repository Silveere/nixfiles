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

  yt-dlp = let
    pkgs-y = (import nixfiles.inputs.nixpkgs-yt-dlp-2024.outPath) { inherit (prev) system;};
  in if ((builtins.compareVersions "2024.5.27" prev.yt-dlp.version) == 1)
    then (final.python3Packages.toPythonApplication pkgs-y.python3Packages.yt-dlp)
    else prev.yt-dlp;

  redlib = let
    redlib-new = final.callPackage nixfiles.packages.${prev.system}.redlib {};
    inherit (prev) redlib;
    notOlder = (builtins.compareVersions redlib-new.version redlib.version) >= 0;
  in if notOlder then redlib-new else redlib;
}
  # # can't optionalAttrs for version checks because it breaks lazy eval and causes infinite recursion
  # // {
  #   obsidian = let
  #     pkg = final.callPackage "${nixfiles.inputs.nixpkgs-unstable}/pkgs/applications/misc/obsidian" { electron = final.electron_28; };
  #   in if isNewer "1.4.16" prev.obsidian.version then prev.obsidian else pkg;
  # }
