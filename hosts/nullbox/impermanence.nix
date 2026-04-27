{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) escapeShellArg;
  # (wip) more configurable than old one, will be used by volatile btrfs module

  btrfsSystemd = {
    volume,
    root ? "/volatile",
    oldRoots ? "/old_roots",
    ...
  }: {
    description = "Rollback BTRFS root subvolume to a pristine state";
    wantedBy = ["initrd.target"];
    after = [
      # is this needed
      # # LUKS/TPM process
      # "systemd-cryptsetup@crypted.service"
      # The root fs target
      "cryptsetup.target"
      "initrd-root-device.target"
    ];
    before = ["sysroot.mount" "shutdown.target"];
    conflicts = ["shutdown.target"];
    unitConfig.DefaultDependencies = "no";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      MOUNTDIR=/mnt
      mkdir -p ''${MOUNTDIR}

      # Pick up any LVM from newly mapped enc
      # Only needed if using lvm, but no harm if not
      vgscan
      vgchange -ay

      BTRFS_VOL=${escapeShellArg volume}

      if [ ! -r "$BTRFS_VOL" ];
      then
        >&2 echo "Device '$BTRFS_VOL' not found"
        exit 1
      fi
      # We first mount the btrfs root to /mnt
      # so we can manipulate btrfs subvolumes.
      # user_subvol_rm_allowed is needed for recursive subvolume deletion
      mount -t btrfs -o subvol=/,user_subvol_rm_allowed "$BTRFS_VOL" "$MOUNTDIR"

      ROOT_SUBVOL="$MOUNTDIR"/${escapeShellArg root}
      OLD_ROOTS="$MOUNTDIR"/${escapeShellArg oldRoots}

      # ensure subvolume parent dir exists, if not subvol=/
      mkdir -p "$(dirname "$ROOT_SUBVOL")"

      if [[ -e "$ROOT_SUBVOL" ]] ; then
        mkdir -p "$OLD_ROOTS"
        timestamp=$(date --date="@$(stat -c %Y "$ROOT_SUBVOL")" "+%Y-%m-%-d_%H:%M:%S")
        mv "$ROOT_SUBVOL" "$OLD_ROOTS"/"$timestamp"
      fi

      btrfs subvolume create "$ROOT_SUBVOL"

      # i realized that computer clocks never go forwards when
      # they lose time (now my next pc will have an extremely rare
      # firmware bug where the time drifts forward when it is off)
      find "$OLD_ROOTS" -mindepth 1 -maxdepth 1 -type d -inum 256 -mtime +30 -print0 | xargs -0r btrfs subvol delete -R

      # Once we're done rolling back to a blank snapshot,
      # we can unmount /mnt and continue on the boot process.
      umount "$MOUNTDIR"
    '';
  };
  root_vol = "/dev/archdesktop/root";
in {
  config = lib.mkIf (!(config.virtualisation ? qemu)) {
    fileSystems."/persist" = {
      neededForBoot = true;
      device = root_vol;
      fsType = "btrfs";
      options = ["subvol=/nixos/@persist"];
    };

    # TODO volatile btrfs module
    # won't increase size since it already has findutils
    boot.initrd.systemd.extraBin.xargs = "${pkgs.findutils}/bin/xargs";
    boot.initrd.systemd.services.btrfs-volatile-root = btrfsSystemd {
      volume = root_vol;
      root = "/nixos/volatile";
      oldRoots = "/nixos/old_roots";
    };

    fileSystems."/" = lib.mkForce {
      device = root_vol;
      fsType = "btrfs";
      options = ["subvol=/nixos/volatile"];
    };

    # agenix fix
    age.identityPaths = [
      "/persist/backup/etc/ssh/ssh_host_ed25519_key"
    ];

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
          {
            directory = "/etc/passfile";
            mode = "0700";
          }

          # persistent non-declarative config
          "/etc/nixos"
          "/etc/ssh"
          {
            directory = "/etc/wireguard";
            mode = "0700";
          }

          # let's keep the root home dir as well
          {
            directory = "/root";
            mode = "0700";
          }

          # system state
          "/etc/NetworkManager/system-connections"
          "/var/lib/bluetooth"
          "/var/lib/blueman"
          "/var/lib/cups"
          "/var/lib/NetworkManager"
          "/var/lib/power-profiles-daemon"
          "/var/lib/systemd/rfkill"
          "/var/lib/systemd/timesync"
          {
            directory = "/var/lib/tailscale";
            mode = "0700";
          }
          "/var/lib/unbound"
          "/var/db/sudo/lectured"

          # remember login stuff
          {
            directory = "/var/cache/tuigreet";
            user = "greeter";
            group = "greeter";
          }
          {
            directory = "/var/cache/regreet";
            user = "greeter";
            group = "greeter";
          }
          {
            directory = "/var/lib/regreet";
            user = "greeter";
            group = "greeter";
          }
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
