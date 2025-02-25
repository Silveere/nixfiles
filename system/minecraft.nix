{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];
  options.services.minecraft-servers.servers = let
    serverModule = {
      name,
      config,
      ...
    }: {
      options = {
        useRecommendedDefaults = lib.mkOption {
          type = lib.types.bool;
          description = "Whether to use recommended server settings.";
          default = false;
        };

        modpack = lib.mkOption {
          description = "Modpack to use";
          type = with lib.types; nullOr package;
          default = null;
        };

        modpackFiles = lib.mkOption {
          description = "List of files from modpack to copy into server directory";
          type = with lib.types; listOf str;
          default = [];
        };

        modpackSymlinks = lib.mkOption {
          description = "List of files from modpack to symlink into server directory";
          type = with lib.types; listOf str;
          default = [];
        };
      };

      config = lib.mkMerge [
        (lib.mkIf config.useRecommendedDefaults {
          autoStart = lib.mkDefault true;
          jvmOpts = "-Dlog4j2.formatMsgNoLookups=true";

          whitelist = lib.mkDefault {
            NullBite = "e24e8e0e-7540-4126-b737-90043155bcd4";
            Silveere = "468554f1-27cd-4ea1-9308-3dd14a9b1a12";
            YzumThreeEye = "3dad78e8-6979-404f-820e-952ce20964a0";
          };

          serverProperties = {
            # allows no chat reports to run
            enforce-secure-profile = lib.mkDefault false;

            # whitelist
            white-list = lib.mkDefault true;
            enforce-whitelist = lib.mkDefault true;

            motd = lib.mkDefault "owo what's this (nix preset edition)";
            enable-rcon = lib.mkDefault false;

            # btrfs performance fix
            sync-chunk-writes = lib.mkDefault false;

            # this helps with some mod support. disable it on public servers.
            allow-flight = lib.mkDefault true;

            # no telemetry
            snooper-enabled = lib.mkDefault false;

            # other preferred settings
            pvp = lib.mkDefault true;
            difficulty = lib.mkDefault "hard";
          };
        })
        (lib.mkIf (!(builtins.isNull config.modpack)) {
          symlinks = lib.genAttrs config.modpackSymlinks (path: "${config.modpack}/${path}");
          files = lib.genAttrs config.modpackFiles (path: "${config.modpack}/${path}");

          package = let
            inherit (config) modpack;

            mcVersion = modpack.manifest.versions.minecraft;
            fixedVersion = lib.replaceStrings ["."] ["_"] mcVersion;
            quiltVersion = modpack.manifest.versions.quilt or null;
            fabricVersion = modpack.manifest.versions.fabric or null;
            loader =
              if (!(builtins.isNull quiltVersion))
              then "quilt"
              else "fabric";
            loaderVersion =
              if loader == "quilt"
              then quiltVersion
              else fabricVersion;

            serverPackage = pkgs.minecraftServers."${loader}-${fixedVersion}".override {inherit loaderVersion;};
          in
            lib.mkDefault serverPackage;
        })
      ];
    };
  in
    lib.mkOption {
      type = with lib.types; attrsOf (submodule serverModule);
    };
}
