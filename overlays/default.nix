nixfiles:
let
  inherit (nixfiles.inputs.nixpkgs) lib;
  # this name is awful. maybe i don't know anything about functional
  # programming or something, but the naming isn't very self explanatory
  # - why is it "compose" instead of "combine"
  # - why is it "extensions" instead of "overlays"
  inherit (lib) composeManyExtensions;
in rec {
  backports = import ./backports.nix nixfiles;
  mitigations = import ./mitigations.nix nixfiles;
  default = composeManyExtensions [
    backports
    mitigations
  ];
}
