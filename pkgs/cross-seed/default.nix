{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage rec {
  pname = "cross-seed";
  version = "6.11.0";
  src = fetchFromGitHub {
    owner = "cross-seed";
    repo = "cross-seed";
    rev = "v${version}";
    hash = "sha256-+bIRLoiY9+23GUuKxPpKK23cb4Dng5nwxh3SUzMAtXA=";
  };

  npmDepsHash = "sha256-gNsD6+4+PIcygL/QCznecd5bVnLyorVJfHM/+cLG4og=";
}
