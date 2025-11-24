{config, ...}: let
  inherit (config.nixfiles) vars;
  nixosModule = {
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

      users.users.root.openssh.authorizedKeys.keys = vars.deployKeys;

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
  };
in {
  config.flake.modules.nixos.nixfiles = nixosModule;
}
