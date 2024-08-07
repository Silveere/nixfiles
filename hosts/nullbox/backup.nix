{ config, lib, pkgs, ... }:
let
  inherit (lib) escapeShellArg;
  secret = name: config.age.secrets."${name}".path;
  fs = config.fileSystems."/srv/mcserver";
in
{
  config = {
    age.secrets.restic-rclone.file   = ../../secrets/restic-rclone.age;
    age.secrets.restic-password.file = ../../secrets/restic-password.age;

    systemd.services.restic-backups-system = {
      path = with pkgs; [ btrfs-progs ];
      # ensures mounts are isolated to only this service
      serviceConfig.PrivateMounts = true;
    };

    services.restic.backups.system = {

      # create an atomic backup
      backupPrepareCommand = ''
        set -Eeuxo pipefail
        mkdir -p /tmp/btrfs_root
        mount -t btrfs -o subvol=/ ${escapeShellArg fs.device} /tmp/btrfs_root

        if btrfs subvol delete /tmp/btrfs_root/@restic-snapshot-mcserver; then
          echo "Old restic snapshot deleted.";
        fi

        btrfs subvol snapshot -r /srv/mcserver /tmp/btrfs_root/@restic-snapshot-mcserver

        umount /srv/mcserver
        mount -t btrfs -o subvol=/@restic-snapshot-mcserver ${escapeShellArg fs.device} /srv/mcserver
      '';
      backupCleanupCommand = ''
        btrfs subvolume delete /tmp/btrfs_root/@restic-snapshot-mcserver
      '';

      rcloneConfigFile = secret "restic-rclone";
      passwordFile = secret "restic-password";
      repository = "rclone:restic:";
      exclude = [
        ".snapshots"
      ];
      paths = [
        "/srv/mcserver"
      ];
      dynamicFilesFrom = ''
        echo
      '';

      extraBackupArgs = [
        "--tag=auto"
        "--group-by=host,tag"
      ];

    };
  };
}
