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
        "gdlmirror"
        "gitea-dump-*"
        "/var/lib/thelounge/storage"
      ];
      paths = [
        "/srv"
        "/srv/media"
        "/srv/syncthing"
        "/srv/http"
        "/opt"
        "/var/lib/gitea"
        "/var/lib/tailscale"
        "/var/lib/private/anki-sync-server"
        "/var/lib/thelounge"
        "/var/lib/paperless"
        "/etc"
      ];
      dynamicFilesFrom = ''
        echo
        find /var/lib -mindepth 1 -maxdepth 1 -type d -name 'authelia-*'
      '';

      extraBackupArgs = [
        "--tag=auto"
        "--group-by=host,tag"
      ];

    };
  };
}
