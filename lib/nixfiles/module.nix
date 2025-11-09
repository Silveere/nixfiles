{
  lib,
  self,
  ...
} @ moduleAttrs: let
  inherit (lib) types;
  nixfiles-lib = (import ./.) {inherit lib self moduleAttrs;};
in {
  config = {
    # dendritic/lib
    nixfiles.lib = nixfiles-lib;
  };
}
