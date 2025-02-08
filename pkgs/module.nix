{
  inputs,
  self,
  config,
  lib,
  options,
  ...
}: let
  cfg = config.nixfiles.outputs.packages;
  inherit (lib) mapAttrs mkEnableOption mkIf;
in {
  options.nixfiles.outputs.packages = {
    enable =
      mkEnableOption ""
      // {
        description = ''
          Whether to generate the packages output.
        '';
        default = true;
      };
  };
  config = mkIf cfg.enable {
    perSystem = {
      system,
      inputs',
      self',
      pkgs,
      ...
    }: {
      packages = let
        inherit (pkgs) callPackage callPackages;

        # i forget how this works so i'm not messing with it.
        mopidyPackages = callPackages ./mopidy {
          python = pkgs.python3;
        };
      in
        (mapAttrs (_: v: callPackage v {}) {
          google-fonts = ./google-fonts;
          wm-helpers = ./wm-helpers;
          atool = ./atool-wrapped;
          nixfiles-assets = ./nixfiles-assets;
          redlib = ./redlib;
          cross-seed = ./cross-seed;
        })
        // {
          inherit (mopidyPackages) mopidy-autoplay;
        };
    };
  };
}
