{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
                 # ^^^^^^^^^^^^^ this part is optional
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # this seems to be a popular way to declare systems
    systems.url = "github:nix-systems/default";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # 33.0.3p2 as suggested by https://xdaforums.com/t/guide-january-3-2024-root-pixel-7-pro-unlock-bootloader-pass-safetynet-both-slots-bootable-more.4505353/
    # android tools versions [ 34.0.0, 34.0.5 ) causes bootloops somehow and 34.0.5 isn't in nixpkgs yet
    pkg-android-tools.url = "github:NixOS/nixpkgs/55070e598e0e03d1d116c49b9eff322ef07c6ac6";

    nix-minecraft = {
      url = "github:infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # provides an up-to-date database for comma
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # no inputs.nixpkgs.follows so i can use cachix
    hyprland.url = "github:hyprwm/Hyprland";

    hyprwm-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nixfiles-assets = {
      # using self-hosted gitea mirror because of GitHub LFS bandwidth limit (even though i'd probably never hit it)
      type = "github";
      owner = "Silveere";
      repo = "nixfiles-assets";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: 
  let
    inherit (self) outputs;
    # inputs is already defined
    lib = nixpkgs.lib;
    systems = [ "x86_64-linux" "aarch64-linux" ];

    overlays = [
      /* android-tools 33.0.3p2 */ (final: prev: {
        inherit (inputs.pkg-android-tools.legacyPackages.${final.system})
          android-tools android-udev-rules;
      })
      (final: prev: let
        packages = import ./pkgs { inherit (prev) pkgs; };
      in {
        inherit (packages) mopidy-autoplay google-fonts;
        atool-wrapped = packages.atool;
      })

      # various temporary fixes that automatically revert
      self.overlays.mitigations

      # auto backports from nixpkgs unstable
      self.overlays.backports

      inputs.hyprwm-contrib.overlays.default
      inputs.rust-overlay.overlays.default
      inputs.nixfiles-assets.overlays.default
      inputs.nix-minecraft.overlays.default
      # inputs.hypridle.overlays.default
      (final: prev: { inherit (inputs.hypridle.packages.${prev.system}) hypridle; })
    ];

    ### Configuration
    # My username
    username = "nullbite";
    # My current timezone for any mobile devices (i.e., my laptop)
    mobileTimeZone = "America/New_York";

    # define extra packages here
    mkExtraPkgs = system: {
      # android-tools = inputs.pkg-android-tools.legacyPackages.${system}.android-tools;
      inherit (inputs.pkg-android-tools.legacyPackages.${system}) android-tools android-udev-rules;
    };

    # Variables to be passed to NixOS modules in the vars attrset
    vars = {
      inherit username mobileTimeZone self;
    };

    # funciton to generate packages for each system
    eachSystem = lib.genAttrs (import inputs.systems);

    # This function produces a module that adds the home-manager module to the
    # system and configures the given module to the user's Home Manager
    # configuration
    homeManagerInit = let _username=username; _nixpkgs=nixpkgs;
    in { system,
        nixpkgs ? _nixpkgs, # this is so modules can know which flake the system is using
        home-manager ? inputs.home-manager,
        username ? _username,
        module ? _ : {},
        rootModule ? (import ./home/root.nix),
        userModules ? { ${username} = [ module ] ; root = [ rootModule ]; },
        stateVersion }:
      { config, lib, pkgs, ... }:
      let
        mapUserModules = lib.attrsets.mapAttrs (user: modules: {...}:
        {
          imports = [
            ./home
          ] ++ modules;
          config = {
            home = { inherit stateVersion; };
          };
        });
        users = mapUserModules userModules;
      in
      {
        imports = [
          home-manager.nixosModules.home-manager
        ];

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          inherit users;
          extraSpecialArgs = {
            inherit inputs outputs vars nixpkgs home-manager;
            extraPkgs = mkExtraPkgs system;
          };
        };
      };

    # TODO rewrite this so it follows the same wrapper pattern as mkHome
    # This function produces a nixosSystem which imports configuration.nix and
    # a Home Manager home.nix for the given user from ./hosts/${hostname}/
    mkSystem = let _username=username; _overlays=overlays; _nixpkgs=nixpkgs;
    in { system,
        nixpkgs ? _nixpkgs,
        home-manager ? inputs.home-manager,
        overlays ? _overlays,
        hostname,
        username ? _username,
        stateVersion,
        extraModules ? [] }:

      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./system
          ({pkgs, config, lib, ...}@args: 
            {
              # Values for every single system that would not conceivably need
              # to be made modular
              system.stateVersion = stateVersion;
              nixpkgs = {
                inherit overlays;
                config = {
                  # not having the freedom to install unfree programs is unfree
                  allowUnfree = true;
                };
              };
              nix.settings.experimental-features = ["nix-command" "flakes" ];
            })
          ./hosts/${hostname}/configuration.nix
          (homeManagerInit {
            inherit nixpkgs home-manager;
            module = import ./hosts/${hostname}/home.nix;
            inherit username system stateVersion;
          })
        ] ++ extraModules;
        specialArgs = {
          inherit inputs outputs vars nixpkgs home-manager;
          extraPkgs = mkExtraPkgs system;
        };
      };

    mkWSLSystem = let _username=username; in
      {username ? _username, extraModules ? [], ...}@args: let
        WSLModule = {...}: {
          imports = [
            inputs.nix-wsl.nixosModules.wsl
          ];
          wsl.enable = true;
          wsl.defaultUser = username;
        };
        override = {extraModules = extraModules ++ [WSLModule];};
      in
        mkSystem (args // override);

    # values to be passed to nixosModules and homeManagerModules wrappers
    moduleInputs = {
      inherit mkExtraPkgs;
    };

    # Make a home-manager standalone configuration. This implementation is
    # better than mkSystem because it extends homeManagerConfiguration.
    mkHome = let
      _home-manager = inputs.home-manager;
      _nixpkgs = inputs.nixpkgs;
      _username = username;
    in { home-manager ? _home-manager,
          nixpkgs ? _nixpkgs,
          username ? _username,
          homeDirectory ? "/home/${username}",
          entrypoint ? ./home/standalone.nix,
          modules ? [ ],
          stateVersion ? null,
          config ? { },
          system,
          ... }@args: let
      _modules = [ entrypoint ] ++ modules ++ [ config ] ++ [
        {
          config = {
            home = {
              inherit username homeDirectory;
            };
            nixpkgs.config = {
              allowUnfree = true;
            };
          };
        }
      ] ++ lib.optional (args ? stateVersion) { config.home.stateVersion = stateVersion; };
    in home-manager.lib.homeManagerConfiguration ({
      modules = _modules;
      pkgs = import nixpkgs {inherit system overlays; };

      extraSpecialArgs = {
        inherit inputs outputs vars nixpkgs home-manager;
        extraPkgs = mkExtraPkgs system;

        # this is needed because modules don't use the default arg for some reason???
        osConfig = {};
      };
    } // builtins.removeAttrs args
      [ "system" "nixpkgs" "home-manager" "modules" "username" "homeDirectory" "stateVersion" "entrypoint" "config" ]);

  in {
    # for repl debugging via :lf .
    inherit inputs vars;

    devShells = eachSystem (system: let
      pkgs = import nixpkgs-unstable { inherit system; };
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nix-update
        ];
      };
    });

    # nix flake modules are meant to be portable so we cannot rely on
    # (extraS|s)pecialArgs to pass variables
    nixosModules = (import ./modules/nixos) moduleInputs;
    homeManagerModules = (import ./modules/home-manager) moduleInputs;
    packages = eachSystem (system: let pkgs = import nixpkgs { inherit system; };
      in import ./pkgs { inherit pkgs; });
    apps = eachSystem (system: import ./pkgs/apps.nix
      { inherit (self.outputs) packages; inherit system; });

    overlays = import ./overlays self;

    nixosConfigurations = {
      slab = mkSystem {
        nixpkgs = inputs.nixpkgs-unstable;
        home-manager = inputs.home-manager-unstable;
        system = "x86_64-linux";
        hostname = "slab";
        stateVersion = "23.11";
      };

      nullbox = mkSystem {
        nixpkgs = inputs.nixpkgs-unstable;
        home-manager = inputs.home-manager-unstable;
        system = "x86_64-linux";
        hostname = "nullbox";
        stateVersion = "23.11";
      };

      nixos-wsl = mkWSLSystem {
        nixpkgs = inputs.nixpkgs-unstable;
        home-manager = inputs.home-manager-unstable;
        system = "x86_64-linux";
        stateVersion = "23.11";
        hostname = "nixos-wsl";
      };
    }; # end nixosConfigurations

    homeConfigurations = {
      # minimal root config for installing terminfo
      "root@rpi4" = mkHome {
        system = "aarch64-linux";
        stateVersion = "23.11";
        config.programs = {
          bash.enable = true;
        };
        nixpkgs = inputs.nixpkgs-unstable;
        home-manager = inputs.home-manager-unstable;
      };

      "nullbite@rpi4" = mkHome {
        system = "aarch64-linux";
        stateVersion = "23.11";
        config.programs = {
          zsh.enable = false;
          keychain.enable = false;
        };
        nixpkgs = inputs.nixpkgs-unstable;
        home-manager = inputs.home-manager-unstable;
      };
      "deck" = mkHome {
        system = "x86_64-linux";
        stateVersion = "23.11";
        username = "deck";
        modules = [ ./users/deck/home.nix ];
        nixpkgs = inputs.nixpkgs-unstable;
        home-manager = inputs.home-manager-unstable;
      };
      "testuser" = mkHome {
        username = "testuser";
        system = "x86_64-linux";
        modules = [ ./users/testuser/home.nix ];
        stateVersion = "23.11";
        nixpkgs = inputs.nixpkgs-unstable;
        home-manager = inputs.home-manager-unstable;
      };
      "nix-on-droid" = mkHome {
        username = "nix-on-droid";
        homeDirectory = "/data/data/com.termux.nix/files/home";
        modules = [ ./users/nix-on-droid/home.nix ];
        system = "aarch64-linux";
        stateVersion = "23.11";
        nixpkgs = inputs.nixpkgs-unstable;
        home-manager = inputs.home-manager-unstable;
      };
    };
  }; # end outputs
} # end flake
