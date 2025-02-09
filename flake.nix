# vim: set foldmethod=marker:
{
  description = "NixOS Configuration";

  inputs = {
    # {{{
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    #              ^^^^^^^^^^^^^ this part is optional
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixpkgs-nix-du.url = "github:NixOS/nixpkgs/c933cf4698e5189b35dd83bf4d7a81aef16d464a";

    # this seems to be a popular way to declare systems
    systems.url = "github:nix-systems/default";

    flake-parts.url = "github:hercules-ci/flake-parts";

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

    # https://github.com/nix-community/lanzaboote/releases
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    # no inputs.nixpkgs.follows so i can use cachix
    # https://github.com/hyprwm/Hyprland/releases
    # hyprland.url = "git+https://github.com/hyprwm/Hyprland?rev=v0.4.1&submodules=1";
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
      # ref = "refs/tags/v0.44.1";
    };

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
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.base16.follows = "base16";
    };

    base16 = {
      url = "github:SenchoPens/base16.nix";
    };

    nixfiles-assets = {
      # using self-hosted gitea mirror because of GitHub LFS bandwidth limit (even though i'd probably never hit it)
      type = "github";
      owner = "Silveere";
      repo = "nixfiles-assets";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
  }; # }}}

  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} (
      {
        inputs,
        self,
        config,
        lib,
        nixfiles-lib,
        ...
      } @ flakeArgs: {
        # flake-parts imports
        imports = [
          ./flake
          ./lib/nixfiles/module.nix
          ./pkgs/module.nix
        ];

        config = {
          # flake-parts systems (still uses nix-systems)
          systems = import inputs.systems;

          # expose vars to nix repl
          debug = lib.mkDefault true;

          nixfiles = {
            vars = {
              ### Configuration
              # My username
              username = "nullbite";
              # My current timezone for any mobile devices (i.e., my laptop)
              mobileTimeZone = "America/New_York";
            };

            common.overlays = let
              nix-minecraft-patched-overlay = let
                normal = inputs.nix-minecraft-upstream.overlays.default;
                quilt = inputs.nix-minecraft.overlays.default;
              in
                lib.composeExtensions
                normal
                (final: prev: let
                  x = quilt final prev;
                in {
                  inherit (x) quiltServers quilt-server;
                  minecraftServers = prev.minecraftServers // x.quiltServers;
                });

              packagesOverlay = final: prev: let
                packages = import ./pkgs {inherit (prev) pkgs;};
              in {
                inherit (packages) mopidy-autoplay google-fonts;
                atool-wrapped = packages.atool;
              };
            in [
              packagesOverlay
              # various temporary fixes that automatically revert
              self.overlays.mitigations

              # auto backports from nixpkgs unstable
              self.overlays.backports

              # modpacks (keeps modpack version in sync between hosts so i can reverse
              # proxy create track map because it's broken)
              self.overlays.modpacks

              inputs.hyprwm-contrib.overlays.default
              inputs.rust-overlay.overlays.default
              inputs.nixfiles-assets.overlays.default
              nix-minecraft-patched-overlay
            ];

            systems.testsys = {
              system = "x86_64-linux";
              enable = false;
            };
          };

          flake = let
            # {{{
            inherit (nixfiles-lib.flake-legacy) mkSystem mkWSLSystem mkISOSystem mkHome;
            inherit (inputs) nixpkgs nixpkgs-unstable;
            inherit (self) outputs;
            inherit (config.nixfiles.vars) username mobileTimeZone;

            # inputs is already defined
            lib = nixpkgs.lib;
            systems = ["x86_64-linux" "aarch64-linux"];

            overlays = let
              nix-minecraft-patched-overlay = let
                normal = inputs.nix-minecraft-upstream.overlays.default;
                quilt = inputs.nix-minecraft.overlays.default;
              in
                lib.composeExtensions
                normal
                (final: prev: let
                  x = quilt final prev;
                in {
                  inherit (x) quiltServers quilt-server;
                  minecraftServers = prev.minecraftServers // x.quiltServers;
                });
            in [
              (final: prev: let
                packages = import ./pkgs {inherit (prev) pkgs;};
              in {
                inherit (packages) mopidy-autoplay google-fonts;
                atool-wrapped = packages.atool;
              })

              # various temporary fixes that automatically revert
              self.overlays.mitigations

              # auto backports from nixpkgs unstable
              self.overlays.backports

              # modpacks (keeps modpack version in sync between hosts so i can reverse
              # proxy create track map because it's broken)
              self.overlays.modpacks

              inputs.hyprwm-contrib.overlays.default
              inputs.rust-overlay.overlays.default
              inputs.nixfiles-assets.overlays.default
              nix-minecraft-patched-overlay
            ];

            # function to generate packages for each system
            eachSystem = lib.genAttrs (import inputs.systems);

            # values to be passed to nixosModules and homeManagerModules wrappers
            moduleInputs = {
            };
            # }}}
          in {
            devShells = eachSystem (system: let
              pkgs = import nixpkgs-unstable {inherit system;};
            in {
              ci = pkgs.mkShell {
                buildInputs = with pkgs; [
                  nix-update
                  nix-fast-build
                ];
              };
              default = pkgs.mkShell {
                buildInputs = with pkgs; [
                  alejandra
                  nix-update
                  inputs.agenix.packages.${system}.default
                ];
              };
            });

            # nix flake modules are meant to be portable so we cannot rely on
            # (extraS|s)pecialArgs to pass variables
            nixosModules = (import ./modules/nixos) moduleInputs;
            homeManagerModules = (import ./modules/home-manager) moduleInputs;
            packages = eachSystem (
              system: {
                iso = let
                  isoSystem = mkISOSystem system;
                in
                  isoSystem.config.system.build.isoImage;
              }
            );
            apps = eachSystem (system:
              import ./pkgs/apps.nix
              {
                inherit (self.outputs) packages;
                inherit system;
              });

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

              # for eval testing
              rpi4-x86_64 = mkSystem {
                nixpkgs = inputs.nixpkgs-unstable;
                home-manager = inputs.home-manager-unstable;
                system = "x86_64-linux";
                stateVersion = "24.11";
                hostname = "rpi4";
                extraModules = [
                  {
                    nixpkgs.hostPlatform = "x86_64-linux";
                  }
                ];
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
                config = {pkgs, ...}: {
                  programs.bash.enable = true;

                  # update nix system-wide since it's installed via root profile
                  home.packages = with pkgs; [btdu nix];
                };
                nixpkgs = inputs.nixpkgs-unstable;
                home-manager = inputs.home-manager-unstable;
              };

              "nullbite@rpi4" = mkHome {
                system = "aarch64-linux";
                stateVersion = "23.11";
                config = {pkgs, ...}: {
                  programs = {
                    zsh.enable = false;
                    keychain.enable = false;
                  };
                  home.packages = with pkgs; [btdu];
                };
                nixpkgs = inputs.nixpkgs-unstable;
                home-manager = inputs.home-manager-unstable;
              };
              "deck" = mkHome {
                system = "x86_64-linux";
                stateVersion = "23.11";
                username = "deck";
                modules = [./users/deck/home.nix];
                nixpkgs = inputs.nixpkgs-unstable;
                home-manager = inputs.home-manager-unstable;
              };
              "testuser" = mkHome {
                username = "testuser";
                system = "x86_64-linux";
                modules = [./users/testuser/home.nix];
                stateVersion = "23.11";
                nixpkgs = inputs.nixpkgs-unstable;
                home-manager = inputs.home-manager-unstable;
              };
              "nix-on-droid" = mkHome {
                username = "nix-on-droid";
                homeDirectory = "/data/data/com.termux.nix/files/home";
                modules = [./users/nix-on-droid/home.nix];
                system = "aarch64-linux";
                stateVersion = "23.11";
                nixpkgs = inputs.nixpkgs-unstable;
                home-manager = inputs.home-manager-unstable;
              };
            };
          };
        };
      }
    ); # end outputs
}
# end flake

