{ config, lib, pkgs, inputs, ...}:
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
    useUnstableUcmConf = lib.mkOption {
      description = "Whether to enable unstable alsa-ucm-conf. This seems to cause a mass rebuild and requires a lot of packages to be built from source, so it should only be used if necessary.";
      default = false;
      example = true;
      type = lib.types.bool;
    };
  };

  config = lib.mkMerge [(mkIf cfg.enable {
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
  })
  ({
    # use alsa-ucm-conf from unstable (fixes Scarlett Solo channels)
    nixpkgs.overlays = lib.optional cfg.useUnstableUcmConf (final: prev: {
      inherit (inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}) alsa-ucm-conf;
    });
  })
  ];
}
