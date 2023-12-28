{ config, lib, pkgs, ...}:
{
  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  environment.systemPackages = with pkgs; [
    qpwgraph
    pavucontrol
    ncpamixer
    pulsemixer
    easyeffects
  ];
}
