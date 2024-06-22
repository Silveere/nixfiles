{ config, lib, pkgs, ... }:
{
  config = {

    users.groups.secrets = {};
    users.users.acme.extraGroups = [ "secrets" ];

    age.secrets.cloudflaredns = {
      file = ../../secrets/cloudflare-dns.age;
      group = "secrets";
    };


    security.acme = {
      acceptTerms = true;
      maxConcurrentRenewals = 1;
      defaults = {
      };

      certs = {
        "protogen.io" = {
          credentialFiles = {
            CLOUDFLARE_EMAIL_FILE = pkgs.writeTextFile "cloudflare-email" ''
              iancoguz@gmail.com
            '';
            CLOUDFLARE_API_KEY_FILE = config.age.secrets.cloudflaredns.path;
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
