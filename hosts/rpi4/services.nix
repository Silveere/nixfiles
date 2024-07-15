{ config, lib, pkgs, ... }:
{
  imports = [
    ./gitea.nix
    ./authelia.nix
  ];
  config = {

    age.secrets.cloudflaredns = {
      file = ../../secrets/cloudflare-dns.age;
      group = "secrets";
    };

    age.secrets.htpasswd-cam = {
      file = ../../secrets/htpasswd-cam.age;
      group = "nginx";
      mode = "0750";
    };
    age.secrets.htpasswd = {
      file = ../../secrets/htpasswd.age;
      group = "nginx";
      mode = "0750";
    };

    age.secrets.authelia-users = {
      file = ../../secrets/authelia-users.age;
      group = "authelia-main";
      mode = "0750";
    };

    age.secrets.authelia-jwt = {
      file = ../../secrets/authelia-jwt.age;
      group = "authelia-main";
      mode = "0750";
    };

    age.secrets.authelia-storage = {
      file = ../../secrets/authelia-storage.age;
      group = "authelia-main";
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
            "proot.link"
            "*.proot.link"
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

    services.authelia.instances.main = {
      enable = true;
      secrets = {
        jwtSecretFile = config.age.secrets.authelia-jwt.path;
        storageEncryptionKeyFile = config.age.secrets.authelia-storage.path;
      };
      settings = {
        access_control.default_policy = "one_factor";
        storage.local.path = "/var/lib/authelia-main/db.sqlite";
        session.domain = "protogen.io";
        notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";
        authentication_backend.file.path = config.age.secrets.authelia-users.path;
      };
    };

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
        mkProxy = args@{ upstream ? "http://127.0.0.1:${builtins.toString args.port}", auth ? false, authelia ? false, extraConfig ? {}, ... }:
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
          (lib.mkIf authelia {
            authelia.instance = "main";
            authelia.endpointURL = "https://auth.protogen.io";
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

        mkAuthProxy = port: mkProxy { inherit port; authelia = true; };

        mkReverseProxy = port: mkProxy { inherit port; };
      in {
        "auth.protogen.io" = {
          forceSSL = true;
          inherit useACMEHost;
          authelia.endpoint.instance = "main";
        };
        "changedetection.protogen.io" = mkReverseProxy 5000;

        # firefly
        "firefly.protogen.io" = mkReverseProxy 8083;
        "firefly-import.protogen.io" = mkAuthProxy 8084;

        "gitea.protogen.io" = mkReverseProxy 3000;

        # home assistant
        "hass.protogen.io" = mkReverseProxy 8123;
        "node.protogen.io" = mkReverseProxy 1880;
        "z2m.protogen.io" = mkAuthProxy 8124;
        "vsc-hass.protogen.io" = mkReverseProxy 1881;

        # jellyfin
        "room.protogen.io" = mkReverseProxy 8096;
        "deemix.protogen.io" = mkAuthProxy 6595;

        # libreddit auth 8087
        "libreddit.protogen.io" = mkAuthProxy 8087;
        "rss.protogen.io" = mkReverseProxy 8082;
        "blahaj.protogen.io" = mkReverseProxy 8086;

        # octoprint (proxy_addr is 10.10.1.8)
        "print.protogen.io" = lib.mkMerge [ (mkProxy { authelia = true; upstream = "http://10.10.1.8:80"; })
        {
          locations."/webcam" = {
            proxyPass = "http://10.10.1.8:80$request_uri";
            proxyWebsockets = true;
            basicAuthFile = config.age.secrets.htpasswd-cam.path;
            authelia.method = null;
          };
        }];

        # searx auth 8088 (none for /favicon.ico, /autocompleter, /opensearch.xml)
        "search.protogen.io".locations."/".return = "302 https://searx.protogen.io$request_uri";
        "searx.protogen.io" = let
          port = 8088;
        in mkProxy { authelia = true; inherit port; extraConfig = {
          locations = lib.genAttrs [ "/favicon.ico" "/autocompleter" "/opensearch.xml" ] (attr: {
            proxyPass = "http://localhost:${builtins.toString port}";
            proxyWebsockets = true;
            authelia.method = null;
            extraConfig = ''
              auth_basic off;
            '';
          });
        };};

        # URL shortener
        "nbt.sh" = mkProxy { port = 8090; extraConfig.serverAliases = [ "proot.link" ]; };
        "admin.nbt.sh" = mkProxy { authelia = true; port = 8091; extraConfig = {
          # authelia version in NixOS does not support multiple domains, use basic
          authelia.method = "basic"; serverAliases = [ "admin.proot.link" ];
        };};

        # uptime
        "uptime.protogen.io" = mkReverseProxy 3001;
        "kuma.protogen.io".locations."/".return = "301 https://uptime.protogen.io";

        "trackmap.protogen.io" = let
          root = pkgs.modpacks.notlite-ctm-static;
        in {
          useACMEHost = "protogen.io";
          forceSSL = true;
          authelia.instance = "main";
          authelia.endpointURL = "https://auth.protogen.io";
          locations."/" = {
            inherit root;
            extraConfig = ''
              autoindex off;
            '';
          };
          locations."/api/" = {
            proxyPass = "http://10.10.0.3:3876";
            proxyWebsockets = true;
            extraConfig = ''
              chunked_transfer_encoding off;
              proxy_buffering off;
              proxy_cache off;
            '';
          };
        };

        # main site
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

        # fallback for known hosts
        "nullbite.com" = {
          forceSSL = true;
          useACMEHost = "protogen.io";
          locations."/" = {
            return = "302 https://protogen.io$request_uri";
          };
          serverAliases = [ "www.nullbite.com" "nullbite.dev" "www.nullbite.dev" "www.protogen.io" ];
        };

        # show blank page for unknown hosts
        "localhost" = {
          default = true;
          addSSL = true;
          useACMEHost = "protogen.io";
          locations."/" = {
            return = "404";
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
