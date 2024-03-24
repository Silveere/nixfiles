{ pkgs, lib, config, ... }:
let
  cfg = config.services.minecraft-servers;
in
{
  config = {
    fileSystems = {
      "/srv/mcserver".options = [ "compress=zstd" "nofail" ];
      "/srv/mcserver/.snapshots".options = [ "compress=zstd" "nofail" ];
    };
    networking.firewall.trustedInterfaces = [ "wg0" ];

    users = {
      users = {
        nullbite.extraGroups = [ "minecraft" ];
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
      servers = {
        minecraft-nixtest = let
          self = cfg.servers.minecraft-nixtest;
          package = pkgs.quiltServers.quilt-1_20_1.override { loaderVersion = "0.21.0"; };
          modpack = pkgs.fetchPackwizModpack {
            url = "https://gitea.protogen.io/nullbite/notlite/raw/branch/release/1.20.1/pack.toml";
            packHash = "sha256-N3Pdlqte8OYz6wz3O/TSG75FMAV+XWAipqoXsYbcYDQ=";
          };
        in {
          enable = false;
          inherit package;
          autoStart = self.enable;
          whitelist = {
            YzumThreeEye = "3dad78e8-6979-404f-820e-952ce20964a0";
            NullBite = "e24e8e0e-7540-4126-b737-90043155bcd4";
            Silveere = "468554f1-27cd-4ea1-9308-3dd14a9b1a12";
          };
          symlinks = let
            symlinkFolders = lib.genAttrs [ "mods" "kubejs" ] (x: "${modpack}/${x}");
          in symlinkFolders;
          serverProperties = {
            # allow NCR
            enforce-secure-profile = false;
            white-list = true;
            enforce-whitelist = true;

            motd = "owo what's this (nix edition)";

            enable-rcon = false;
            difficulty = "hard";
            hardcore = false;
            online-mode = true;
            pvp = true;

            sync-chunk-writes = false;
          };
        };
      };
    };
  };
}
