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
    pkgs-unstable = import nixfiles.inputs.nixpkgs-unstable {
      config.allowUnfree = true;
      inherit (final.stdenv.hostPlatform) system;
    };
    inherit (final) callPackage kdePackages lib;

    backport = let
      _callPackage = callPackage;
    in
      {
        pkgname,
        callPackage ? _callPackage,
        new ? pkgs-unstable,
        override ? {},
      }: let
        inherit (lib) getAttrFromPath;
        inherit (builtins) getAttr isString;

        getAttr' = name: attrs:
          if isString pkgname
          then getAttr name attrs
          else getAttrFromPath name attrs;
        oldPkg = getAttr' pkgname prev;
        newPkg = getAttr' pkgname pkgs-unstable;
      in
        if oldPkg.version == newPkg.version
        then oldPkg
        else (callPackage newPkg.override) override;

    backport' = pkgname: backport {inherit pkgname;};

    # defined locally to not pull in perl from unstable
    stripJavaArchivesHook =
      final.makeSetupHook {
        name = "strip-java-archives-hook";
        propagatedBuildInputs = [final.strip-nondeterminism];
      }
      ./strip-java-archives.sh;
  in {
    vesktop = backport' "vesktop";
    obsidian = backport {
      pkgname = "obsidian";
      override.electron = final.electron_28;
    };
    prismlauncher-unwrapped = backport {
      pkgname = "prismlauncher-unwrapped";
      inherit (kdePackages) callPackage;
      override = {
        # apple something idk why the package doesn't just ask for darwin and get it itself
        # maybe i should make a pull request that changes the params to `darwin, Cocoa ? darwin.apple_sdk.frameworks.Cocoa`
        inherit (final.darwin.apple_sdk.frameworks) Cocoa;
      };
    };
  };
in {
  config.flake.overlays.backports = overlay;
}
