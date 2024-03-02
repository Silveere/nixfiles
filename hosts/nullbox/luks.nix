{ pkgs, config, lib, ... }:
let
  usb = "903D-DF5B";
in
{
  config = {
    # cryptsetup
    boot.initrd.kernelModules = ["uas" "usbcore" "usb_storage"];
    boot.initrd.supportedFilesystems = ["vfat"];

    boot.initrd.luks.devices = {
      lvmroot = {
        preOpenCommands = ''
          mkdir -m 0755 /key
          sleep 1
          mount -n -t vfat -o ro `findfs UUID=${usb}` /key
        '';

        device="/dev/disk/by-uuid/85b5f22e-0fa5-4f0d-8fba-f800a0b41671";
        keyFile = "/key/image.png"; # yes it's literally an image file. bite me
        allowDiscards = true;
        fallbackToPassword = true;
        preLVM = true;
      };
    };
  };
}
