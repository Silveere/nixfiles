{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.common.bluetooth;
in
{
  options.nixfiles.common.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = lib.mkDefault true;
      powerOnBoot = lib.mkDefault true;
    };
  };
}
