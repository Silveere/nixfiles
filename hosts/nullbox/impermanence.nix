{ pkgs, config, lib, ... }:
let
  mkBtrfsInit = { prefix ? "",
                  volume }:
  ''
    mkdir /btrfs_tmp
    mount ${volume} /btrfs_tmp -o subvol=/

    # unix is fine with multiple consecutive slashes if prefix is empty or
    # contains a leading or trailing slash
    mkdir -p "/btrfs_tmp/${prefix}/"

    if [[ -e "/btrfs_tmp/${prefix}/volatile" ]] ; then
      mkdir -p "/btrfs_tmp/${prefix}/old_roots"
      timestamp=$(date --date="@$(stat -c %Y "/btrfs_tmp/${prefix}/volatile")" "+%Y-%m-%-d_%H:%M:%S")
      mv "/btrfs_tmp/${prefix}/volatile" "/btrfs_tmp/${prefix}/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
      IFS=$'\n'
      for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
        delete_subvolume_recursively "/btrfs_tmp/$i"
      done
      # btrfs subvolume delete "$1"
      echo would run: btrfs subvolume delete "$1"
      echo remove this echo once you see this message

    }

    for i in $(find /btrfs_tmp/${prefix}/old_roots/ -maxdepth 1 -mtime +30); do
      delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/${prefix}/volatile

    umount /btrfs_tmp
  '';

  root_vol = "/dev/archdesktop/root";
in {
  config = lib.mkIf (!(config.virtualisation ? qemu)) {
    fileSystems."/persist" = {
      neededForBoot = true;
      device = root_vol;
      fsType = "btrfs";
      options = [ "subvol=/nixos/@persist" ];
    };

    boot.initrd.postDeviceCommands = lib.mkAfter (mkBtrfsInit { prefix = "nixos"; volume = root_vol; });
    fileSystems."/" = lib.mkForce {
      device = root_vol;
      fsType = "btrfs";
      options = [ "subvol=/nixos/volatile" ];
    };
    environment.persistence = {
      "/persist/nobackup" = {
        hideMounts = true;
        directories = [
          "/var/lib/systemd/coredump"
          "/var/lib/flatpak"
          "/var/log"
        ];

        files = [
          "/var/lib/systemd/random-seed"
        ];
      };

      "/persist/backup" = {
        hideMounts = true;
        directories = [
          # this affects generation/consistency of uids and gids, and should
          # probably NEVER be excluded removed.
          "/var/lib/nixos/"
          # password files for user.user.<name>.hashedPasswordFile
          { directory = "/etc/passfile"; mode = "0700"; }

          # persistent non-declarative config
          "/etc/nixos"
          "/etc/ssh"
          { directory = "/etc/wireguard"; mode = "0700"; }

          # let's keep the root home dir as well
          { directory = "/root"; mode = "0700"; }

          # system state
          "/etc/NetworkManager/system-connections"
          "/var/lib/bluetooth"
          "/var/lib/blueman"
          "/var/lib/cups"
          "/var/lib/NetworkManager"
          "/var/lib/power-profiles-daemon"
          "/var/lib/systemd/rfkill"
          { directory = "/var/lib/tailscale"; mode = "0700"; }
          "/var/lib/unbound"
          "/var/db/sudo/lectured"

          # remember login stuff
          "/var/cache/tuigreet"
        ];

        files = [
          "/etc/machine-id"
        ];
      };
    };

    users.mutableUsers = false;
    users.users.nullbite.hashedPasswordFile = "/persist/passfile/nullbite";
    users.users.root.hashedPasswordFile = "/persist/passfile/root";
  };
}
