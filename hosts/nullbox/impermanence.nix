{ pkgs, config, lib, ... }:
let
  inherit (lib) escapeShellArg;
  root_vol = "/dev/archdesktop/root";
in {
  imports = [
    ./btrfs-clean.nix
  ];
  config = lib.mkIf (!(config.virtualisation ? qemu)) {
    fileSystems."/persist" = {
      neededForBoot = true;
      device = root_vol;
      fsType = "btrfs";
      options = [ "subvol=/nixos/@persist" ];
    };

    fileSystems."/" = lib.mkForce {
      device = root_vol;
      fsType = "btrfs";
      btrfs = {
        subvolume = "/nixos/volatile";
        cleanOnBoot = {
          enable = true;
          destination = "/nixos/old_roots";
        };
      };
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
          "/var/lib/systemd/timesync"
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
