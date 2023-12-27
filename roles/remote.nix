{ config, lib, pkgs, ... }:
{
  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {

    };
  };

  services.tailscale.enable = true;
}
