{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.nixfiles.args.flake) self;
  inherit (config.age) secrets;
in {
  config = {
    networking.firewall.allowedTCPPorts = [80 443];

    age.secrets = {
      cloudflare-dns-token = {
        file = self.outPath + "/secrets/cloudflare-dns-token.age";
        group = "secrets";
      };
      cloudflare-dns = {
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
            "CLOUDFLARE_API_KEY_FILE" = config.age.secrets.cloudflare-dns.path;
          };

          dnsProvider = "cloudflare";
          domain = "meow.nullbite.com";
          extraDomainNames = [
            "*.meow.nullbite.com"
            "hass-meow.nullbite.com"
          ];
        };
      };
    };

    users.users.nginx.extraGroups = ["acme"];

    # third time's the charm ? ? ?
    services.cloudflare-dyndns = {
      enable = true;
      apiTokenFile = secrets.cloudflare-dns-token.path;
      domains = [
        "meow.ddns.nullbite.com"
      ];
      ipv4 = true;
      ipv6 = false;
      proxied = false;
    };

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

        hassProxy = mkProxy {
          upstream = "http://192.168.1.227:8123";
        };
      in {
        "hass.meow.nullbite.com" = hassProxy;
        "hass-meow.nullbite.com" = hassProxy;
        "localhost" = {
          default = true;
          addSSL = true;
          useACMEHost = "meow.nullbite.com";
          locations."/" = {
            return = "404";
          };
        };
      };
    };
  };
}
