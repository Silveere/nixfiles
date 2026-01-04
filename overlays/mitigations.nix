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
      inherit (prev.stdenv.hostPlatform) system;
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

    pkgsFromFlake = flake: (import flake.outPath) {inherit (prev.stdenv.hostPlatform) system;};
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
      if updateTime < endTimestamp
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
    # gamescope-git =
    #   prev.gamescope.overrideAttrs (_:
    #   {
    #     src = prev.fetchFromGitHub {
    #       owner = "ValveSoftware";
    #       repo = "gamescope";
    #       rev = "1faf7acd90f960b8e6c816bfea15f699b70527f9";
    #       hash = "sha256-/JMk1ZzcVDdgvTYC+HQL09CiFDmQYWcu6/uDNgYDfdM=";
    #       fetchSubmodules = true;
    #     };
    #   });
  in {
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

    beets = let
      stable = pkgsStable.beets;
      unstable = prev.beets;
      now = 1759635362;
    in
      hold now 15 stable unstable;

    # redlib = let
    #   redlib-new = final.redlib-git;
    #   inherit (prev) redlib;
    # in
    #   pickNewer redlib-new redlib;

    # gamescope = let
    #   fixed = gamescope-git;
    #   broken = prev.gamescope;
    #   now = 1755470213;
    # in hold now 30 fixed broken;

    pcmanfm = let
      stable = pkgsStable.pcmanfm;
      unstable = prev.pcmanfm;
      now = 1752774627;
    in
      hold now 21 stable unstable;

    rustdesk-flutter = let
      stable = pkgsStable.rustdesk-flutter;
      unstable = prev.rustdesk-flutter;
      now = 1741899501;
    in
      hold now 7 stable unstable;

    forgejo-migrate = (import inputs.nixpkgs-forgejo.outPath {inherit (prev.stdenv.hostPlatform) system;}).forgejo;

    kodi = let
      stable = pkgsStable.kodi;
      unstable = prev.kodi;
      now = 1760162132;
    in
      hold now 7 stable unstable;

    tmuxp = let
      stable = pkgsStable.tmuxp;
      unstable = prev.tmuxp;
      now = 1762905155;
    in
      hold now 7 stable unstable;

    bucklespring-libinput = let
      stable = pkgsStable.bucklespring-libinput;
      unstable = prev.bucklespring-libinput;
      now = 1762905155;
    in
      hold now 30 stable unstable;

    krita = let
      stable = pkgsStable.krita;
      unstable = prev.krita;
      now = 1760377443;
    in
      hold now 7 stable unstable;

    feishin = let
      stable = pkgsStable.feishin;
      unstable = prev.feishin;
      now = 1762897691;
    in
      hold now 14 stable unstable;

    electron_38 = let
      stable = pkgsStable.electron_38;
      unstable = prev.electron_38;
      now = 1762897691;
    in
      hold now 14 stable unstable;

    signal-desktop = let
      stable = pkgsStable.signal-desktop;
      unstable = prev.signal-desktop;
      now = 1762897691;
    in
      hold now 14 stable unstable;

    hollywood = let
      stable = pkgsStable.hollywood;
      unstable = prev.hollywood;
      now = 1763229394;
    in
      hold now 7 stable unstable;

    tika = let
      stable = pkgsStable.tika;
      unstable = prev.tika;
      now = 1763622695;
    in
      hold now 7 stable unstable;

    vesktop = let
      patched = let
        # NixOS/nixpkgs#476347
        nixpkgs = prev.fetchFromGitHub {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "2e21f6c5797fcccfc1e8eced873aea8401a71135";
          hash = "sha256-bmDUBlqgpIAXQ0QFn1fWpurlc+j2sI+B5941PWsic3M=";
        };
        pkgs = (import nixpkgs) {inherit (prev.stdenv.hostPlatform) system;};
      in
        pkgs.vesktop;

      stable = patched;
      unstable = prev.vesktop;
      now = 1767537701;
    in
      hold now 7 stable unstable;

    oneko = let
      stable = pkgsStable.oneko;
      unstable = prev.oneko;
      now = 1767537701;
    in
      hold now 7 stable unstable;
  };
in {
  config.flake.overlays.mitigations = overlay;
}
