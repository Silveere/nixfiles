{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfiles.hardware.laptop;
in {
  options.nixfiles.hardware.laptop = {
    enable =
      lib.mkEnableOption ""
      // {
        description = ''
          Whether to enable laptop configuration options for hardware and power.
        '';
      };
  };
  config = lib.mkIf cfg.enable {
    services.upower = {
      enable = lib.mkDefault true;
      # this is logind's job
      ignoreLid = lib.mkDefault true;

      # i like these defaults better
      percentageLow = lib.mkDefault 20;
      percentageCritical = lib.mkDefault 10;
      percentageAction = lib.mkDefault 5;
      criticalPowerAction = lib.mkDefault "Hibernate";
    };

    services.power-profiles-daemon = {
      enable = lib.mkDefault true;
    };
  };
}
