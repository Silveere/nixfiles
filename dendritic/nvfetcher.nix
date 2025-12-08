{
  self,
  lib,
  flake-parts-lib,
  ...
}: let
  mkNvfetcherSources = pkgs: pkgs.callPackage (self.outPath + "/_sources/generated.nix") {};
  inherit
    (flake-parts-lib)
    mkPerSystemOption
    ;

  inherit (lib) mkOption;
in {
  options.perSystem = mkPerSystemOption ({
    system,
    pkgs,
    ...
  }: {
    _file = ./nvfetcher.nix;

    options.nixfiles.nvfetcherSources = mkOption {
      description = ''
        nvfetcher sources for system ${system}
      '';
      default = mkNvfetcherSources pkgs;
      readOnly = true;
    };
  });
  config = {
    flake.overlays.nvfetcher = final: prev: {
      nvfetcherSources = mkNvfetcherSources final;
    };
  };
}
