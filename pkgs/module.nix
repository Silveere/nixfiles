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
    }: {
      packages = {
        lucem = pkgs.callPackage ./lucem {};
        magiskboot = pkgs.callPackage ./magiskboot {};
        ksud = pkgs.callPackage ./ksud {};
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
