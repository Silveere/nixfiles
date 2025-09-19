{pkgs, ...}: let
  inherit (pkgs) callPackage callPackages;

  mopidyPackages = callPackages ./mopidy {
    python = pkgs.python3;
  };
in {
  inherit (mopidyPackages) mopidy-autoplay;
  google-fonts = callPackage ./google-fonts {};
  wm-helpers = callPackage ./wm-helpers {};
  atool = callPackage ./atool-wrapped {};
  nixfiles-assets = callPackage ./nixfiles-assets {};
  cross-seed = callPackage ./cross-seed {};
  magiskboot = callPackage ./magiskboot {};
  ksud = callPackage ./ksud {};
}
