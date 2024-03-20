{ pkgs, lib, config, ... }:
{
  config = {
    networking.networkmanager.dns = "none";
    services.unbound.enable = true;
  };
}
