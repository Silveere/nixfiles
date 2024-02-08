{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.hardware.bluetooth;
in
{
  options.nixfiles.hardware.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = lib.mkDefault true;
      powerOnBoot = lib.mkDefault true;
    };
  };
}
