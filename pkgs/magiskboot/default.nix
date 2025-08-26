{
  lib,
  stdenv,
  fetchurl,
  unzip,
  system
}: let
  systems = {
    "i686-linux" = "x86";
    "x86_64-linux" = "x86_64";
    "aarch64-linux" = "arm64-v8a";
    "armv7l-linux" = "armeabi-v7a";
  };

  arch = systems.${system} or (abort "unsupported system: ${system}");
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "magiskboot-bin";
    version = "29.0";

    src = fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v29.0/Magisk-v29.0.apk";
      hash = "sha256-mdQN8aaKBaXnhFKpzU8tdTQ012IrrutE6hSugjjBqco=";
    };

    nativeBuildInputs = [unzip];

    phases = [ "installPhase" ];

    installPhase = ''
      unzip -p "${finalAttrs.src}" "lib/${arch}/libmagiskboot.so" > libmagiskboot.so
      install -Dm555 libmagiskboot.so "$out/bin/magiskboot"
      rm libmagiskboot.so
    '';
  })
