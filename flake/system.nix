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

  inherit (builtins) attrNames;

  inherit (nixfiles-lib.flake-legacy) mkSystem mkHome mkWSLSystem mkISOSystem;
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
            description = "NixOS modules";
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

          configPath = mkOption {
            description = "Path to main system configuration module.";
            type = lib.types.path;
            default = self + "/hosts/${config.name}/configuration.nix";
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

            configPath = mkOption {
              description = "Path to main home configuration module.";
              type = lib.types.path;
              default = self + "/hosts/${config.name}/home.nix";
            };

            modules = mkOption {
              description = "home-manager modules";
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
            nixfilesModule = self + "/system";
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
          in
            [
              nixfilesModule
              defaultsModule
              # TODO
              # import /hosts/ path
              # home manager init
            ]
            ++ lib.optionals config.wsl wslModule;
          extraConfig = {
            inherit (config) system modules;
            # TODO get rid of specialArgs and pass things as a module
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
