{pkgs, ...}: let
  inherit (pkgs) lib;
  inherit (lib.types) mkOptionType;
  inherit (lib.options) mergeEqualOption;
in {
  mkCheckedType = type:
    mkOptionType {
      name = "${type}";
      description = "Attribute set of type ${type}";
      descriptionClass = "noun";
      merge = mergeEqualOption;
      check = value: value._type or "" == "${type}";
    };
  flake = mkOptionType {
    name = "flake";
    description = "Nix flake";
    descriptionClass = "noun";
    merge = mergeEqualOption;
    check = value: value._type or "" == "flake";
  };
}
