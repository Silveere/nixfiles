{lib, ...}: let
  mkNixosModule = release: let
    inherit (lib) versionAtLeast versionOlder;
  in
    {
      config,
      lib,
      pkgs,
      outputs,
      vars,
      ...
    } @ args: let
      cfg = config.nixfiles.programs.adb;
    in {
      options.nixfiles.programs.adb = {
        enable = lib.mkEnableOption "adb configuration";
      };

      config = lib.mkMerge [
        {
          config = lib.mkIf cfg.enable {
            environment.systemPackages =
              [
                pkgs.scrcpy
                # from overlay
                pkgs.magiskboot
                pkgs.ksud
              ]
              ++ lib.optional (versionAtLeast release "26.05") pkgs.android-tools;
          };
        }
        (lib.mkIf (versionOlder release "26.05") {
          programs.adb.enable = true;
          users.users.${vars.username}.extraGroups = ["adbusers"];
        })
      ];
    };
in {
  config.flake.modules.nixos = {
    "nixfiles-26.05" = mkNixosModule "26.05";
    "nixfiles-25.11" = mkNixosModule "25.11";
  };
}
