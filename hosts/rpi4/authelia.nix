{ config, lib, pkgs, ... }:
{
  # authelia
  options.services.nginx = let
    inherit (lib) types;
    mkAttrsOfSubmoduleOpt = module: lib.mkOption { type = with types; attrsOf (submodule module); };

    # make system config accessible from submodules
    systemConfig = config;

    # submodule definitions
    locationModule' = vhostAttrs: { name, config, ... }: {
    };
    vhostModule = { name, config, ... }@attrs: {
      options.locations = mkAttrsOfSubmoduleOpt (locationModule' attrs);
    };

  in {
    virtualHosts = mkAttrsOfSubmoduleOpt vhostModule;
  };

}
