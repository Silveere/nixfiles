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
      # slightly above mkDefault
      users.users."${vars.username}".initialPassword = lib.mkOverride 990 null;
    };
  };
in {
  config.flake.modules.nixos.avf = nixosModule;
}
