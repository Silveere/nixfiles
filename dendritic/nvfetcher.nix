{ self, ... }:
let
  mkNvfetcherSources = pkgs: pkgs.callPackage (self.outPath + "/_sources/generated.nix") { };
in
{
  config = {
    flake.overlays.nvfetcher = final: prev: {
      nvfetcherSources = mkNvfetcherSources final;
    };
  };
}
