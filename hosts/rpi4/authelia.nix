{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkIf optionalString;
  inherit (builtins)
    isNull
    any
    all
    attrValues
    toString
    ;

  inherit (config.services) nginx;

  validAuthMethods = [
    "regular"
    "basic"
  ];
  getUpstreamFromInstance =
    instance:
    let
      inherit (config.services.authelia.instances.${instance}.settings) server;
      port = server.port or 9091;
      host = server.host or "127.0.0.1";

      targetHost = 
        if host == "0.0.0.0" then
          "127.0.0.1"
        else if lib.hasInfix ":" host then
          throw "TODO IPv6 not supported in Authelia server address (hard to parse, can't tell if it is [::])."
        else
          host;
    in
    "http://${targetHost}:${toString port}";

  # use this when reverse proxying to authelia (and only authelia because i
  # like the nixos recommended proxy settings better)
  autheliaProxyConfig = pkgs.writeText "authelia-proxy-config.conf" ''
    ## Headers
    proxy_set_header Host $host;
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header X-Forwarded-URI $request_uri;
    proxy_set_header X-Forwarded-Ssl on;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Real-IP $remote_addr;

    ## Basic Proxy Configuration
    client_body_buffer_size 128k;
    # Timeout if the real server is dead.
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
    proxy_redirect  http://  $scheme://;
    proxy_http_version 1.1;
    proxy_cache_bypass $cookie_session;
    proxy_no_cache $cookie_session;
    proxy_buffers 64 256k;

    ## Trusted Proxies Configuration
    ## Please read the following documentation before configuring this:
    ##     https://www.authelia.com/integration/proxies/nginx/#trusted-proxies
    # set_real_ip_from 10.0.0.0/8;
    # set_real_ip_from 172.16.0.0/12;
    # set_real_ip_from 192.168.0.0/16;
    # set_real_ip_from fc00::/7;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    ## Advanced Proxy Configuration
    send_timeout 5m;
    proxy_read_timeout 360;
    proxy_send_timeout 360;
    proxy_connect_timeout 360;
  '';

  autheliaLocation = ''
    internal;

    ## Headers
    ## The headers starting with X-* are required.
    proxy_set_header X-Original-Method $request_method;
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header Content-Length "";
    proxy_set_header Connection "";

    ## Basic Proxy Configuration
    proxy_pass_request_body off;
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; # Timeout if the real server is dead
    proxy_redirect http:// $scheme://;
    proxy_http_version 1.1;
    proxy_cache_bypass $cookie_session;
    proxy_no_cache $cookie_session;
    proxy_buffers 4 32k;
    client_body_buffer_size 128k;

    ## Advanced Proxy Configuration
    send_timeout 5m;
    proxy_read_timeout 240;
    proxy_send_timeout 240;
    proxy_connect_timeout 240;
  '';
  autheliaLocationConfig = pkgs.writeText "authelia-location.conf" autheliaLocation;
  autheliaBasicLocationConfig = pkgs.writeText "authelia-location-basic.conf" ''
    ${autheliaLocation}

    # Auth Basic Headers
    proxy_set_header X-Original-Method $request_method;
    proxy_set_header X-Forwarded-Method $request_method;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header X-Forwarded-URI $request_uri;
  '';

  genAuthConfig =
    method:
    let
      snippet_regular = ''
        ## Configure the redirection when the authz failure occurs. Lines starting
        ## with 'Modern Method' and 'Legacy Method' should be commented /
        ## uncommented as pairs. The modern method uses the session cookies
        ## configuration's authelia_url value to determine the redirection URL here.
        ## It's much simpler and compatible with the mutli-cookie domain easily.

        ## Modern Method: Set the $redirection_url to the Location header of the
        ## response to the Authz endpoint.
        auth_request_set $redirection_url $upstream_http_location;

        ## Modern Method: When there is a 401 response code from the authz endpoint
        ## redirect to the $redirection_url.
        error_page 401 =302 $redirection_url;
      '';
    in
    ''
      ## Send a subrequest to Authelia to verify if the user is authenticated and
      # has permission to access the resource.

      auth_request /internal/authelia/authz${optionalString (method == "basic") "/basic"};

      ## Save the upstream metadata response headers from Authelia to variables.
      auth_request_set $user $upstream_http_remote_user;
      auth_request_set $groups $upstream_http_remote_groups;
      auth_request_set $name $upstream_http_remote_name;
      auth_request_set $email $upstream_http_remote_email;

      ## Inject the metadata response headers from the variables into the request
      ## made to the backend.
      proxy_set_header Remote-User $user;
      proxy_set_header Remote-Groups $groups;
      proxy_set_header Remote-Name $name;
      proxy_set_header Remote-Email $email;

      ${optionalString (method == "regular") snippet_regular}
    '';
  genAuthConfigPkg =
    method: pkgs.writeText "authelia-authrequest-${method}.conf" (genAuthConfig method);
in
{
  # authelia
  options.services.nginx =
    let
      mkAttrsOfSubmoduleOpt = module: lib.mkOption { type = with types; attrsOf (submodule module); };

      # make system config accessible from submodules
      systemConfig = config;

      # submodule definitions
      vhostModule =
        { name, config, ... }@attrs:
        {
          options = {
            locations = mkAttrsOfSubmoduleOpt (genLocationModule attrs);
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
                type = with types; nullOr str;
                default = null;
              };
              method = lib.mkOption {
                description = ''
                  Default Authelia authentication method to use for all locations
                  in this virtualHost. Authentication is disabled by default for
                  all locations if this is set to `null`.
                '';
                type = with types; nullOr (enum validAuthMethods);
                default = "regular";
                example = "basic";
              };
            };
          };
          config = {
            authelia.upstream = mkIf (!(isNull config.authelia.instance)) (
              getUpstreamFromInstance config.authelia.instance
            );
            authelia.endpoint.upstream = mkIf (!(isNull config.authelia.endpoint.instance)) (
              getUpstreamFromInstance config.authelia.endpoint.instance
            );

            forceSSL = lib.mkIf (!(isNull config.authelia.endpoint.upstream)) true;

            # authelia nginx internal endpoints
            locations =
              let
                api = "${config.authelia.upstream}/api/authz/auth-request";
              in
              lib.mkMerge [
                (lib.mkIf (!(isNull config.authelia.upstream)) {
                  # just setup both, they can't be accessed externally anyways.
                  "/internal/authelia/authz" = {
                    proxyPass = api;
                    recommendedProxySettings = false;
                    extraConfig = ''
                      include ${autheliaLocationConfig};
                    '';
                  };
                  "/internal/authelia/authz/basic" = {
                    proxyPass = "${api}/basic";
                    recommendedProxySettings = false;
                    extraConfig = ''
                      include ${autheliaBasicLocationConfig};
                    '';
                  };
                })
                (lib.mkIf (!(isNull config.authelia.endpoint.upstream)) {
                  "/" = {
                    extraConfig = ''
                      include "${autheliaProxyConfig}";
                    '';
                    proxyPass = "${config.authelia.endpoint.upstream}";
                    recommendedProxySettings = false;
                  };
                  "= /api/verify" = {
                    proxyPass = "${config.authelia.endpoint.upstream}";
                    recommendedProxySettings = false;
                  };
                  "/api/authz" = {
                    proxyPass = "${config.authelia.endpoint.upstream}";
                    recommendedProxySettings = false;
                  };
                })
              ];
          };
        };

      genLocationModule =
        vhostAttrs:
        { name, config, ... }:
        let
          vhostConfig = vhostAttrs.config;
        in
        {
          options.authelia.method = lib.mkOption {
            description = ''
              Authelia authentication method to use for this location.
              Authentication is disabled for this location if this is set to
              `null`.
            '';
            type = with types; nullOr (enum validAuthMethods);
            default = vhostConfig.authelia.method;
            example = "basic";
          };
          config =
            lib.mkIf
              (
                (!(lib.strings.hasPrefix "/internal/authelia/" name))
                && (!(isNull vhostConfig.authelia.upstream))
                && (!(isNull config.authelia.method))
              )
              {
                extraConfig = ''
                  include ${genAuthConfigPkg config.authelia.method};
                '';
              };
        };

    in
    {
      virtualHosts = mkAttrsOfSubmoduleOpt vhostModule;
    };

  # TODO check if any vhosts have authelia configured
  config =
    let
      # TODO later, there are only assertions here
      configured = any (
        vhost: (!(isNull vhost.authelia.upstream)) || (!(isNull vhost.authelia.endpoint.upstream))
      ) (attrValues nginx.virtualHosts);
    in
    mkIf true {
      assertions = [
        {
          assertion = all (
            vhost: (!(isNull vhost.authelia.upstream)) -> (isNull vhost.authelia.endpoint.upstream)
          ) (attrValues nginx.virtualHosts);
          message = "`services.nginx.virtualHosts.<name>.authelia.upstream` and `services.nginx.virtualHosts.<name>.authelia.endpoint.upstream` cannot be set at the same time.";
        }
        # {
        #   assertion = all (
        #     vhost: vhost.authelia.instance -> config.services.authelia.instances ? "${vhost.authelia.instance}"
        #   ) (attrValues nginx.virtualHosts);
        #   message = "`services.authelia.instances.<name>` must be configured if `services.nginx.virtualHosts.<name>.authelia.instance` is set.";
        # }
      ];
    };
}
