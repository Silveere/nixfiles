{ lib,
  atool,
  makeBinaryWrapper,
  stdenvNoCC,
  lzip,
  plzip,
  lzop,
  lzma,
  zip,
  unzip,
  arj,
  rpm,
  cpio,
  p7zip,
  unrar,
  lha,
  unfree ? false }:
let
  wrappedPath = lib.makeBinPath ([lzip plzip lzop lzma zip unzip arj rpm cpio p7zip] ++ lib.optionals unfree [unrar lha]);
in
stdenvNoCC.mkDerivation {
  name = "atool-wrapped";
  phases = [ "installPhase" ];
  nativeBuildInputs = [ makeBinaryWrapper ];
  src = ./.;
  installPhase = ''
    makeBinaryWrapper "${atool}/bin/atool" "$out/bin/atool" \
      --inherit-argv0 --prefix PATH : "${wrappedPath}"
    for i in acat adiff als apack arepack aunpack ; do
      ln -s $out/bin/atool $out/bin/$i
    done
    # i have no idea if this is the "right" way to do this
    mkdir -p "$out/share"
    ln -s "${atool}/share/man" "$out/share/man"
  '';
}
