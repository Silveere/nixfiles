nixfiles: final: prev:
let
  inherit (prev) callPackage fetchFromGitHub;
  inherit (prev.lib) recurseIntoAttrs optionalAttrs;

  xz-hold = nixfiles.inputs.nixpkgs-unstable.legacyPackages.${prev.system}.xz.version == "5.6.1";
  xz-fixed = (nixfiles.inputs.nixpkgs-staging-next.legacyPackages.${prev.system}.xz);

  # if you can't do version based just make it time based and deal with it in a
  # month if it's not fixed
  # 2024-04-10T08:11:11
  gap-hold = (nixfiles.inputs.nixpkgs-unstable.lastModified <= 1712751071);
  gimpPlugins-gap = let
    src = fetchFromGitHub {
      owner = "Scrumplex";
      repo = "nixpkgs";
      rev = "cca25fd345f2c48de66ff0a950f4ec3f63e0420f";
      hash="sha256-oat4TwOorFevUMZdBFgaQHx/UKqGW7CGMoOHVgQxVdM="; 
    };
  in recurseIntoAttrs (callPackage "${src}/pkgs/applications/graphics/gimp/plugins" {});
in (optionalAttrs gap-hold { gimpPlugins = gimpPlugins-gap; }) //
  (optionalAttrs xz-hold { xz=xz-fixed; })
