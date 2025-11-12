{ config, lib, self, inputs, ... }:
let
  # TODO deduplicate some of this module, probably create a few helper
  # functions to generate the conditional imports. probably also create a
  # function to create and/or compose overlays. this is still infinitely
  # cleaner than overlays/mitigations.nix.
  #
  # also apparently the home-manager ssh option doesn't work how i expected it
  # to (no way to NOT generate a config) and overlaying `openssh` causes a mass
  # rebuild so that is not an option either; i need to factor out the base
  # profiles to dendritic so i can manage them more easily.

  sshPackage' = pkgs: let
    inherit (pkgs.stdenv.hostPlatform) system;
  in inputs.nixpkgs.legacyPackages.${system}.openssh;

  held = now: days: let
    seconds = days * 24 * 60 * 60;
    endTime = now + seconds;
  in self.lastModified < endTime;
in
{
  config.flake.modules = {
    nixos.nixfiles = {
      imports = lib.optional (held 1762974327 14) ({ pkgs, ... }: {
        programs.ssh.package = sshPackage' pkgs;
      });
    };
    homeManager.nixfiles = {
      imports = lib.optional (held 1762974327 14) ({ pkgs, ... }: {
        programs.ssh.package = sshPackage' pkgs;
      });
    };
  };
}
