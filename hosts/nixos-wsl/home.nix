{ pkgs, lib, config, osConfig ? {}, ... }:
{
  config = {
    nixfiles.profile.base.enable = true;
  };
}
