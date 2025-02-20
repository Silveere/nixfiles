{ nixpkgs ? <nixpkgs>, pkgs ? (import nixpkgs) { } }:
let
  inherit (pkgs) callPackage fetchFromSourcehut fetchFromGitHub lib;
  inherit (lib) escapeShellArg;

  lucem = pkgs.callPackage ./. { };

  nim_lk_patched = pkgs.nim_lk.overrideAttrs (final: prev: {
    src = pkgs.fetchFromSourcehut {
      owner = "~ehmry";
      repo = "nim_lk";
      rev = "c2d601095d1961d8f59f1fffe5b56788b255c3de";
      hash = "sha256-1WD1UVi6N7tftE69LAhx86Qxc97oMHKARFsCVGqtEm4=";
    };
    patches = [
      ./nim_lk-rev-order-fix.patch
    ];
  });

in
  pkgs.stdenvNoCC.mkDerivation {
    name = "lucem-lock.json";

    src = lucem.src;

    nativeBuildInputs = with pkgs; [
      nim_lk_patched
      nix-prefetch-git
      nix
      # cacert
      git
    ];

    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

    buildPhase = ''
      find .
      nim_lk > $out
    '';
  }
