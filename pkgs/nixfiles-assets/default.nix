{ lib, stdenvNoCC, fetchFromGitea }:
let
  src = fetchFromGitea {
    domain = "gitea.protogen.io";
    owner = "nullbite";
    repo = "nixfiles-assets";
    rev = "4ee66c3036";
    hash = "sha256-e8iXy4hCLYegNTeyB/GB8hj+gj1wPD+b+XOsEcdfEJY=";
    forceFetchGit = true;
    fetchLFS = true;
  };
in
stdenvNoCC.mkDerivation {
  pname = "nixfiles-assets";
  version = src.rev;
  inherit src;
  phases = [ "installPhase" ];
  installPhase = ''
    cd $src
    pwd
    ls
    mkdir -p $out/share/
    cp -a wallpapers $out/share/
  '';
}
