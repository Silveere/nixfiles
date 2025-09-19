{
  config,
  lib,
  ...
}: {
  imports = [./legacy-module.nix];
  config = {
    perSystem = {
      system,
      inputs',
      self',
      pkgs,
      ...
    }: let
      sources = pkgs.callPackages ./_sources/generated.nix {};
      callPackage = pkgs.newScope {
        inherit sources;
      };
    in {
      packages = {
        lucem = callPackage ./lucem {};
        magiskboot = callPackage ./magiskboot {};
        ksud = callPackage ./ksud {};
        redlib = callPackage ./redlib {};
        redlib-git = callPackage ./redlib/override.nix {};
      };
    };

    flake = {
      overlays.new-packages = final: prev: let
        inherit (final) callPackage;
        currentSystem = config.perSystem "${prev.system}";
        flakePackages = currentSystem.packages;
        addPackages = packages: lib.genAttrs packages (package: callPackage flakePackages.${package}.override {});
      in
        addPackages [
          "lucem"
          "magiskboot"
          "ksud"
        ];
    };
  };
}
