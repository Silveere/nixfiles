{
  lib,
  buildNimPackage,
  curl,
  gtk4,
  libadwaita,
  pkg-config,
  openssl,
  xorg,
  libxkbcommon,
  libGL,
  wayland,
  wayland-protocols,
  wayland-scanner,
  fetchFromGitHub,
}:
buildNimPackage (finalAttrs: {
  pname = "lucem";
  version = "2.1.2";

  src = fetchFromGitHub {
    owner = "xTrayambak";
    repo = "lucem";
    tag = finalAttrs.version;
    hash = "sha256-9i7YMXG6hXMcQmVdPYX+YxrtQPHZE1RZb+gv5dGEff8=";
  };

  patches = [
    ./lucem-disable-auto-updater.patch
  ];

  lockFile = ./lock.json;

  buildInputs = [
    gtk4.dev
    libadwaita.dev
    openssl.dev
    curl.dev
    xorg.libX11
    xorg.libXcursor.dev
    xorg.libXrender
    xorg.libXext
    libxkbcommon.dev
    libGL.dev
    wayland.dev
    wayland-protocols
    wayland-scanner.dev
  ];
  nativeBuildInputs = [
    pkg-config
  ];

  # env.LD_LIBRARY_PATH = lib.makeLibraryPath [
  #   gtk4.dev
  #   libadwaita.dev
  #   pkg-config
  #   curl.dev
  #   openssl.dev
  #   wayland.dev
  # ];
})
