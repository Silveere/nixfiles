{lib, ...}: let
  inherit (lib) types;
  nixfiles-lib = (import ./.) {inherit lib;};
in {
  options.nixfiles.lib = lib.mkOption {
    description = "nixfiles library";
    type = types.attrs;
    readOnly = true;
    default = nixfiles-lib;
  };

  config._module.args = {
    inherit nixfiles-lib;
  };
}
