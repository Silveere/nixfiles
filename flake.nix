{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
                 # ^^^^^^^^^^^^^ this part is optional
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixpkgs-yt-dlp-2024.url = "github:NixOS/nixpkgs/528db5fa94041f0b4909a855d8b9fb9b44fa4f5d";

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

    nix-minecraft = {
      url = "github:Silveere/nix-minecraft/quilt-revert";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-minecraft-upstream = {
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
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

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

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    stylix = {
      url = "github:danth/stylix?ref=e8e3304c2f8cf2ca60dcfc736a7422af2f24b8a8";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

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

    overlays = let
      nix-minecraft-patched-overlay = let
        normal = inputs.nix-minecraft-upstream.overlays.default;
        quilt = inputs.nix-minecraft.overlays.default;
      in lib.composeExtensions
        normal
        (final: prev: let
          x=quilt final prev;
        in {
          inherit (x) quiltServers quilt-server;
          minecraftServers = prev.minecraftServers // x.quiltServers;
        });
    in [
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
      nix-minecraft-patched-overlay
      # inputs.hypridle.overlays.default
      (final: prev: { inherit (inputs.hypridle.packages.${prev.system}) hypridle; })
    ];

    ### Configuration
    # My username
    username = "nullbite";
    # My current timezone for any mobile devices (i.e., my laptop)
    mobileTimeZone = "America/New_York";

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
          backupFileExtension = "hm.bak";
          inherit users;
          extraSpecialArgs = {
            inherit inputs outputs vars nixpkgs home-manager;
          };
        };
      };

    # TODO rewrite this so it follows the same wrapper pattern as mkHome
    # This function produces a nixosSystem which imports configuration.nix and
    # a Home Manager home.nix for the given user from ./hosts/${hostname}/
    mkSystemN = let
      _username = username;
      _overlays = overlays;
    in { nixpkgs ? inputs.nixpkgs,
          home-manager ? inputs.home-manager,
          username ? _username,
          entrypoint ? ./system,
          modules ? [ ],
          stateVersion ? null,
          config ? { },
          overlays ? _overlays,
          system,
          ... }@args: let
        _modules = [ entrypoint config ] ++ modules ++ [{
          nixpkgs.config = {
            inherit overlays;
            allowUnfree = true;
          };
        }] ++ lib.optional (args ? stateVersion) { config.system.stateVersion = stateVersion; };
      in nixpkgs.lib.nixosSystem {
      };
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

    mkISOSystem = system: inputs.nixpkgs-unstable.lib.nixosSystem {
      inherit system;
      modules = [
        "${inputs.nixpkgs-unstable}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
        ({ config, pkgs, lib, ... }:
        {
          environment.systemPackages = with pkgs; [
            neovim
            gparted
          ];
        })
      ];
    };

    # values to be passed to nixosModules and homeManagerModules wrappers
    moduleInputs = {
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
          inputs.agenix.packages.${system}.default
        ];
      };
    });

    # nix flake modules are meant to be portable so we cannot rely on
    # (extraS|s)pecialArgs to pass variables
    nixosModules = (import ./modules/nixos) moduleInputs;
    homeManagerModules = (import ./modules/home-manager) moduleInputs;
    packages = eachSystem (system: let pkgs = import nixpkgs { inherit system; };
      in (
        import ./pkgs { inherit pkgs; }) // {
          iso = let
            isoSystem = mkISOSystem system;
          in isoSystem.config.system.build.isoImage;
        }
      );
    apps = eachSystem (system: import ./pkgs/apps.nix
      { inherit (self.outputs) packages; inherit system; });

    overlays = import ./overlays self;

    nixosConfigurations = {
      iso = mkISOSystem "x86_64-linux";
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

      rpi4 = mkSystem {
        nixpkgs = inputs.nixpkgs-unstable;
        home-manager = inputs.home-manager-unstable;
        system = "aarch64-linux";
        stateVersion = "24.11";
        hostname = "rpi4";
      };
    }; # end nixosConfigurations

    homeConfigurations = {
      # minimal root config
      "root@rpi4" = mkHome {
        system = "aarch64-linux";
        stateVersion = "23.11";
        username = "root";
        homeDirectory = "/root";
        config = { pkgs, ...}: {
          programs.bash.enable = true;

          # update nix system-wide since it's installed via root profile
          home.packages = with pkgs; [ btdu nix ];
        };
        nixpkgs = inputs.nixpkgs-unstable;
        home-manager = inputs.home-manager-unstable;
      };

      "nullbite@rpi4" = mkHome {
        system = "aarch64-linux";
        stateVersion = "23.11";
        config = { pkgs, ...} : {
          programs = {
            zsh.enable = false;
            keychain.enable = false;
          };
          home.packages = with pkgs; [ btdu ];
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
