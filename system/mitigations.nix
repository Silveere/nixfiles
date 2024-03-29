{ pkgs, config, lib, inputs, nixpkgs, ... }:
let
  p5 = config.services.xserver.desktopManager.plasma5.enable;
  p6 = config.services.desktopManager.plasma6.enable;

  isNewer = ref: ver: ((builtins.compareVersions ver ref) == 1);

  # kernel update
  newKernelPackages = inputs.nixpkgs-staging-next.legacyPackages.${pkgs.system}.linuxPackages_latest;
in
{
  config = lib.mkMerge [
    {
      boot.kernelPackages = newKernelPackages;
      assertions = [
        { assertion = (!(isNewer "6.8" nixpkgs.legacyPackages.${pkgs.system}.linuxPackages.kernel.version));
          message = "Kernel is no longer outdated. Please remove this."; }
      ];
    }
  ];
}
