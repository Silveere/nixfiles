nixfiles: final: prev:
let
  inherit (prev) callPackage fetchFromGitHub;
  inherit (prev.lib) recurseIntoAttrs optionalAttrs;
  isNewer = ref: ver: (builtins.compareVersions ver ref) == 1;

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
  # can't optionalAttrs for version checks because it breaks lazy eval and causes infinite recursion
  {
    obsidian = let
      pkg = final.callPackage "${nixfiles.inputs.nixpkgs-unstable}/pkgs/applications/misc/obsidian" { electron = final.electron_28; };
    in if isNewer "1.4.16" prev.obsidian.version then prev.obsidian else pkg;
  }
