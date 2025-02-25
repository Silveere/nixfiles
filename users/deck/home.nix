{
  pkgs,
  config,
  lib,
  ...
}: {
  config = {
    home.packages = [
      (pkgs.writeShellScriptBin "hmup" ''
        unset LD_PRELOAD LD_LIBRARY_PATH

        konsole -e bash -c "nix flake metadata --refresh github:Silveere/nixfiles; nh home switch github:Silveere/nixfiles"
      '')
      (
        pkgs.runCommand "deckwrap" {} ''
          mkdir -p $out/bin/
          cat << 'EOF' > $out/bin/deckwrap
          #!/bin/sh
          #this shebang is a constant between nixos and non-nixos that can be
          #used to unset the two things below so we can get to the real command
          unset LD_PRELOAD LD_LIBRARY_PATH

          exec "$@"
          EOF
          chmod +x $out/bin/deckwrap
        ''
      )
    ];
    programs.keychain.enable = false;
    nixfiles.packageSets.gaming.enable = true;
    nixfiles.packageSets.gaming.enableLaunchers = false;
  };
}
