{
  lib,
  inputs,
  ...
}: {
  config.perSystem = {
    config,
    pkgs,
    self',
    ...
  }: let
    formatter =
      pkgs.runCommandNoCC "flake-formatter" {
        formatter = lib.getExe self'.formatter;
      } ''
        mkdir -p $out/bin
        ln -s "$formatter" "$out/bin/formatter"
      '';

    install-hooks = pkgs.writeShellScriptBin "install-hooks" config.pre-commit.installationScript;

    devShell-common = with pkgs; [
      jq
      nix-update
      nix-fast-build
      nvfetcher
      just
      config.pre-commit.settings.package
      install-hooks
    ];

    devShell-default = with pkgs; [
      alejandra
      formatter
      # inputPathLinks
      inputs.agenix.packages.${system}.default
    ];
  in {
    treefmt = {
      programs = {
        alejandra.enable = true;
      };
      settings = {
        global.excludes = [
          "_sources/*"
        ];
      };
    };

    pre-commit.settings = {
      hooks = {
        treefmt = {
          enable = true;
        };
      };
    };

    devShells = {
      ci = pkgs.mkShell {
        buildInputs = devShell-common;
      };
      default = let
        inputPaths = lib.mapAttrsToList (_: v: v.outPath) inputs;
        inputPathLinks = let
          linkCommands = lib.pipe inputPaths [
            (map (x: "ln -s ${lib.escapeShellArg x} $out/"))
            (lib.concatStringsSep "\n")
          ];
        in
          pkgs.runCommand "links" {} ''
            mkdir -p $out
            ${linkCommands}
          '';
      in
        pkgs.mkShell {
          # no-op which (theoreticlly) forces all of the flake inputs
          # to be build inputs so i can have all of them as a gcroot
          # locally automatically by lorri. it normally only pins the
          # shell as opposed to all of the inputs like nix-direnv,
          # which makes cerain things annoying. i like having all of
          # the inputs cached.
          shellHook = ''
            : ${lib.escapeShellArg (lib.concatStringsSep ":" inputPaths)}

            echo installing pre-commit hooks >&2
            ${config.pre-commit.installationScript}
          '';

          buildInputs = devShell-common ++ devShell-default;
        };
    };
  };
}
