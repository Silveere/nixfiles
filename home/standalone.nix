# Home Manager default nixfiles entrypoint. Currently this file does nothing
# besides import default.nix
{ pkgs, config, lib, ... }:
{
  imports = [
    ./.
  ];
}
