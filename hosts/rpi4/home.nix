{ config, ... }:
{
  config = {
    nixfiles.profile.base.enable = true;
    programs.keychain.enable = false;
  };
}
