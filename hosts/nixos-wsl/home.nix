{ pkgs, lib, config, osConfig ? {}, ... }:
{
  config = {
    nixfiles = { 
      profile.base.enable = true;
      packageSets.dev.enable = true;
      packageSets.multimedia.enable = true;
      programs.mopidy.enable = true;
    };
    home.file.windows-home = {
      source = config.lib.file.mkOutOfStoreSymlink "/mnt/c/Users/nullbite";
    };
  };
}
