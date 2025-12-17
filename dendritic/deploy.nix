{
  self,
  inputs,
  config,
  ...
}: let
  inherit (inputs) deploy-rs;
  configs = config.flake.nixosConfigurations;

  nixpkgs-deploy = inputs.nixpkgs-unstable;

  # this is kinda hacky
  deployPkgs' = system:
    import nixpkgs-deploy {
      inherit system;
      overlays = [
        inputs.deploy-rs.overlays.default
        (self: super: {
          deploy-rs = {
            inherit (nixpkgs-deploy.legacyPackages.${system}) deploy-rs;
            lib = super.deploy-rs.lib;
          };
        })
      ];
    };

  mkProfile = nixosConfiguration: let
    inherit (nixosConfiguration.config.nixpkgs.hostPlatform) system;
    deploy-rs = let
      deployPkgs = deployPkgs' system;
    in
      deployPkgs.deploy-rs;
  in
    deploy-rs.lib.activate.nixos nixosConfiguration;

  nixosModule = {...}: {
    config.users.users.root.openssh.authorizedKeys.keys = config.nixfiles.vars.deployKeys;
  };
in {
  config.flake = {
    modules.nixos.deploy-target = nixosModule;

    deploy = {
      user = "root";
      sshUser = "root";
      interactiveSudo = false;
      autoRollback = true;
      magicRollback = true;

      nodes = {
        rpi4 = {
          hostname = "x.protogen.io";

          profiles.system = {
            path = mkProfile configs.rpi4;
            user = "root";
          };
        };

        nixos-meow = {
          hostname = "nixos-meow.magpie-moth.ts.net";
          profiles.system = {
            path = mkProfile configs.nixos-meow;
            user = "root";
          };
        };

        nixos-px1 = {
          hostname = "nixos-px1.alpha.hel.hz.nullbite.com";
          profiles.system = {
            path = mkProfile configs.nixos-px1;
            user = "root";
          };
        };
      };
    };
  };
}
