{ config, lib, pkgs, ... }:
let
  secret = name: config.age.secrets."${name}".path;
in
{
  config = {
    age.secrets.restic-rclone.file   = ../../secrets/restic-rclone.age;
    age.secrets.restic-password.file = ../../secrets/restic-password.age;
    services.restic.backups.system = {
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
