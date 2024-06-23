{ config, lib, pkgs, ... }:
{
  config = {

    age.secrets.cloudflaredns = {
      file = ../../secrets/cloudflare-dns.age;
      group = "secrets";
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

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;

      commonHttpConfig = ''
        port_in_redirect off;
      '';

      virtualHosts = let
        mkReverseProxy = port: {
          useACMEHost = "protogen.io";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${builtins.toString port}";
            proxyWebsockets = true;
          };
        };
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
        "jellyfin.protogen.io" = mkReverseProxy 8096;
        # deemix auth 8096
        # libreddit auth 8087
        "rss.protogen.io" = mkReverseProxy 8082;
        "blahaj.protogen.io" = mkReverseProxy 8086;
        # octoprint (proxy_addr is 10.10.1.8)
        # searx auth 8088 (none for /favicon.ico, /autocompleter, /opensearch.xml)
        # nbt.sh alias proot.link 8090
        # admin.nbt.sh alias admin.proot.link 8091 auth
        # create track map todo later
        "uptime.protogen.io" = mkReverseProxy 3001;
        "kuma.protogen.io".locations."/".return = "301 https://uptime.protogen.io";
        "vsc-hass.protogen.io" = mkReverseProxy 1881;


        "localhost" = {
          default = true;
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
