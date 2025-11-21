# vim: set foldmethod=marker:
{
  description = "NixOS Configuration";

  inputs = {
    # {{{
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    #              ^^^^^^^^^^^^^ this part is optional
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixpkgs-nix-du.url = "github:NixOS/nixpkgs/c933cf4698e5189b35dd83bf4d7a81aef16d464a";
    nixpkgs-mopidy.url = "github:NixOS/nixpkgs/93ff48c9be84a76319dac293733df09bbbe3f25c";

    nixpkgs-forgejo.url = "github:NixOS/nixpkgs/02032da4af073d0f6110540c8677f16d4be0117f";

    # this seems to be a popular way to declare systems
    systems.url = "github:nix-systems/default";

    flake-parts.url = "github:hercules-ci/flake-parts";

    import-tree.url = "github:vic/import-tree";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    pre-commit-nix = {
      # why is it called git-hooks if it is a pre-commit wrapper
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # this is nice so one-off impure scripts can interact with attributes in
    # this flake
    flake-compat = {
      url = "github:edolstra/flake-compat";
    };

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

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
      url = "github:danth/stylix/82323751bcd45579c8d3a5dd05531c3c2a78e347";
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

    ai-robots-txt = {
      url = "github:ai-robots-txt/ai.robots.txt";
      flake = false;
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
          ./overlays
          # dendritic init >:3
          (inputs.import-tree ./dendritic)
          inputs.treefmt-nix.flakeModule
          inputs.flake-parts.flakeModules.modules
          inputs.pre-commit-nix.flakeModule
        ];

        config = {
          # flake-parts systems (still uses nix-systems)
          systems = import inputs.systems;

          # expose vars to nix repl
          debug = lib.mkDefault true;

          perSystem = {
            config,
            system,
            pkgs,
            self',
            ...
          }: {
            legacyPackages.specialisedNixosConfigurations = let
              attrs = lib.pipe self.nixosConfigurations [
                (lib.filterAttrs (n: v: !(builtins.elem n ["iso" "rpi4-x86_64"])))
                (lib.filterAttrs (n: v: v.pkgs.stdenv.hostPlatform.system or "" == system))
                (lib.mapAttrs' (configName: v: let
                  nospec =
                    (v.extendModules {
                      modules = [
                        ({lib, ...}: {
                          config.specialisation = lib.mkForce {};
                        })
                      ];
                    })
                    .config;
                  configs =
                    (
                      lib.mapAttrs'
                      (n: v: lib.nameValuePair "specialisation-${n}" v.configuration)
                      v.config.specialisation
                    )
                    // {inherit nospec;};
                in
                  lib.nameValuePair configName configs))
                (
                  lib.concatMapAttrs (
                    configName: v:
                      (
                        lib.mapAttrs' (
                          specName: v: lib.nameValuePair "${configName}--${specName}" v
                        )
                      )
                      v
                  )
                )
                (lib.mapAttrs (_: v: v.system.build.toplevel))
              ];
            in
              attrs;
          };

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

              zen-browser-overlay = final: prev: let
                inherit (final.stdenv.hostPlatform) system;
                inherit (final) callPackage;

                input = inputs.zen-browser;
                packages = input.packages.${system};
              in {
                zen-browser-bin = packages.twilight;
              };
            in [
              # TODO delete this, transfer all packages to new-packages overlay
              packagesOverlay
              self.overlays.new-packages
              # various temporary fixes that automatically revert
              self.overlays.mitigations

              # auto backports from nixpkgs unstable
              self.overlays.backports

              # modpacks (keeps modpack version in sync between hosts so i can reverse
              # proxy create track map because it's broken)
              self.overlays.modpacks
              self.overlays.nvfetcher

              inputs.hyprwm-contrib.overlays.default
              inputs.rust-overlay.overlays.default
              inputs.nixfiles-assets.overlays.default
              nix-minecraft-patched-overlay
              zen-browser-overlay
            ];

            systems = {
              slab.system = "x86_64-linux";
              nullbox.system = "x86_64-linux";
              rpi4.system = "aarch64-linux";

              nixos-px1.system = "x86_64-linux";
              nixos-wsl = {
                system = "x86_64-linux";
                wsl = true;
              };

              # for eval testing
              rpi4-x86_64 = {
                system = "x86_64-linux";
                name = "rpi4";
                modules = [
                  {
                    nixpkgs.hostPlatform = "x86_64-linux";
                  }
                ];
              };
            }; # end systems
          };

          flake = let
            # {{{
            inherit (nixfiles-lib.flake-legacy) mkSystem mkWSLSystem mkISOSystem mkHome;
            inherit (inputs) nixpkgs nixpkgs-unstable;
            inherit (self) outputs;
            inherit (config.nixfiles.vars) username mobileTimeZone;

            # inputs is already defined
            lib = nixpkgs.lib;

            # function to generate packages for each system
            eachSystem = lib.genAttrs (import inputs.systems);

            # values to be passed to nixosModules and homeManagerModules wrappers
            moduleInputs = {
            };
            # }}}
          in {
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

            nixosConfigurations = {
              iso = mkISOSystem "x86_64-linux";
            }; # end nixosConfigurations

            nospec = lib.mapAttrs (n: v:
              v.extendModules {
                modules = [
                  (
                    {lib, ...}: {specialisation = lib.mkForce {};}
                  )
                ];
              })
            config.flake.nixosConfigurations;

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

