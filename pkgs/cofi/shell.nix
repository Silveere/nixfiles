{ pkgs ? import <nixpkgs> {} }:
let
  rofi-dmenu-wrapped = pkgs.writeShellScript "rofi-dmenu" ''
    exec "${pkgs.rofi-wayland}/bin/rofi" -dmenu "$@"
  '';
in
pkgs.mkShell {
  shellHook = ''
    export COMMA_PICKER="${rofi-dmenu-wrapped}"
  '';
  nativeBuildInputs = with pkgs; [
    rofi-wayland
    libnotify
    comma
  ];
}
