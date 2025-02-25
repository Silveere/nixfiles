{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.services.minecraft-servers;
in {
  config = {
    fileSystems = {
      "/srv/mcserver".options = ["compress=zstd" "nofail"];
      "/srv/mcserver/.snapshots".options = ["compress=zstd" "nofail"];
    };
    networking.firewall.trustedInterfaces = ["wg0"];

    users = {
      users = {
        nullbite.extraGroups = ["minecraft"];
      };
    };

    services.snapper = {
      configs.mcserver = {
        FSTYPE = "btrfs";
        SUBVOLUME = "/srv/mcserver";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_MIN_AGE = 1800;
        TIMELINE_LIMIT_HOURLY = 36;
        TIMELINE_LIMIT_DAILY = 14;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 12;
        TIMELINE_LIMIT_YEARLY = 10000;
      };
    };

    services.minecraft-servers = {
      enable = true;
      eula = true;
      dataDir = "/srv/mcserver";
      servers = let
        # hack to make quilt work. requires manual installation.
        # workaround for nix-minecraft#60
        shimPackage = pkgs.writeShellScriptBin "minecraft-server" ''
          exec ${pkgs.jre_headless}/bin/java $@ -jar ./quilt-server-launch.jar nogui
        '';

        nulllite-staging = let
          commit = "b8c639a";
          packHash = "sha256-HTDVIkcBf0DyLbSCuU08/HnEQuesi3cmXXhB4y4lyko=";
        in
          pkgs.fetchPackwizModpack {
            url = "https://gitea.protogen.io/nullbite/nulllite/raw/commit/${commit}/pack.toml";
            inherit packHash;
          };
      in {
        nulllite-staging = {
          useRecommendedDefaults = true;
          enable = true;
          autoStart = false;
          modpack = nulllite-staging;
          modpackSymlinks = ["mods"];
          modpackFiles = ["config/"];
          serverProperties.server-port = 25574;
          serverProperties.motd = "staging server";
        };
        notlite = {
          useRecommendedDefaults = true;
          enable = true;
          autoStart = true;
          modpack = pkgs.modpacks.notlite;
          modpackSymlinks = ["config/yosbr" "config/quilt-loader-overrides.json" "mods"];
          modpackFiles = ["kubejs/"];
          serverProperties = {
            motd = "owo what's this (nix notlite edition)";
            server-port = 25567;
            "query.port" = 25567;

            # more declarative
            level-seed = "8555431723250870652";
            level-type = "bclib:normal";
          };
        };
        minecraft-nixtest = let
          self = cfg.servers.minecraft-nixtest;
          package = pkgs.quiltServers.quilt-1_20_1.override {loaderVersion = "0.21.0";};
        in {
          useRecommendedDefaults = true;
          enable = false;
          modpack = pkgs.modpacks.notlite;
          # package = shimPackage;
          autoStart = self.enable;
          whitelist = {
            YzumThreeEye = "3dad78e8-6979-404f-820e-952ce20964a0";
            NullBite = "e24e8e0e-7540-4126-b737-90043155bcd4";
            Silveere = "468554f1-27cd-4ea1-9308-3dd14a9b1a12";
          };
          modpackSymlinks = ["mods"];
          modpackFiles = ["config/" "kubejs/"];
          serverProperties = rec {
            motd = "owo what's this (nix edition)";
            server-port = 25568;
            "query.port" = server-port;
          };
        };
      };
    };
  };
}
