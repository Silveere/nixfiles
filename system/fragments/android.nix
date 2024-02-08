{ config, lib, pkgs, outputs, vars, ...}@args:
{
  imports = [ outputs.nixosModules.adb ];
  
  config = {
    programs.adb.enable = true;
    users.users.${vars.username}.extraGroups = [ "adbusers" ];
  };
}
