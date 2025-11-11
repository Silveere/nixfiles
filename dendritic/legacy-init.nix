{ self, config, ... }:
let
  nixos = { ... }: {
    imports = [
      (self.outPath + "/system")
    ];
  };
  homeManager = { ... }: {
    imports = [
      (self.outPath + "/home")
    ];
  };

  homeManagerStandalone = { ... }: {
    imports = [
      (self.outPath + "/home/standalone.nix")
      config.flake.modules.homeManager.nixfiles
    ];
  };
in
{
  config = {
    flake.modules = {
      homeManager.nixfiles = homeManager;
      homeManager.nixfiles-standalone = homeManagerStandalone;
      nixos.nixfiles = nixos;
    };
  };
}
