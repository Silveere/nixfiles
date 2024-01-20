{...}@moduleInputs:
{ config, lib, pkgs, ... }:
with lib;

let
  extraPkgs = (moduleInputs.mkExtraPkgs pkgs.system);
in
{
  meta.maintainers = [ maintainers.mic92 ];

  disabledModules = [ "programs/adb.nix" ];

  ###### interface
  options = {
    programs.adb = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = lib.mdDoc ''
          Whether to configure system to use Android Debug Bridge (adb).
          To grant access to a user, it must be part of adbusers group:
          `users.users.alice.extraGroups = ["adbusers"];`
        '';
      };
    };
  };

  ###### implementation
  config = mkIf config.programs.adb.enable {
    services.udev.packages = [ extraPkgs.android-udev-rules ];
    environment.systemPackages = [ extraPkgs.android-tools ];
    users.groups.adbusers = {};
  };
}
