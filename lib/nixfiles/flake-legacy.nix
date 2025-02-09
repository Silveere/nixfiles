{
  self,
  lib,
  ...
}: let
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

  ### Configuration
  # My username
  username = "nullbite";
  # My current timezone for any mobile devices (i.e., my laptop)
  mobileTimeZone = "Europe/Amsterdam";

  # Variables to be passed to NixOS modules in the vars attrset
  vars = {
    inherit username mobileTimeZone self;
  };

  # funciton to generate packages for each system
  eachSystem = lib.genAttrs (import inputs.systems);

  # values to be passed to nixosModules and homeManagerModules wrappers
  moduleInputs = {
  };
  inherit (self) inputs outputs;
  inherit (inputs) nixpkgs nixpkgs-unstable home-manager home-manager-unstable;
in rec {
  # This function produces a module that adds the home-manager module to the
  # system and configures the given module to the user's Home Manager
  # configuration
  homeManagerInit = let
    _username = username;
    _nixpkgs = nixpkgs;
  in
    {
      system,
      nixpkgs ? _nixpkgs, # this is so modules can know which flake the system is using
      home-manager ? inputs.home-manager,
      username ? _username,
      module ? _: {},
      rootModule ? (import (self + "/home/root.nix")),
      userModules ? {
        ${username} = [module];
        root = [rootModule];
      },
      stateVersion,
    }: {
      config,
      lib,
      pkgs,
      ...
    }: let
      mapUserModules = lib.attrsets.mapAttrs (user: modules: {...}: {
        imports =
          [
            (self + "/home")
          ]
          ++ modules;
        config = {
          home = {inherit stateVersion;};
        };
      });
      users = mapUserModules userModules;
    in {
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

  # TODO rewrite this so it follows the same wrapper pattern as
  # mkHome This function produces a nixosSystem which imports
  # configuration.nix and a Home Manager home.nix for the given user
  # from ./hosts/${hostname}/
  #
  # nevermind i am migrating everything to flake-parts, i'm glad i
  # never got around to this. i think the module system takes care of
  # whatever the fuck godforsaken use-case i had for rewriting this
  # (more ergonomic and/or default arguments or something).
  mkSystemN = let
    _username = username;
    _overlays = overlays;
  in
    {
      nixpkgs ? inputs.nixpkgs,
      home-manager ? inputs.home-manager,
      username ? _username,
      entrypoint ? (self + "/system"),
      modules ? [],
      stateVersion ? null,
      config ? {},
      overlays ? _overlays,
      system,
      ...
    } @ args: let
      _modules =
        [entrypoint config]
        ++ modules
        ++ [
          {
            nixpkgs.config = {
              inherit overlays;
              allowUnfree = true;
            };
          }
        ]
        ++ lib.optional (args ? stateVersion) {config.system.stateVersion = stateVersion;};
    in
      nixpkgs.lib.nixosSystem {
      };
  mkSystem = let
    _username = username;
    _overlays = overlays;
    _nixpkgs = nixpkgs;
  in
    {
      system,
      nixpkgs ? _nixpkgs,
      home-manager ? inputs.home-manager,
      overlays ? _overlays,
      hostname,
      username ? _username,
      stateVersion,
      extraModules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          [
            (self + "/system")
            ({
                pkgs,
                config,
                lib,
                ...
              } @ args: {
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
                nix.settings.experimental-features = ["nix-command" "flakes"];
              })
            (self + "/hosts/${hostname}/configuration.nix")
            (homeManagerInit {
              inherit nixpkgs home-manager;
              module = import (self + "/hosts/${hostname}/home.nix");
              inherit username system stateVersion;
            })
          ]
          ++ extraModules;
        specialArgs = {
          inherit inputs outputs vars nixpkgs home-manager;
        };
      };

  mkWSLSystem = let
    _username = username;
  in
    {
      username ? _username,
      extraModules ? [],
      ...
    } @ args: let
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

  mkISOSystem = system:
    inputs.nixpkgs-unstable.lib.nixosSystem {
      inherit system;
      modules = [
        "${inputs.nixpkgs-unstable}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
        ({
          config,
          pkgs,
          lib,
          ...
        }: {
          environment.systemPackages = with pkgs; [
            neovim
            gparted
          ];
        })
      ];
    };
  # Make a home-manager standalone configuration. This implementation is
  # better than mkSystem because it extends homeManagerConfiguration.
  mkHome = let
    _home-manager = inputs.home-manager;
    _nixpkgs = inputs.nixpkgs;
    _username = username;
  in
    {
      home-manager ? _home-manager,
      nixpkgs ? _nixpkgs,
      username ? _username,
      homeDirectory ? "/home/${username}",
      entrypoint ? (self + "/home/standalone.nix"),
      modules ? [],
      stateVersion ? null,
      config ? {},
      system,
      ...
    } @ args: let
      _modules =
        [entrypoint]
        ++ modules
        ++ [config]
        ++ [
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
        ]
        ++ lib.optional (args ? stateVersion) {config.home.stateVersion = stateVersion;};
    in
      home-manager.lib.homeManagerConfiguration ({
          modules = _modules;
          pkgs = import nixpkgs {inherit system overlays;};

          extraSpecialArgs = {
            inherit inputs outputs vars nixpkgs home-manager;

            # this is needed because modules don't use the default arg for some reason???
            osConfig = {};
          };
        }
        // builtins.removeAttrs args
        ["system" "nixpkgs" "home-manager" "modules" "username" "homeDirectory" "stateVersion" "entrypoint" "config"]);
}
