{ pkgs, config, lib, ... }:
{
  config = {
    programs.keychain.enable = false;
    nixfiles.packageSets.gaming.enable = true;
    nixfiles.packageSets.gaming.enableLaunchers = false;
  };
}
