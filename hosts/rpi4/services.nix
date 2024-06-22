{ config, lib, pkgs, ... }:
{
  config = {

    users.groups.secrets = {};
    users.users.acme.extraGroups = [ "secrets" ];

    age.secrets.cloudflaredns = {
      file = ../../secrets/cloudflare-dns.age;
      group = "secrets";
    };

    users.users.nginx.extraGroups = [ "acme" ];

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;

      commonHttpConfig = ''
        port_in_redirect off;
      '';

      virtualHosts = {
        "localhost" = {
          default = true;
          locations."/" = {
            return = "302 https://protogen.io$request_uri";
          };
        };
        "protogen.io" = {
          serverAliases = "x.protogen.io";
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
  };
}
