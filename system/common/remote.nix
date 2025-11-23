{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfiles.common.remoteAccess;
in {
  config = lib.mkIf cfg.enable {
    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
      };
    };

    users.users.root.openssh.authorizedKeys.keys = [
      # hardware key
      # (yes it is called "test" i don't care)
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIISnhXFnXvFlQBDHtf1O2l6kXZPiqZaxXeyMAy6LBwGJAAAABHNzaDo= test"
    ];

    programs.mosh = {
      enable = true;
      openFirewall = true;
    };

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    networking.wireguard.enable = true;
  };
  options = {
    nixfiles.common.remoteAccess.enable = lib.mkEnableOption "remote access options";
  };
}
