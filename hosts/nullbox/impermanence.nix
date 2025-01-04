{ pkgs, config, lib, ... }:
let
  inherit (lib) escapeShellArg;
  # (wip) more configurable than old one, will be used by volatile btrfs module
  mkBtrfsInit = { volatileRoot ? "/volatile",
                      oldRoots ? "/old_roots",
                      volume }:
  ''
    mkdir -p /btrfs_tmp
    mount ${escapeShellArg volume} /btrfs_tmp -o subvol=/

    # ensure subvol parent directory exists
    mkdir -p $(dirname /btrfs_tmp/${escapeShellArg volatileRoot})

    if [[ -e /btrfs_tmp/${escapeShellArg volatileRoot} ]] ; then
      mkdir -p /btrfs_tmp/${escapeShellArg oldRoots}
      timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/${escapeShellArg volatileRoot})" "+%Y-%m-%-d_%H:%M:%S")
      mv /btrfs_tmp/${escapeShellArg volatileRoot} /btrfs_tmp/${escapeShellArg oldRoots}/"$timestamp"
    fi

    btrfs subvolume create /btrfs_tmp/${escapeShellArg volatileRoot}

    umount /btrfs_tmp

    # TODO implement deletion once system is booted. the old implementation did
    # it here, which is not safe until system time is at least monotonic.
    # systemd tmpfiles is good enough, just mount it to somewhere in /run
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

    # TODO volatile btrfs module
    boot.initrd.postDeviceCommands = lib.mkAfter (mkBtrfsInit {
      volume = root_vol;
      volatileRoot = "/nixos/volatile";
      oldRoots = "/nixos/old_roots";
    });

    fileSystems."/" = lib.mkForce {
      device = root_vol;
      fsType = "btrfs";
      options = [ "subvol=/nixos/volatile" ];
    };

    # agenix fix
    fileSystems."/etc/ssh".neededForBoot = true;

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
          "/var/lib/systemd/timesync"
          { directory = "/var/lib/tailscale"; mode = "0700"; }
          "/var/lib/unbound"
          "/var/db/sudo/lectured"

          # remember login stuff
          { directory = "/var/cache/tuigreet"; user = "greeter"; group = "greeter"; }
          { directory = "/var/cache/regreet"; user = "greeter"; group = "greeter"; }
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
