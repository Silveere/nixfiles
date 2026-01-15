{
  self,
  inputs,
  config,
  ...
}: let
  inherit (config.nixfiles) vars;
  nixosModule = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      inputs.nixos-avf.nixosModules.avf
    ];
    config = {
      avf.defaultUser = lib.mkDefault "${vars.username}";

      # revive default user for testing
      users.users.droid = {
        isNormalUser = true;
        extraGroups = ["droid" "wheel"];
      };
      users.groups.droid = {};

      # proper uid/gid config
      users.users."${vars.username}" = {
        # slightly above mkDefault
        initialPassword = lib.mkOverride 990 null;
        uid = 1001;
      };
      users.groups."${vars.username}" = {
        gid = 994;
      };

      environment.systemPackages = let
        # mount helper to run it as user `droid` so i can use fstab/systemd mounts
        bindfs-droid = pkgs.writeShellScriptBin "mount.fuse.bindfs.droid" ''
          set -Eeuxo pipefail
          ${pkgs.coreutils}/bin/chown droid "$2"
          exec ${pkgs.util-linux}/bin/setpriv --reuid droid --regid droid --init-groups -- ${pkgs.bindfs}/bin/mount.fuse.bindfs "$@"
        '';
      in [
        pkgs.bindfs
        bindfs-droid
      ];

      fileSystems."/mnt/shared-mirror" = {
        device = "/mnt/shared";
        fsType = "fuse.bindfs.droid";
        options = [
          "allow_other"
          "mirror-only=${vars.username}"
          "create-as-mounter"
          "chown-ignore"
          "chgrp-ignore"
          "chmod-ignore"
          "perms=0600:u+X"
          "nofail"
        ];
      };
    };
  };
in {
  config.flake.modules.nixos.avf = nixosModule;
}
