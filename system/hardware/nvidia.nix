{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.hardware.nvidia;
  
  rcu_patch = pkgs.fetchpatch {
    url = "https://github.com/gentoo/gentoo/raw/c64caf53/x11-drivers/nvidia-drivers/files/nvidia-drivers-470.223.02-gpl-pfn_valid.patch";
    hash = "sha256-eZiQQp2S/asE7MfGvfe6dA/kdCvek9SYa/FFGp24dVg=";
  };

  nvidia_555 = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "555.42.02";
    sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
    sha256_aarch64 = lib.fakeSha256;
    openSha256 =  "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
    settingsSha256 =  "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
    persistencedSha256 = lib.fakeSha256;
  };

  nvidia_535 = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "535.154.05";
    sha256_64bit = "sha256-fpUGXKprgt6SYRDxSCemGXLrEsIA6GOinp+0eGbqqJg=";
    sha256_aarch64 = "sha256-G0/GiObf/BZMkzzET8HQjdIcvCSqB1uhsinro2HLK9k=";
    openSha256 = "sha256-wvRdHguGLxS0mR06P5Qi++pDJBCF8pJ8hr4T8O6TJIo=";
    settingsSha256 = "sha256-9wqoDEWY4I7weWW05F4igj1Gj9wjHsREFMztfEmqm10=";
    persistencedSha256 = "sha256-d0Q3Lk80JqkS1B54Mahu2yY/WocOqFFbZVBh+ToGhaE=";

    patches = [ rcu_patch ];
  };
in
{
  # imports = [
  #   ../opengl.nix
  # ];

  # Load nvidia driver for Xorg and Wayland
  options.nixfiles.hardware.nvidia = {
    modesetting.enable = lib.mkEnableOption "NVIDIA configuration with modesetting";
  };
  config = lib.mkIf cfg.modesetting.enable {
    services.xserver.videoDrivers = ["nvidia"];

    nixfiles.hardware.opengl.enable = true;

    boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

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
      open = lib.mkDefault (!(lib.versionOlder config.hardware.nvidia.package.version "560"));
      # to match <nixpkgs/nixos/modules/hardware/video/nvidia.nix>

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = lib.mkDefault true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = let
        inherit (config.boot.kernelPackages.nvidiaPackages) production stable latest beta;
      in lib.mkDefault beta;
    };
  };
}
