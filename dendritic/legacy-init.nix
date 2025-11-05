{ self }:
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
in
{
  config = {
    flake.modules = {
      homeManager.nixfiles = homeManager;
      nixos.nixfiles = nixos;
    };
  };
}
