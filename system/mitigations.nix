{ pkgs, config, lib, inputs, nixpkgs, ... }:
let
  p5 = config.services.xserver.desktopManager.plasma5.enable;
  p6 = config.services.desktopManager.plasma6.enable;
in
{
  config = lib.mkMerge [
    (lib.mkIf (p5 || p6) {
      assertions = [
        {
          assertion = ((nixpkgs == inputs.nixpkgs-unstable) && nixpkgs.lastModified < (1710889954 + (60*60*24*2)));
          message = "workaround still configured in system/mitigations.nix";
        }
      ];
      programs.gnupg.agent.pinentryPackage = lib.mkForce pkgs.pinentry-qt;
    })
  ];
}
