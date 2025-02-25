{
  pkgs,
  config,
  lib,
  inputs,
  nixpkgs,
  ...
}: let
  p5 = config.services.xserver.desktopManager.plasma5.enable;
  p6 = config.services.desktopManager.plasma6.enable;

  isNewer = ref: ver: ((builtins.compareVersions ver ref) == 1);

  # kernel update
  newKernelPackages = let
    pkgs-new = import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    };
  in
    pkgs-new.linuxPackages_latest;
in {
}
