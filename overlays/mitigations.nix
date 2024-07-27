nixfiles: final: prev:
let
  inherit (final) lib callPackage fetchFromGitHub;
  inherit (lib) recurseIntoAttrs optionalAttrs
    versionOlder versionAtLeast;

  pickFixed = ours: theirs: if versionAtLeast ours.version theirs.version then ours else theirs;
  pickNewer = ours: theirs: if versionOlder theirs.version ours.version then ours else theirs;

  optionalPkg = cond: val: if cond then val else null;

  gimp-with-plugins-good = let
    badPlugins = [ "gap" ];
    itemInList = list: item: lib.any (x: x==item) list;
    pluginFilter = name: value: (value.type or null == "derivation") && (!(itemInList badPlugins name)) && (!value.meta.broken);
    filteredPlugins = lib.filterAttrs pluginFilter prev.gimpPlugins;
    plugins = lib.mapAttrsToList (_: v: v) filteredPlugins;
  in prev.gimp-with-plugins.override { inherit plugins; };

# this also causes an infinite recursion and i have no idea why
# in nixfiles.inputs.nixpkgs.lib.filterAttrs (k: v: v != null) {
in {
  gimp-with-plugins = gimp-with-plugins-good;

  yt-dlp = let
    pkgs-y = (import nixfiles.inputs.nixpkgs-yt-dlp-2024.outPath) { inherit (prev) system;};
  in if ((builtins.compareVersions "2024.5.27" prev.yt-dlp.version) == 1)
    then (final.python3Packages.toPythonApplication pkgs-y.python3Packages.yt-dlp)
    else prev.yt-dlp;

  redlib = let
    redlib-new = final.callPackage nixfiles.packages.${prev.system}.redlib.override {};
    inherit (prev) redlib;
    notOlder = (builtins.compareVersions redlib-new.version redlib.version) >= 0;
  in if notOlder then redlib-new else redlib;
}
