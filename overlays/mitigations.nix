{
  config,
  lib,
  self,
  inputs,
  ...
}: let
  # TODO legacy refactor
  # not high priority, this still works well for this overlay.
  nixfiles = self;
  overlay = final: prev: let
    pkgsStable = import nixfiles.inputs.nixpkgs.outPath {
      inherit (prev) system;
      config.allowUnfree = true;
    };
    updateTime = nixfiles.inputs.nixpkgs-unstable.lastModified;

    inherit (final) callPackage fetchFromGitHub;
    inherit
      (lib)
      recurseIntoAttrs
      optionalAttrs
      versionOlder
      versionAtLeast
      ;

    pkgsFromFlake = flake: (import flake.outPath) {inherit (prev) system;};
    pkgsFromInput = name: pkgsFromFlake nixfiles.inputs.${name};
    pickFixed = ours: theirs:
      if versionAtLeast ours.version theirs.version
      then ours
      else theirs;
    pickNewer = ours: theirs:
      if versionOlder theirs.version ours.version
      then ours
      else theirs;

    hold = now: days: ours: theirs: let
      seconds = days * 24 * 60 * 60;
      endTimestamp = now + seconds;
    in
      if now < endTimestamp
      then ours
      else theirs;

    optionalPkg = cond: val:
      if cond
      then val
      else null;

    gimp-with-plugins-good = let
      badPlugins = ["gap"];
      itemInList = list: item: lib.any (x: x == item) list;
      pluginFilter = name: value: (value.type or null == "derivation") && (!(itemInList badPlugins name)) && (!value.meta.broken);
      filteredPlugins = lib.filterAttrs pluginFilter prev.gimpPlugins;
      plugins = lib.mapAttrsToList (_: v: v) filteredPlugins;
    in
      prev.gimp-with-plugins.override {inherit plugins;};
    # this also causes an infinite recursion and i have no idea why
    # in nixfiles.inputs.nixpkgs.lib.filterAttrs (k: v: v != null) {
  in
    {
      nix-du = let
        old = prev.nix-du;
        new = (pkgsFromInput "nixpkgs-nix-du").nix-du;
      in
        pickNewer old new;

      gimp-with-plugins = gimp-with-plugins-good;

      nwg-displays = let
        stable = pkgsStable.nwg-displays;
        unstable = prev.nwg-displays;
        now = 1739114541;
      in
        hold now 7 stable unstable;

      libreoffice = let
        stable = pkgsStable.libreoffice;
        unstable = prev.libreoffice;
        now = 1739558971;
      in
        hold now 7 stable unstable;

      gotenberg = let
        stable = pkgsStable.gotenberg;
        unstable = prev.gotenberg;
        now = 1745707083;
      in
        hold now 90 stable unstable;

      redlib = let
        redlib-new = final.callPackage nixfiles.packages.${prev.system}.redlib.override {};
        inherit (prev) redlib;
      in
        pickNewer redlib-new redlib;

      rustdesk-flutter = let
        stable = pkgsStable.rustdesk-flutter;
        unstable = prev.rustdesk-flutter;
        now = 1741899501;
      in
        hold now 7 stable unstable;
    }
    // (
      lib.genAttrs [
        "mopidyPackages"
        "mopidy"
        "mopidy-bandcamp"
        "mopidy-iris"
        "mopidy-jellyfin"
        "mopidy-local"
        "mopidy-moped"
        "mopidy-mopify"
        "mopidy-mpd"
        "mopidy-mpris"
        "mopidy-muse"
        "mopidy-musicbox-webclient"
        "mopidy-notify"
        "mopidy-podcast"
        "mopidy-scrobbler"
        "mopidy-somafm"
        "mopidy-soundcloud"
        "mopidy-spotify"
        "mopidy-subidy"
        "mopidy-tidal"
        "mopidy-tunein"
        "mopidy-youtube"
        "mopidy-ytmusic"
      ] (name: let
        pkgs-mopidy = (import inputs.nixpkgs-mopidy) {inherit (prev) system;};
        unstable = prev."${name}";
        stable = pkgs-mopidy."${name}";
        now = 1740786429;
      in
        # pin for at least 90 days because who knows when this will be fixed
        # https://github.com/mopidy/mopidy/issues/2183
        hold now 90 stable unstable)
    );
in {
  config.flake.overlays.mitigations = overlay;
}
