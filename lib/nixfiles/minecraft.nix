pkgs:
let
  inherit (pkgs) lib;
in
{
  mkServer = { modpack ? null, modpackSymlinks ? [], modpackFiles ? [], jvmOpts ? null, ...}@opts: let
    # log4j exploit is bad and scary and i have no idea if this is still needed
    # but it's best to be on the safe side
    jvmOptsPatched = let
      requiredJvmOpts = "-Dlog4j2.formatMsgNoLookups=true";
    in if (!(builtins.isNull jvmOpts))
      then requiredJvmOpts + " " + jvmOpts
      else requiredJvmOpts;

    symlinks = lib.genAttrs modpackSymlinks (path: "${modpack}/${path}");
    files = lib.genAttrs modpackFiles (path: "${modpack}/${path}");

    serverPackage = let
      mcVersion = modpack.manifest.versions.minecraft;
      fixedVersion = lib.replaceStrings [ "." ] [ "_" ] mcVersion;
      quiltVersion = modpack.manifest.versions.quilt or null;
      fabricVersion = modpack.manifest.versions.fabric or null;
      loader = if (!(builtins.isNull quiltVersion)) then "quilt" else "fabric";
      loaderVersion = if loader == "quilt" then quiltVersion else fabricVersion;
    in pkgs.minecraftServers."${loader}-${fixedVersion}".override { inherit loaderVersion; };

  in lib.mkMerge [
    (lib.mkIf (!(builtins.isNull modpack)) {
      inherit symlinks files;
      package = lib.mkDefault serverPackage;
    })
    {
      autoStart = lib.mkDefault true;
      jvmOpts = jvmOptsPatched;
      whitelist = lib.mkDefault {
        NullBite     = "e24e8e0e-7540-4126-b737-90043155bcd4";
        Silveere     = "468554f1-27cd-4ea1-9308-3dd14a9b1a12";
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
    }
    (builtins.removeAttrs opts [ "modpack" "modpackSymlinks" "modpackFiles" "jvmOpts" ])
  ];
}
