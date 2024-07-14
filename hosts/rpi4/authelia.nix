{ config, lib, pkgs, ... }:
let
  inherit (lib) types;
  inherit (builtins) isNull;

  getUpstreamFromInstance = instance: let
    inherit (config.services.authelia.instances.${instance}.settings) server;
    inherit (server) port;
    host = if server.host == "0.0.0.0" then "127.0.0.1"
      else if lib.hasInfix ":" server.host then
        throw "TODO IPv6 not supported in Authelia server address (hard to parse, can't tell if it is [::])."
      else server.host;
  in "http://${host}:${port}";
in
{
  # authelia
  options.services.nginx = let
    mkAttrsOfSubmoduleOpt = module: lib.mkOption { type = with types; attrsOf (submodule module); };

    # make system config accessible from submodules
    systemConfig = config;

    # submodule definitions
    vhostModule = { name, config, ... }@attrs: {
      options = {
        locations = mkAttrsOfSubmoduleOpt (locationModule' attrs);
        authelia = {
          endpoint = {
            instance = lib.mkOption {
              description = ''
                Local Authelia instance to act as the authentication endpoint.
                This virtualHost will be configured to provide the
                public-facing authentication service.
              '';
              type = with types; nullOr str;
              default = null;
            };
            upstream = lib.mkOption {
              description = ''
                Internal URL of the Authelia endpoint to forward authentication
                requests to.
              '';
              type = with types; nullOr str;
              default = null;
            };
          };
          instance = lib.mkOption {
            description = ''
              Local Authelia instance to use. Setting this option will
              automatically configure Authelia on the specified virtualHost
              with the given instance of Authelia.
            '';
            type = with types; nullOr str;
            default = null;
          };
          upstream = lib.mkOption {
            description = ''
              Internal URL of the Authelia endpoint to forward authorization
              requests to. This should not be the public-facing authentication
              endpoint URL.
            '';
          };
        };
      };
      config = {
        authelia.upstream = lib.mkIf (!(isNull config.authelia.instance))
          (getUpstreamFromInstance config.authelia.instance);
        authelia.endpoint.upstream = lib.mkIf (!(isNull config.authelia.endpoint.instance))
          (getUpstreamFromInstance config.authelia.endpoint.instance);
      };
    };

    locationModule' = vhostAttrs: { name, config, ... }: let
      vhostConfig = vhostAttrs.config;
    in {
    };

  in {
    virtualHosts = mkAttrsOfSubmoduleOpt vhostModule;
  };

  # TODO check if any vhosts have authelia configured
  config = lib.mkIf false {

    assertions = [
      # TODO vhost cannot be both auth endpoint and regular reverse proxy
    ];
  };
}
