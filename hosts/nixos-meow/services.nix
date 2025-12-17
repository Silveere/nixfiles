{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.nixfiles.args.flake) self;
in {
  config = {
    age.secrets = {
      cloudflaredns = {
        file = self.outPath + "/secrets/cloudflare-dns.age";
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
        "meow.nullbite.com" = {
          credentialFiles = {
            "CLOUDFLARE_EMAIL_FILE" = pkgs.writeText "email" "iancoguz@gmail.com";
            "CLOUDFLARE_API_KEY_FILE" = config.age.secrets.cloudflaredns.path;
          };

          dnsProvider = "cloudflare";
          domain = "meow.nullbite.com";
          extraDomainNames = [
            "*.meow.nullbite.com"
          ];
        };
      };
    };

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
        useACMEHost = "meow.nullbite.com";
        # i really need to deduplicate this
        # once i decide to fix the dendritic lib import thing i can do that
        # also in hosts/{rpi4,nixos-px1}/services.nix
        mkProxy = args @ {
          upstream ? "http://127.0.0.1:${builtins.toString args.port}",
          auth ? false,
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
            extraConfig
          ];

        mkAuthProxy = port:
          mkProxy {
            inherit port;
          };

        mkReverseProxy = port: mkProxy {inherit port;};
      in {
        "hass.meow.nullbite.com" = mkProxy {
          upstream = "http://192.168.1.227:8123";
        };
      };
    };
  };
}
