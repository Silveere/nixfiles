{ config, lib, pkgs, ... }:
let
  inherit (config.age) secrets;
  inherit (builtins) toString;
in
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
      group = "authelia-shared";
      mode = "0750";
    };

    age.secrets.authelia-jwt = {
      file = ../../secrets/authelia-jwt.age;
      group = "authelia-shared";
      mode = "0750";
    };

    age.secrets.authelia-storage = {
      file = ../../secrets/authelia-storage.age;
      group = "authelia-shared";
      mode = "0750";
    };

    age.secrets.authelia-session = {
      file = ../../secrets/authelia-session.age;
      group = "authelia-shared";
      mode = "0750";
    };

    age.secrets.anki = {
      file = ../../secrets/anki-user.age;
    };

    age.secrets.homepage = {
      file = ../../secrets/homepage.age;
    };

    age.secrets.paperless-admin = {
      file = ../../secrets/paperless-admin.age;
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
            "nullbite.xyz"
            "*.nullbite.xyz"
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

    users.groups.authelia-shared = { };
    services.authelia.instances = lib.mapAttrs (inst: opts: {
      enable = true;
      group = "authelia-shared";
      secrets = {
        jwtSecretFile = config.age.secrets.authelia-jwt.path;
        storageEncryptionKeyFile = config.age.secrets.authelia-storage.path;
        sessionSecretFile = config.age.secrets.authelia-session.path;
      };
      settings = {
        access_control.default_policy = "one_factor";
        storage.local.path = "/var/lib/authelia-${inst}/db.sqlite";
        session.cookies = [
          {
            domain = "protogen.io";
            authelia_url = "https://auth.protogen.io";
            default_redirection_url = "https://searx.protogen.io";
          }
          {
            domain = "nbt.sh";
            authelia_url = "https://auth.nbt.sh";
            default_redirection_url = "https://admin.nbt.sh";
          }
          {
            domain = "proot.link";
            authelia_url = "https://auth.proot.link";
            default_redirection_url = "https://admin.proot.link";
          }
        ];
        session.redis = {
          host = config.services.redis.servers.authelia.unixSocket;
        };
        notifier.filesystem.filename = "/var/lib/authelia-${inst}/notification.txt";
        authentication_backend.file.path = config.age.secrets.authelia-users.path;
        server.port = lib.mkIf (opts ? port) (opts.port or null);
        theme = "auto";
      };
    }) {
      main = {
        domain = "protogen.io";
        # port = 9091 # default
      };
    };

    services.redis = {
      servers.authelia = {
        enable = true;
      };
    };

    users.users."${config.services.authelia.instances.main.user}".extraGroups = let
      name = config.services.redis.servers.authelia.user;
    in [ name ];

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
            authelia.instance = lib.mkDefault "main";
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
      in (lib.mapAttrs (domain: instance: { forceSSL = true; inherit useACMEHost; authelia.endpoint = { inherit instance; };}) {
        "auth.protogen.io" = "main";
        "auth.nbt.sh" = "main";
        "auth.proot.link" = "main";
      }) // {
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
        "libreddit.protogen.io" = {
          locations."/".return = "302 https://redlib.protogen.io$request_uri";
          forceSSL = true;
          useACMEHost = "protogen.io";
        };
        "redlib.protogen.io" = mkAuthProxy 8087;
        "rss.protogen.io" = mkReverseProxy 8082;
        "blahaj.protogen.io" = mkReverseProxy 8086;
        "paper.protogen.io" = mkReverseProxy config.services.paperless.port;

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
        "admin.nbt.sh" = mkProxy { authelia = true; port = 8091; extraConfig.serverAliases = [ "admin.proot.link" ]; };

        # uptime
        "uptime.protogen.io" = mkReverseProxy 3001;
        "kuma.protogen.io".locations."/".return = "301 https://uptime.protogen.io";

        "anki.protogen.io" = mkReverseProxy config.services.anki-sync-server.port;

        # homepage
        "home.protogen.io" = mkAuthProxy 8089;

        "lounge.protogen.io" = mkAuthProxy 9000;

        "trackmap.protogen.io" = let
          root = pkgs.modpacks.notlite-ctm-static;
        in {
          useACMEHost = "protogen.io";
          forceSSL = true;
          authelia.instance = "main";
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
          serverAliases = [ "www.nullbite.com" "nullbite.dev" "www.nullbite.dev" "www.protogen.io" "nullbite.xyz" "www.nullbite.xyz" ];
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

    # https://gethomepage.dev
    services.homepage-dashboard = let
      entry = name: value: { "${name}" = value; };
      makeBookmark = name: {...}@attrs: entry name [ attrs ];
      makeBookmark' = name: icon: abbr: href: makeBookmark name ({ inherit abbr href; } // lib.optionalAttrs (icon != null) { inherit icon; });
    in {
      enable = true;
      listenPort = 8089;
      environmentFile = secrets.homepage.path;

      # bookmarks customCSS customJS docker environmentFile kubernetes services settings widgets
      settings = {
        theme = "dark";
        color = "slate";
      };

      widgets = [
        (entry "resources" {
          cpu = true;
          memory = true;
          disk = "/";
        })
        (entry "search" {
          provider = "custom";
          target = "_self";
          url = "https://searx.protogen.io/search?q=";
          suggestionUrl = "https://searx.protogen.io/autocompleter?q=";
          showSearchSuggestions = true;
        })
      ];

      services = let
        service = name: subdomain: icon: {...}@attrs: entry name ({
          href = "https://${subdomain}.protogen.io";
          inherit icon;
        } // attrs);
        basicService = name: subdomain: icon: service name subdomain icon {};
      in [
        (entry "unsorted" [
          (basicService "Firefly III" "firefly" "firefly-iii")
          (basicService "Gitea" "gitea" "gitea")
          (basicService "Home Assistant" "hass" "home-assistant")
          (basicService "Node-RED" "node" "node-red")
          (basicService "Zigbee2MQTT" "z2m" "zigbee2mqtt")
          (basicService "Code Server (Home Assistant)" "vsc-hass" "vscode")
          (basicService "Deemix" "deemix" "deemix")
          (basicService "Miniflux" "rss" "miniflux")
          (basicService "mlmym" "blahaj" "lemmy-light")
          (basicService "Octoprint" "print" "octoprint")
          (basicService "SearXNG" "searx" "searxng")
          (basicService "TheLounge" "lounge" "thelounge")
          (basicService "Paperless" "paper" "paperless-ngx")
          (entry "Shlink" { href = "https://admin.nbt.sh"; icon = "shlink"; })
          (basicService "Create Track Map" "trackmap" "")

          ((x: service x x x {
            widget = {
            };
          }) "changedetection")

          (service "Uptime Kuma" "uptime" "uptime-kuma" {
            widget = {
              type = "uptimekuma";
              url = "https://uptime.protogen.io";
              slug = "all";
            };
          })
          (service "Jellyfin" "room" "jellyfin" {
            widget = {
              type = "jellyfin";
              url = "https://room.protogen.io";
              key = "{{HOMEPAGE_VAR_JELLYFIN}}";
              enableBlocks = true;
              enableNowPlaying = true;
              enableUser = true;
            };
          })
        ])
      ];

      bookmarks = [
        (entry "Admin" [
          (makeBookmark' "Backblaze" "backblaze" "BZ" "https://secure.backblaze.com/user_signin.htm")
          (makeBookmark' "Cloudflare" "cloudflare" "CF" "https://dash.cloudflare.com")
          (makeBookmark' "Porkbun" "porkbun" "PB" "https://porkbun.com/account/domainsSpeedy")
          (makeBookmark' "Namecheap" "namechea" "NC" "https://ap.www.namecheap.com/")
        ])
        (entry "Developer" [
          (makeBookmark' "GitHub" "github" "GH" "https://github.com")
        ])
        (entry "Local" [
          (makeBookmark' "Syncthing" "syncthing" "ST" "http://127.0.0.1:8384")
          (makeBookmark' "Iris" null "IR" "http://localhost:6680/iris/")
        ])
        (entry "Entertainment" [
          (makeBookmark' "Redlib" "redlib" "RL" "https://redlib.protogen.io")
        ])
      ];
    };

    virtualisation.docker = {
      enable = true;
      storageDriver = "btrfs";
    };

    # needed for mDNS in Home Assistant
    networking.firewall.allowedUDPPorts = [ 5353 ];

    systemd.services.redlib.environment = {
      REDLIB_DEFAULT_SUBSCRIPTIONS = lib.pipe ./reddit-subscriptions.txt [
        builtins.readFile
        (lib.splitString "\n")
        (lib.filter (x: x != ""))
        (lib.concatStringsSep "+")
      ];
      REDLIB_DEFAULT_SHOW_NSFW = "on";
      REDLIB_DEFAULT_BLUR_NSFW = "on";
      REDLIB_DEFAULT_BLUR_SPOILER = "on";
      REDLIB_DEFAULT_USE_HLS = "on";
      REDLIB_DEFAULT_DISABLE_VISIT_REDDIT_CONFIRMATION = "on";

      REDLIB_ENABLE_RSS = "on";
    };

    services.redlib = {
      enable = true;
      port = 8087;
    };

    services.thelounge = {
      enable = true;
    };

    services.redis.servers.paperless.enable = true;
    services.paperless = {
      enable = true;
      # default is "localhost", binding should not rely on DNS (even if
      # localhost is hard-coded 99.999% of the time)
      address = "127.0.0.1";
      passwordFile = secrets.paperless-admin.path;
      settings = {
        PAPERLESS_ADMIN_USER = "nullbite";
        PAPERLESS_REDIS = "unix://${config.services.redis.servers.paperless.unixSocket}";
        PAPERLESS_URL = "https://paper.protogen.io";
        PAPERLESS_TIKA_ENABLED = true;
        PAPERLESS_TIKA_ENDPOINT = "http://localhost:${toString config.services.tika.port}";
        PAPERLESS_TIKA_GOTENBERG_ENDPOINT =
          "http://localhost:${toString config.services.gotenberg.port}";
      };
    };
    users.users."${config.services.paperless.user}".extraGroups = let
      name = config.services.redis.servers.paperless.group;
    in [ name ];

    services.gotenberg = {
      enable = true;
      port = 3002;
    };
    services.tika.enable = true;

    services.anki-sync-server = {
      enable = true;
      address = "127.0.0.1";
      users = [
        {
          username = "nullbite";
          passwordFile = config.age.secrets.anki.path;
        }
      ];
    };
  };
}
