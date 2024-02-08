{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.common.nvidia;
in
{
  # imports = [
  #   ../opengl.nix
  # ];

  # Load nvidia driver for Xorg and Wayland
  options.nixfiles.common.nvidia = {
    modesetting.enable = lib.mkEnableOption "NVIDIA configuration with modesetting";
  };
  config = lib.mkIf cfg.modesetting.enable {
    services.xserver.videoDrivers = ["nvidia"];

    nixfiles.common.opengl.enable = true;

    hardware.nvidia = {

      # Modesetting is required.
      modesetting.enable = lib.mkDefault true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      powerManagement.enable = lib.mkDefault false;
      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = lib.mkDefault false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of 
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = lib.mkDefault false;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = lib.mkDefault true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.production;
    };
  };
}
