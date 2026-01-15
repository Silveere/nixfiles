{
  pkgs,
  lib,
  config,
  osConfig ? {},
  ...
}: {
  config = {
    nixfiles = {
      profile.base.enable = true;
      packageSets.multimedia.enable = true;
    };
    home.file.sdcard = {
      source = config.lib.file.mkOutOfStoreSymlink "/mnt/shared/";
    };
  };
}
