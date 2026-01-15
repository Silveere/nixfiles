{
  self,
  inputs,
  config,
  ...
}: let
  inherit (config.nixfiles) vars;
  nixosModule = {lib, ...}: {
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
      # slightly above mkDefault
      users.users."${vars.username}".initialPassword = lib.mkOverride 990 null;
    };
  };
in {
  config.flake.modules.nixos.avf = nixosModule;
}
