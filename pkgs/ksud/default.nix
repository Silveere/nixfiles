{
  lib,
  stdenv,
  fetchurl,
  unzip,
  system,
}: let
  lock = builtins.fromJSON (builtins.readFile ./lock.json);
  release = lock.${system};
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "ksud";
    version = release.version;

    src = fetchurl {
      inherit (release) url hash;
    };

    phases = ["installPhase"];

    installPhase = ''
      install -Dm555 $src "$out/bin/ksud"
    '';
  })
