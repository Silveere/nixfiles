pkgs:
let
  inherit (pkgs) lib;
  inherit (lib.types) mkOptionType;
  inherit (lib.options) mergeEqualOption;
in
{
  flake = mkOptionType {
    name="flake";
    description="Nix flake";
    descriptionClass = "noun";
    merge = mergeEqualOption; check = (value: value._type or "" == "flake"); };
}
