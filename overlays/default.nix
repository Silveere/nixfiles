{
  config,
  lib,
  ...
}: let
  inherit (lib) composeManyExtensions;
  cfg = config.flake.overlays;
in {
  imports = [
    ./mitigations.nix
    ./backports.nix
    ./modpacks.nix
  ];
  config.flake.overlays = {
    default = with cfg; composeManyExtensions [
      backports
      mitigations
    ];
  };
}
