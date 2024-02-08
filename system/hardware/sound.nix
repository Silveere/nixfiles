{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.hardware.sound;
  inherit (lib) optionals mkEnableOption mkIf mkDefault;
in
{
  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  options.nixfiles.hardware.sound = {
    enable = mkEnableOption "sound configuration";
  };

  config = mkIf cfg.enable {
    security.rtkit.enable = mkDefault true;
    services.pipewire = {
      enable = true;
      alsa.enable = mkDefault true;
      alsa.support32Bit = mkDefault config.services.pipewire.alsa.enable;
      pulse.enable = mkDefault true;
      jack.enable = mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      qpwgraph
      easyeffects
    ] ++ optionals config.services.pipewire.pulse.enable [
      pavucontrol
      ncpamixer
      pulsemixer
    ];
  };
}
