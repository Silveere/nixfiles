{
  pkgs,
  config,
  lib,
  ...
}: let
  usb = "903D-DF5B";
in {
  config = {
    # cryptsetup
    boot.initrd.kernelModules = ["uas" "usbcore" "usb_storage"];
    boot.initrd.supportedFilesystems = ["vfat"];

    boot.initrd.systemd.services.cryptsetup-keyfile = {
      description = "set up keyfile for LUKS";
      wantedBy = ["cryptsetup-pre.target"];
      before = ["cryptsetup-pre.target" "shutdown.target"];
      conflicts = ["shutdown.target"];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      # this should probably be a mount unit but i don't care question mark
      script = ''
        mkdir -m 0755 /key
        sleep 1
        mount -n -t vfat -o ro "$(findfs UUID=${usb})" /key
      '';
    };

    boot.initrd.luks.devices = {
      lvmroot = {
        device = "/dev/disk/by-uuid/85b5f22e-0fa5-4f0d-8fba-f800a0b41671";
        keyFile = "/key/image.png"; # yes it's literally an image file. bite me
        allowDiscards = true;
        preLVM = true;
      };
    };
  };
}
