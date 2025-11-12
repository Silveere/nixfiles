{ config, lib, self, inputs, ... }:
let
  # TODO deduplicate some of this module, probably create a few helper
  # functions to generate the conditional imports. probably also create a
  # function to create and/or compose overlays. this is still infinitely
  # cleaner than overlays/mitigations.nix.

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
        nixpkgs.overlays = let
          ov = final: _: {
            openssh = sshPackage' final;
          };
        in [ ov ];
      });
    };
  };
}
