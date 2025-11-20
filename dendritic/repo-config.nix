{
  lib,
  inputs,
  ...
}: {
  config.perSystem = {
    pkgs,
    self',
    ...
  }: {
    devShells = {
      ci = pkgs.mkShell {
        buildInputs = with pkgs; [
          jq
          nix-update
          nix-fast-build
          nvfetcher
          just
        ];
      };
      default = let
        formatter =
          pkgs.runCommandNoCC "flake-formatter" {
            formatter = lib.getExe self'.formatter;
          } ''
            mkdir -p $out/bin
            ln -s "$formatter" "$out/bin/formatter"
          '';

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
          '';

          buildInputs = with pkgs; [
            alejandra
            nix-update
            formatter
            nvfetcher
            just
            # inputPathLinks
            inputs.agenix.packages.${system}.default
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
  };
}
