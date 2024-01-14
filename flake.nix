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

    # Variables to be passed to NixOS modules in the vars attrset
    vars = {
      inherit username mobileTimeZone;
    };

    # This function produces a module that adds the home-manager module to the
    # system and configures the given module to the user's Home Manager
    # configuration
    homeManagerInit = user: module: { config, lib, pkgs, ... }: {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user} = module;
      };
    };

    mkExtraPkgs = system: {
      android-tools = inputs.pkg-android-tools.legacyPackages.${system}.android-tools;
    };

    mkSystem = system: hostname:
      let
        extraPkgs = mkExtraPkgs system;
      in
        lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/${hostname}/configuration.nix
            (homeManagerInit username (import ./hosts/${hostname}/home.nix))
          ];
          specialArgs = {
            inherit inputs outputs vars extraPkgs;
          };
        };

  in {
    # for repl debugging via :lf .
    inherit inputs;
    vars = {
      inherit lib username;
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
          # ./system/hyprland.nix
          (homeManagerInit username (import ./hosts/slab/home.nix))
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
          (homeManagerInit username (import ./hosts/nullbox/home.nix))
        ];
      };
    };
  };
}
