{
  config,
  lib,
  inputs,
  ...
}: let
  overlayType = lib.mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
  };
in {
  options.nixfiles.common.overlays = lib.mkOption {
    description = "List of overlays shared between various parts of the flake.";
    type = lib.types.listOf overlayType;
    default = [];
  };
}
