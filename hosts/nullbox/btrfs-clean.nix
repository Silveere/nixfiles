{ config, lib, utils, pkgs, ... }:
let
  inherit (builtins) attrValues all;
  inherit (lib) escapeShellArg optionalString concatStringsSep
    nameValuePair mapAttrs' filterAttrs mapAttrsToList
    mkIf mkOption types;
  inherit (utils) escapeSystemdPath;

  genBtrfsInit' = fsConfig: genBtrfsInit {
    inherit (fsConfig) device;
    inherit (fsConfig.btrfs) subvolume;
    inherit (fsConfig.btrfs.cleanOnBoot) destination;
  };
  genBtrfsInit = { subvolume, device, destination, }:
  ''
    mkdir -p /btrfs_tmp
    mount ${escapeShellArg device} /btrfs_tmp -o subvol=/

    # ensure subvol parent directory exists
    mkdir -p $(dirname /btrfs_tmp/${escapeShellArg subvolume})

    if [[ -e /btrfs_tmp/${escapeShellArg subvolume} ]] ; then
      mkdir -p /btrfs_tmp/${escapeShellArg destination}
      timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/${escapeShellArg subvolume})" "+%Y-%m-%-d_%H:%M:%S")
      mv /btrfs_tmp/${escapeShellArg subvolume} /btrfs_tmp/${escapeShellArg destination}/"$timestamp"
    fi

    btrfs subvolume create /btrfs_tmp/${escapeShellArg subvolume}

    umount /btrfs_tmp

  '';
    # TODO implement deletion once system is booted. the old implementation did
    # it here, which is not safe until system time is at least monotonic.
    # systemd tmpfiles is good enough, just mount it to somewhere in /run

  generateInitrdUnit = name: values: let
    deviceUnit = "${escapeSystemdPath values.device}.device";
  in nameValuePair "btrfs-clean-subvolume-${escapeSystemdPath name}" {
    description = "BTRFS subvolume reset for ${name} mountpoint";
    wantedBy = [ "initrd-root-fs.target" ];
    before = [ "sysroot.mount" ];
    after = [ deviceUnit ];
    requires = [ deviceUnit ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Exec = pkgs.writeShellScript "btrfs-clean-subvolume" (genBtrfsInit' values);
    };
  };

  fsModule = { config, name, ... }:
  {
    options.btrfs = {
      subvolume = mkOption {
        description = "btrfs subvolume of filesystem";
        type = with types; nullOr path;
        default = null;
      };
      cleanOnBoot = {
        enable = mkOption {
          description = ''
            Whether to replace this subvolume with an empty one before mount.
            This is useful in combination with Impermanence.
          '';
          type = types.bool;
          default = false;
          example = true;
        };
        destination = mkOption {
          description = ''
            Destination of old subvolume, relative to btrfs root (subvol=/).
            Cleanup is handled as a separate step, in case any old state is
            needed.
          '';
          type = types.path;
          example = "/old_roots";
        };
      };
    };
    config = {
      options = let
        inherit (config.btrfs) subvolume;
      in lib.mkIf (!(isNull subvolume)) [ "subvol=${subvolume}" ];
    };
  };
in
{
  options = {
    fileSystems = mkOption {
      type = with types; attrsOf (submodule fsModule);
    };
  };
  config = let
    configuredFileSystems = filterAttrs (k: v: v.btrfs.cleanOnBoot.enable) config.fileSystems;
  in mkIf (configuredFileSystems != { }) {

    assertions = [
      { assertion = all (x: x.btrfs.cleanOnBoot.enable -> x.btrfs.subvolume != null) (attrValues configuredFileSystems);
        message = "fileSystems.<name>.btrfs.cleanOnBoot.enable is set but no subvolume is configured."; }
    ];
    boot.initrd.systemd.services = mapAttrs' generateInitrdUnit configuredFileSystems;

    boot.initrd.postDeviceCommands = let
      scripts = mapAttrsToList (name: values: genBtrfsInit' values) configuredFileSystems;
    in mkIf (!config.boot.initrd.systemd.enable) (lib.mkAfter (concatStringsSep "\n" scripts));
  };
}
