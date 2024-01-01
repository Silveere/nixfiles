{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
                 # ^^^^^^^^^^^^^ this part is optional
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs: 
  let
    lib = nixpkgs.lib;
    lib-unstable = nixpkgs-unstable.lib;
    username = "nullbite";
    hmModule = home-manager.nixosModules.home-manager;
    hmModuleDefaults = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    };
  in {
    # for repl debugging via :lf .
    inherit inputs;
    vars = {
      inherit lib lib-unstable username;
    };

    nixosConfigurations = {
      slab = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/slab/configuration.nix
          ./hosts/slab/nvidia-optimus.nix
          ./system/remote.nix
          ./system/plasma.nix
          ./system/fragments/opengl.nix
          ./system/gaming.nix
          ./system/hyprland.nix
          hmModule (hmModuleDefaults // {
            home-manager.users."${username}" = import ./hosts/slab/home.nix;
          })
        ];
      };
      nullbox = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nullbox/configuration.nix
          ./system/remote.nix
          ./system/plasma.nix
          ./system/fragments/hardware/nvidia-modeset.nix
          ./system/gaming.nix

          hmModule (hmModuleDefaults // {
            home-manager.users."${username}" = import ./hosts/nullbox/home.nix;
          })

        ];
      };
    };
  };
}
