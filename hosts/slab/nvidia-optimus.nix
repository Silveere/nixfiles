{
  config,
  lib,
  pkgs,
  ...
}: {
  services.supergfxd.enable = true;
  specialisation = {
    nvidia.configuration = {
      system.nixos.tags = ["NVIDIA"];

      nixfiles.supergfxd.profile = "Hybrid";

      # Load nvidia driver for Xorg and Wayland
      services.xserver.videoDrivers = ["amdgpu" "nvidia"];

      hardware.nvidia = {
        # Use the NVidia open source kernel module (not to be confused with the
        # independent third-party "nouveau" open source driver).
        # Support is limited to the Turing and later architectures. Full list of
        # supported GPUs is at:
        # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
        # Only available from driver 515.43.04+
        # Currently alpha-quality/buggy, so false is currently the recommended setting.
        open = false;

        # Enable the Nvidia settings menu,
        # accessible via `nvidia-settings`.
        nvidiaSettings = false;

        # Optionally, you may need to select the appropriate driver version for your specific GPU.
        package = let
          stable = config.boot.kernelPackages.nvidiaPackages.stable;
          version = stable;
        in
          version;

        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          amdgpuBusId = "PCI:07:00:0";
          nvidiaBusId = "PCI:01:00:0";
        };
      };
    };
  };
}
