{ config, lib, pkgs, ... }:
let
  copypartyRoot = "/tmp/copyparty";
  inherit (config.age) secrets;
  inherit (builtins) toString;
in
{
  config = {

    age.secrets = {
      rclone-crypt = {
        file = ../../secrets/rclone-crypt.age;
        mode = "0600";
      };
    };

    fileSystems."/mnt/crypt" = {
      device = "crypt-shared:";
      fsType = "rclone";
      options = [
        "nodev"
        "nofail"
        "allow_other"
        "default_permissions"
        "args2env"
        "config=${secrets.rclone-crypt.path}"
        "vfs_cache_mode=full"
        "cache_dir=/var/cache/rclone"
        "gid=${toString config.users.groups.rclonecrypt.gid}"
        "umask=0007"
      ];
    };

    users.groups.rclonecrypt = {
      gid = 1999;
      members = [
        "copyparty"
        "nullbite"
      ];
    };

    users.users.copyparty = {
      group = "copyparty";
      isSystemUser = true;
    };

    users.groups.copyparty = { };
    # services.copyparty = {
    #   enable = true;
    #   user = "copyparty";
    #   group = "copyparty";
    # };
  };
}
