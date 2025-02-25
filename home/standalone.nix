# Home Manager default nixfiles entrypoint. This serves as an alternative to
# default.nix, which sets up some more appropriate options for home-manager
{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./.
    inputs.stylix.homeManagerModules.stylix
  ];
  config = {
    # bash is more common on my standalone machines for some reason (low
    # powered things like raspberry pis, the default on steam deck, termux,
    # etc.)
    programs.bash.enable = lib.mkDefault true;
    programs.home-manager.enable = lib.mkDefault true;
    nixfiles = {
      profile.base.enable = lib.mkDefault true;
      packageSets = {
        multimedia.enable = lib.mkDefault true;
      };
    };
  };
}
