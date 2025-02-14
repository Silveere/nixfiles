nixfiles: final: prev:
let
  pkgsStable = import nixfiles.inputs.nixpkgs.outPath { inherit (prev) system; };
  updateTime = nixfiles.inputs.nixpkgs-unstable.lastModified;

  inherit (final) lib callPackage fetchFromGitHub;
  inherit (lib) recurseIntoAttrs optionalAttrs
    versionOlder versionAtLeast;

  pkgsFromFlake = flake: (import flake.outPath) { inherit (prev) system; };
  pkgsFromInput = name: pkgsFromFlake nixfiles.inputs.${name};
  pickFixed = ours: theirs: if versionAtLeast ours.version theirs.version then ours else theirs;
  pickNewer = ours: theirs: if versionOlder theirs.version ours.version then ours else theirs;

  hold = now: days: ours: theirs: let
      seconds = days * 24 * 60 * 60;
      endTimestamp = now + seconds;
    in if now < endTimestamp then ours else theirs;

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
  nix-du = let
    old = prev.nix-du;
    new = (pkgsFromInput "nixpkgs-nix-du").nix-du;
  in pickNewer old new;

  gimp-with-plugins = gimp-with-plugins-good;

  nwg-displays = let
    stable = pkgsStable.nwg-displays;
    unstable = prev.nwg-displays;
    now = 1739114541;
  in hold now 7 stable unstable;

  libreoffice = let
    stable = pkgsStable.libreoffice;
    unstable = prev.libreoffice;
    now = 1739558971;
  in hold now 7 stable unstable;

  redlib = let
    redlib-new = final.callPackage nixfiles.packages.${prev.system}.redlib.override {};
    inherit (prev) redlib;
  in pickNewer redlib-new redlib;
}
