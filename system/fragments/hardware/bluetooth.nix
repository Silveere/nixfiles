{ config, lib, pkgs, ...}:
{
  hardware.bluetooth = {
    enable = lib.mkDefault true;
    powerOnBoot = lib.mkDefault true;
  };
}
