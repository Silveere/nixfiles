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

    boot.initrd.systemd.mounts = [
      {
        unitConfig.DefaultDependencies = false;
        wantedBy = ["cryptsetup-pre.target"];
        before = ["cryptsetup-pre.target" "shutdown.target" "umount.target"];
        conflicts = ["shutdown.target" "umount.target"];

        what = "/dev/disk/by-uuid/${usb}";
        where = "/key";
        type = "vfat";
        options = ["ro" "nofail"];
      }
    ];

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
