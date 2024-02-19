{ lib,
  stdenvNoCC,
  socat,
  coreutils,
  hyprland,
  makeShellWrapper }:
let
  wrappedPath = lib.makeBinPath [ coreutils socat hyprland ];
in
stdenvNoCC.mkDerivation {
  name = "hyprland-dispatcher";
  phases = [ "installPhase" ];
  nativeBuildInputs = [ makeShellWrapper ];
  src = ./.;
  installPhase = ''
    install -Dm555 $src/dispatcher.sh $out/bin/hypr-dispatcher
    wrapProgramShell $out/bin/hypr-dispatcher --prefix PATH : "${wrappedPath}"
  '';
}
