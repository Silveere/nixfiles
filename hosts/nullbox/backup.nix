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
    };

    services.restic.backups.system = {

      # create an atomic backup
      backupPrepareCommand = ''
        set -Eeuxo pipefail

        if btrfs subvol delete /srv/mcserver/@restic; then
          echo "Old restic snapshot deleted.";
        fi

        btrfs subvol snapshot -r /srv/mcserver /srv/mcserver/@restic
      '';
      backupCleanupCommand = ''
        btrfs subvolume delete /srv/mcserver/@restic
      '';

      rcloneConfigFile = secret "restic-rclone";
      passwordFile = secret "restic-password";
      repository = "rclone:restic:";
      exclude = [
        ".snapshots"
      ];
      paths = [
        "/srv/mcserver/@restic"
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
