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

    # TODO once i have a better way to manage multiarch packages
    # 33.0.3p2 as suggested by https://xdaforums.com/t/guide-january-3-2024-root-pixel-7-pro-unlock-bootloader-pass-safetynet-both-slots-bootable-more.4505353/
    # android tools versions [ 34.0.0, 34.0.5 ) causes bootloops somehow and 34.0.5 isn't in nixpkgs yet
    pkg-android-tools.url = "github:NixOS/nixpkgs/55070e598e0e03d1d116c49b9eff322ef07c6ac6";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: 
  let
    inherit (self) outputs;
    # inputs is already defined
    lib = nixpkgs.lib;
    systems = [ "x86_64-linux" "aarch64-linux" ];

    ### Configuration
    # My username
    username = "nullbite";
    # My current timezone for any mobile devices (i.e., my laptop)
    mobileTimeZone = "Europe/Amsterdam";

    # define extra packages here
    mkExtraPkgs = system: {
      # android-tools = inputs.pkg-android-tools.legacyPackages.${system}.android-tools;
      inherit (inputs.pkg-android-tools.legacyPackages.${system}) android-tools;
    };

    # Variables to be passed to NixOS modules in the vars attrset
    vars = {
      inherit username mobileTimeZone;
    };


    # This function produces a module that adds the home-manager module to the
    # system and configures the given module to the user's Home Manager
    # configuration
    homeManagerInit = {system, username ? username , module}: { config, lib, pkgs, ... }: {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = module;
        extraSpecialArgs = {
          inherit inputs outputs vars;
          extraPkgs = mkExtraPkgs system;
        };
      };
    };

    # This function produces a nixosSystem which imports configuration.nix and
    # a Home Manager home.nix for the given user from ./hosts/${hostname}/
    mkSystem = {system, hostname, username ? username}:
      lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/${hostname}/configuration.nix
          (homeManagerInit {
            module = import ./hosts/${hostname}/home.nix;
            inherit username system;
          })
        ];
        specialArgs = {
          inherit inputs outputs vars;
          extraPkgs = mkExtraPkgs system;
        };
      };

  in {
    # for repl debugging via :lf .
    inherit inputs;
    vars = {
      inherit lib username;
    };

    nixosConfigurations = {
      slab = lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          ./hosts/slab/configuration.nix
          ./hosts/slab/nvidia-optimus.nix
          ./system/remote.nix
          ./system/plasma.nix
          ./system/fragments/opengl.nix
          ./system/gaming.nix
          # ./system/hyprland.nix
          (homeManagerInit {
            module = import ./hosts/slab/home.nix;
            inherit system;
          })
        ];
      };
      nullbox = lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          ./hosts/nullbox/configuration.nix
          ./system/remote.nix
          ./system/plasma.nix
          ./system/fragments/hardware/nvidia-modeset.nix
          ./system/gaming.nix
          (homeManagerInit {
            module = import ./hosts/nullbox/home.nix;
            inherit system;
          })
        ];
      };
    };
  };
}
