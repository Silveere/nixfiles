{ pkgs, config, lib, ... }:
{
  config = {
    home.packages = [
    (pkgs.writeShellScriptBin "hmup" ''
      unset LD_PRELOAD LD_LIBRARY_PATH

      konsole -e bash -c "nix flake metadata --refresh github:Silveere/nixfiles; nh home switch github:Silveere/nixfiles"
    '')
    ];
    programs.keychain.enable = false;
    nixfiles.packageSets.gaming.enable = true;
    nixfiles.packageSets.gaming.enableLaunchers = false;
  };
}
