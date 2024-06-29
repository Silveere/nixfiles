{ config, lib, pkgs, ... }:
{
  imports = [
    ./gitea.nix
  ];
  config = {

    age.secrets.cloudflaredns = {
      file = ../../secrets/cloudflare-dns.age;
      group = "secrets";
    };

    age.secrets.htpasswd = {
      file = ../../secrets/htpasswd.age;
      group = "nginx";
      mode = "0750";
    };

    users.groups.secrets = {};
    users.users.acme.extraGroups = [ "secrets" ];

    security.acme = {
      acceptTerms = true;
      maxConcurrentRenewals = 1;

      defaults.email = "iancoguz@gmail.com";

      certs = {
        "protogen.io" = {
          credentialFiles = {
            "CLOUDFLARE_EMAIL_FILE" = pkgs.writeText "email" "iancoguz@gmail.com";
            "CLOUDFLARE_API_KEY_FILE" = config.age.secrets.cloudflaredns.path;
          };

          dnsProvider = "cloudflare";
          domain = "protogen.io";
          extraDomainNames = [
            "*.protogen.io"
            "nullbite.com"
            "*.nullbite.com"
            "nullbite.dev"
            "*.nullbite.dev"
            "nbt.sh"
            "*.nbt.sh"
          ];
        };
      };
    };

    users.users.nginx.extraGroups = [ "acme" ];

    networking.firewall.allowedTCPPorts = [
      80 443
      # this is needed for node to work for some reason
      8123
    ];

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;

      commonHttpConfig = ''
        port_in_redirect off;
      '';

      virtualHosts = let
        useACMEHost = "protogen.io";
        mkProxy = args@{ upstream ? "http://127.0.0.1:${builtins.toString args.port}", auth ? false, extraConfig ? {}, ... }:
        lib.mkMerge [
          {
            inherit useACMEHost;
            forceSSL = true;
            locations."/" = {
              proxyPass = upstream;
              proxyWebsockets = true;
            };
          }
          (lib.mkIf auth {
            basicAuthFile = config.age.secrets.htpasswd.path;
          })
          extraConfig
        ];

        # mkReverseProxy = port: {
        #   inherit useACMEHost;
        #   forceSSL = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:${builtins.toString port}";
        #     proxyWebsockets = true;
        #   };
        # };

        mkAuthProxy = port: mkProxy { inherit port; auth = true; };

        mkReverseProxy = port: mkProxy { inherit port; };
      in {
        # TODO change all these with a vim macro when i learn how to extend submodules
        "changedetection.protogen.io" = mkReverseProxy 5000;
        "firefly.protogen.io" = mkReverseProxy 8083;
        # firefly-import auth 8084
        "gitea.protogen.io" = mkReverseProxy 3000;
        # home assistant
        "hass.protogen.io" = mkReverseProxy 8123;
        "node.protogen.io" = mkReverseProxy 1880;
        # z2m auth 8124
        "z2m.protogen.io" = mkAuthProxy 8124;
        "room.protogen.io" = mkReverseProxy 8096;
        "deemix.protogen.io" = mkAuthProxy 6595;
        # libreddit auth 8087
        "libreddit.protogen.io" = mkAuthProxy 8087;
        "rss.protogen.io" = mkReverseProxy 8082;
        "blahaj.protogen.io" = mkReverseProxy 8086;
        # octoprint (proxy_addr is 10.10.1.8)
        "print.protogen.io" = mkProxy { auth = true; upstream = "http://10.10.1.8:80"; };
        # searx auth 8088 (none for /favicon.ico, /autocompleter, /opensearch.xml)
        "search.protogen.io".locations."/".return = "302 https://searx.protogen.io$request_uri";
        "searx.protogen.io" = let
          port = 8088;
        in mkProxy { auth = true; inherit port; extraConfig = {
          locations = lib.genAttrs [ "/favicon.ico" "/autocompleter" "/opensearch.xml" ] (attr: {
            proxyPass = "http://localhost:${builtins.toString port}";
            proxyWebsockets = true;
            extraConfig = ''
              auth_basic off;
            '';
          });
        };};
        # nbt.sh alias proot.link 8090
        "nbt.sh" = mkProxy { port = 8090; extraConfig.serverAliases = [ "proot.link" ]; };
        # admin.nbt.sh alias admin.proot.link 8091 auth
        "admin.nbt.sh" = mkProxy { auth = true; port = 8091; extraConfig.serverAliases = [ "admin.proot.link" ]; };
        # create track map todo later
        "uptime.protogen.io" = mkReverseProxy 3001;
        "kuma.protogen.io".locations."/".return = "301 https://uptime.protogen.io";
        "vsc-hass.protogen.io" = mkReverseProxy 1881;


        "localhost" = {
          default = true;
          addSSL = true;
          useACMEHost = "protogen.io";
          locations."/" = {
            return = "302 https://protogen.io$request_uri";
          };
        };
        "protogen.io" = {
          serverAliases = [ "x.protogen.io" ];
          useACMEHost = "protogen.io";
          forceSSL = true;
          locations."/" = {
            root = "/srv/http";
            extraConfig = ''
              autoindex on;
            '';
          };
        };
      };
    };

    virtualisation.docker = {
      enable = true;
      storageDriver = "btrfs";
    };

    # needed for mDNS in Home Assistant
    networking.firewall.allowedUDPPorts = [ 5353 ];

    systemd.services.libreddit.environment = {
      LIBREDDIT_DEFAULT_SUBSCRIPTIONS = lib.pipe ./reddit-subscriptions.txt [
        builtins.readFile
        (lib.splitString "\n")
        (lib.filter (x: x != ""))
        (lib.concatStringsSep "+")
      ];
    };
    services.libreddit = {
      enable = true;
      port = 8087;
      package = pkgs.redlib;
    };
  };
}
