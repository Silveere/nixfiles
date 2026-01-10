{self, ...}: let
  unstableModules = let
    m = self.modules.nixos;
  in [m."nixfiles-26.05"];
  stableModules = let
    m = self.modules.nixos;
  in [
    m."nixfiiles-25.11"
  ];
in {
  config.flake.modules.nixos = {
    nixfiles.imports = unstableModules;
    nixfiles-stable.imports = stableModules;
  };
}
