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
      inherit (pkgs) callPackage;
    in {
      packages = {
        lucem = callPackage ./lucem {};
        magiskboot = callPackage ./magiskboot {};
        ksud = callPackage ./ksud {};
        redlib-git = callPackage ./redlib/override.nix {};
        gamescope-git = callPackage ./gamescope {};
      };
    };

    flake = {
      overlays.new-packages = final: prev: let
        # redlib would probably cause an infinite recursion this needs to be
        # prev (or have some separate workaround for redlib if other packages
        # need to depend on each other)
        inherit (final) callPackage;
        currentSystem = config.perSystem "${prev.stdenv.hostPlatform.system}";
        flakePackages = currentSystem.packages;
        addPackages = packages: lib.genAttrs packages (package: callPackage flakePackages.${package}.override {});
      in
        addPackages [
          "lucem"
          "magiskboot"
          "ksud"
          "redlib-git"
          "gamescope-git"
        ];
    };
  };
}
