{
  config,
  options,
  lib,
  nixfiles-lib,
  inputs,
  self,
  ...
}: let
  cfg = config.nixfiles.systems;
  inherit
    (lib)
    types
    mkOption
    mkIf
    filterAttrs
    mapAttrs
    ;

  inherit (builtins) attrNames isNull;

  inherit (nixfiles-lib.flake-legacy) mkSystem mkHome mkWSLSystem mkISOSystem homeManagerInit;
  inherit (nixfiles-lib.types) mkCheckedType;

  mkConfigurationOption = systemType:
    mkOption {
      description = "${systemType} configuration type";
      type = with types; nullOr mkCheckedType "configuration";
      default = null;
    };
in {
  options.nixfiles.systems = let
    systemModule = let
      outerConfig = config;
      outerOptions = options;
    in
      {
        name,
        config,
        ...
      }: {
        options = {
          enable =
            lib.mkEnableOption ""
            // {
              description = ''
                Whether to install this configuration into the flake outputs.
              '';
              default = true;
            };

          nixpkgs = mkOption {
            description = "nixpkgs input to build system with";
            type = nixfiles-lib.types.flake;
            default = inputs.nixpkgs-unstable;
          };

          extraConfig = mkOption {
            description = ''
              Arguments to pass to nixpkgs.lib.nixosSystem
            '';
            type = types.attrs;
            default = {};
          };

          system = mkOption {
            description = "Nix system value";
            type = types.str;
            example = "x86_64-linux";
          };

          modules = mkOption {
            description = "Extra NixOS configuration modules.";
            type = with types; listOf deferredModule;
            default = [];
          };

          name = mkOption {
            description = ''
              Name of NixOS configuration. This influences the default
              directory to load configuration from. This does *not* modify the
              system's hostname, but should probably be set to the same value.
            '';
            type = lib.types.str;
            default = name;
          };

          configRoot = mkOption {
            description = "Path to directory containing system and home configuration modules.";
            type = lib.types.path;
            default = self + "/hosts/${config.name}";
          };

          configuration = mkOption {
            description = "Path/module of main NixOS configuration.";
            type = with types; nullOr deferredModule;
            default = config.configRoot + "/configuration.nix";
          };

          home-manager = {
            enable =
              lib.mkEnableOption ""
              // {
                description = ''
                  Whether to enable home-manager for this configuration.
                '';
                default = true;
              };

            input = mkOption {
              description = "home-manager input";
              type = nixfiles-lib.types.flake;
              default = inputs.home-manager-unstable;
            };

            configuration = mkOption {
              description = "Path/module of main home-manager configuration.";
              type = with types; nullOr deferredModule;
              default = config.configRoot + "/home.nix";
            };

            modules = mkOption {
              description = "Extra home-manager modules";
              type = with types; listOf deferredModule;
            };
          };

          wsl =
            lib.mkEnableOption ""
            // {
              description = ''
                Whether to import WSL related configuration
              '';
            };

          result = lib.mkOption {
            description = "Resulting system configuration";
            type = with types; nullOr (mkCheckedType "configuration");
          };
        };

        config = {
          home-manager.input = lib.mkIf (config.nixpkgs == inputs.nixpkgs) (lib.mkDefault inputs.home-manager);

          modules = let
            # dendritic nixfiles init >:3
            nixfilesModule = outerConfig.flake.modules.nixos.nixfiles;
            defaultsModule = {...}: {
              # Values for every single system that would not conceivably need
              # to be made modular

              # this should be set in the system config
              # system.stateVersion = stateVersion;
              nixpkgs = {
                inherit (outerConfig.nixfiles.common) overlays;
                config = {
                  # not having the freedom to install unfree programs is unfree
                  allowUnfree = true;
                };
              };
              # this should be on by default and there is no reason to turn it
              # off because this flake will literally stop working otheriwse
              nix.settings.experimental-features = ["nix-command" "flakes"];
            };
            wslModule = {...}: {
              imports = [
                inputs.nix-wsl.nixosModules.wsl
              ];
              wsl.enable = true;
              wsl.defaultUser = outerConfig.nixfiles.vars.username;
            };

            homeManagerModule = let
              homeManagerModuleInner = homeManagerInit {
                inherit (config) nixpkgs system;
                inherit (outerConfig.nixfiles.vars) username;
                home-manager = config.home-manager.input;
                module =
                  if (isNull config.home-manager.configuration)
                  then {}
                  else config.home-manager.configuration;
              };
            in
              {
                config,
                pkgs,
                lib,
                ...
              }: let
                osConfig = config;
                perUserDefaultsModule = {
                  lib,
                  config,
                  ...
                }: {
                  config = {
                    # previously, home-manager inherited stateVersion from
                    # nixos in a really hacky way that depended on the wrapper
                    # function. this should preserve that behavior in a much
                    # safer way by directly setting it in a module. ideally, it
                    # should probably be set manually, but I want to maintain
                    # backwards compatibility for now.
                    home.stateVersion = lib.mkDefault osConfig.system.stateVersion;

                    # only inherit configs from system for myself
                    nixfiles.useOsConfig =
                      config.home.username == outerConfig.nixfiles.vars.username;

                    # pass the system nixpkgs config as defaults for the
                    # home-manager nixpkgs config. useGlobalPkgs prevents
                    # setting overlays at the home level; this allows for doing
                    # that while inheriting the system overlays.
                    nixpkgs = {
                      config = lib.mapAttrs (n: v: lib.mkDefault v) osConfig.nixpkgs.config;
                      # mkOrder 900 is after mkBefore but before default order
                      overlays = lib.mkOrder 900 osConfig.nixpkgs.overlays;
                    };
                  };
                };
              in {
                imports = [
                  # TODO placeholder using old function
                  homeManagerModuleInner
                ];

                options.home-manager.users = lib.mkOption {
                  type = with lib.types; attrsOf (submodule perUserDefaultsModule);
                };
              };
          in
            [
              nixfilesModule
              defaultsModule
            ]
            # dendritic should simplify this too because this is essentially a
            # wrapper for `imports` and i should not define separate configs
            # for this
            ++ lib.optional (!(isNull config.configuration)) config.configuration
            ++ lib.optional config.home-manager.enable homeManagerModule
            ++ lib.optional config.wsl wslModule;
          extraConfig = {
            inherit (config) system modules;
            # TODO get rid of specialArgs and pass things as a module
            # or just use dendritic :3
            specialArgs = let
              inherit (self) outputs;
            in {
              inherit inputs outputs;
              inherit (outerConfig.nixfiles) vars;
              inherit (config) nixpkgs;
              inherit (config.home-manager) input;
            };
          };
          result = config.nixpkgs.lib.nixosSystem config.extraConfig;
        };
      };
  in
    lib.mkOption {
      description = ''
        NixOS system configurations
      '';
      type = with types; attrsOf (submodule systemModule);
      default = {};
    };

  config = {
    flake.nixosConfigurations = let
      enabledSystems = filterAttrs (n: v: v.enable) cfg;
    in
      mapAttrs (_: v: v.result) enabledSystems;
  };
}
