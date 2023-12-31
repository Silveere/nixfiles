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

    # to use this add `homeModules <username> [ ... ]` to a system's modules.
    homeModules = user: modules: home-manager.nixosModules.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users."${user}" = {lib, config, pkgs, osConfig, ...}:
      {
        imports = modules;
      };
    };
  in {
    # for repl debugging via :lf .
    inherit inputs;
    lets = {
      inherit lib lib-unstable username homeModules;
    };

    nixosConfigurations = {
      slab = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/slab/configuration.nix
          ./hosts/slab/nvidia-optimus.nix
          ./roles/remote.nix
          ./roles/plasma.nix
          ./fragments/opengl.nix
          ./roles/gaming.nix
        ];
      };
      nullbox = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nullbox/configuration.nix
          ./roles/remote.nix
          ./roles/plasma.nix
          ./fragments/hardware/nvidia-modeset.nix
          ./roles/gaming.nix

          hmModule (hmModuleDefaults // {
            home-manager.users."${username}" = import ./home.nix;
          })

        ];
      };
    };
  };
}
