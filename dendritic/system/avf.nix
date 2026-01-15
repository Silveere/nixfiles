{
  self,
  inputs,
  config,
  ...
}: let
  inherit (config.nixfiles) vars;
  nixosModule = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      inputs.nixos-avf.nixosModules.avf
    ];
    config = {
      avf.defaultUser = lib.mkDefault "${vars.username}";

      # revive default user for testing
      users.users.droid = {
        isNormalUser = true;
        extraGroups = ["droid" "wheel"];
      };
      users.groups.droid = {};

      # proper uid/gid config
      users.users."${vars.username}" = {
        # slightly above mkDefault
        initialPassword = lib.mkOverride 990 null;
        uid = 1001;
      };
      users.groups."${vars.username}" = {
        gid = 994;
      };
    };
  };
in {
  config.flake.modules.nixos.avf = nixosModule;
}
