{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.age) secrets;
in {
  config = {
    age.secrets = {
      atticd = {
        file = ../../secrets/atticd.age;
        group = "atticd-secret";
      };
      cloudflaredns = {
        file = ../../secrets/cloudflare-dns.age;
        group = "secrets";
      };
    };

    users.groups.secrets = {};
    users.users.acme.extraGroups = ["secrets"];

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
            "attic2.protogen.io"
          ];
        };
      };
    };

    # can't be bothered to fix NAT hairpinning rn
    networking.hosts."127.0.0.1" = [
      "attic2.protogen.io"
    ];

    users.users.nginx.extraGroups = ["acme"];

    services.nginx = {
      enable = true;
      enableReload = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;

      commonHttpConfig = ''
        port_in_redirect off;
      '';

      virtualHosts = let
        useACMEHost = "protogen.io";
        mkProxy = args @ {
          upstream ? "http://127.0.0.1:${builtins.toString args.port}",
          auth ? false,
          # authelia ? false,
          extraConfig ? {},
          ...
        }:
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
            # (lib.mkIf authelia {
            #   authelia.instance = lib.mkDefault "main";
            # })
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

        mkAuthProxy = port:
          mkProxy {
            inherit port;
            # authelia = true;
          };

        mkReverseProxy = port: mkProxy {inherit port;};
      in {
        "attic2.protogen.io" = mkProxy {
          port = 8080;
          extraConfig.extraConfig = ''
            client_max_body_size 0;
          '';
        };
      };
    };

    services.atticd = {
      enable = true;
      environmentFile = secrets.atticd.path;
      settings = {
        # TODO change this to a better port
        listen = "[::]:8080";
        database.url = "postgres://atticd?host=/run/postgresql";
        allowed-hosts = [
          "attic2.protogen.io"
        ];
        api-endpoint = "https://attic2.protogen.io/";
        compression.type = "zstd";
        garbage-collection.interval = "12 hours";
      };
    };

    users.groups.atticd-secret = {};

    systemd.services.atticd = {
      after = ["postgresql.target"];
      serviceConfig = {
        SupplementaryGroups = "atticd-secret";
      };
    };

    services.postgresql = {
      enable = lib.mkDefault true;

      ensureDatabases = ["atticd"];
      ensureUsers = [
        {
          name = config.services.atticd.user;
          ensureDBOwnership = true;
        }
      ];
    };
  };
}
