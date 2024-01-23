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

    # 33.0.3p2 as suggested by https://xdaforums.com/t/guide-january-3-2024-root-pixel-7-pro-unlock-bootloader-pass-safetynet-both-slots-bootable-more.4505353/
    # android tools versions [ 34.0.0, 34.0.5 ) causes bootloops somehow and 34.0.5 isn't in nixpkgs yet
    pkg-android-tools.url = "github:NixOS/nixpkgs/55070e598e0e03d1d116c49b9eff322ef07c6ac6";

    # provides an up-to-date database for comma
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      inherit (inputs.pkg-android-tools.legacyPackages.${system}) android-tools android-udev-rules;
    };

    # Variables to be passed to NixOS modules in the vars attrset
    vars = {
      inherit username mobileTimeZone self;
    };


    # this is needed to work around an infinite recursion (it probably isn't
    # but i'm stupid)
    _username=username;
    # This function produces a module that adds the home-manager module to the
    # system and configures the given module to the user's Home Manager
    # configuration
    homeManagerInit = {system, username ? _username , module ? _ : {}, rootModule ? (import ./home/root.nix), userModules ? { ${username} = [ module ] ; root = [ rootModule ]; }, stateVersion }:
    { config, lib, pkgs, ... }:
    let
      mapUserModules = lib.attrsets.mapAttrs (user: modules: {...}:
      {
        imports = modules;
        config = {
          home = { inherit stateVersion; };
        };
      });
      users = mapUserModules userModules;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        inherit users;
        extraSpecialArgs = {
          inherit inputs outputs vars;
          extraPkgs = mkExtraPkgs system;
        };
      };
    };

    # This function produces a nixosSystem which imports configuration.nix and
    # a Home Manager home.nix for the given user from ./hosts/${hostname}/
    mkSystem = {system, hostname, username ? _username, stateVersion}:
      lib.nixosSystem {
        inherit system;
        modules = [
          ({pkgs, config, lib, ...}@args: 
            {
              # Values for every single system that would not conceivably need
              # to be made modular
              system.stateVersion = stateVersion;
              # not having the freedom to install unfree programs is unfree
              nixpkgs.config.allowUnfree = true;
              nix.settings.experimental-features = ["nix-command" "flakes" ];
            })
          ./hosts/${hostname}/configuration.nix
          (homeManagerInit {
            module = import ./hosts/${hostname}/home.nix;
            inherit username system stateVersion;
          })
        ];
        specialArgs = {
          inherit inputs outputs vars;
          extraPkgs = mkExtraPkgs system;
        };
      };

    moduleInputs = {
      inherit mkExtraPkgs;
    };

  in {
    # for repl debugging via :lf .
    inherit inputs vars;

    # nix flake modules are meant to be portable so we cannot rely on
    # (extraS|s)pecialArgs to pass variables
    nixosModules = (import ./modules/nixos) moduleInputs;
    homeManagerModules = (import ./modules/home-manager) moduleInputs;

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
          ./system/android.nix
          # ./system/hyprland.nix
          (homeManagerInit {
            # module = import ./hosts/slab/home.nix;
            inherit system;
            stateVersion = "23.11";
            # rootModule = import ./home/root.nix;
            userModules = { ${username} = [(import ./hosts/slab/home.nix)]; root = [(import ./home/root.nix)]; };
          })
        ];
        specialArgs = {
          inherit inputs outputs vars;
          extraPkgs = mkExtraPkgs system;
        };
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
            stateVersion = "23.11";
          })
        ];
      };
    };
  };
}
