{
  inputs,
  config,
  ...
}: let
  inherit (config.nixfiles.lib.flake-legacy) mkHome;
in {
  config.flake = {
    nixOnDroidConfigurations.default =
      inputs.nix-on-droid.lib.nixOnDroidConfiguration {
      };

    homeConfigurations."nix-on-droid" = mkHome {
      username = "nix-on-droid";
      homeDirectory = "/data/data/com.termux.nix/files/home";
      modules = [./users/nix-on-droid/home.nix];
      system = "aarch64-linux";
      stateVersion = "23.11";
      nixpkgs = inputs.nixpkgs-unstable;
      home-manager = inputs.home-manager-unstable;
    };
  };
}
