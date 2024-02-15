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
    # symlinking them doesn't work for some reason so i have to build multiple
    for i in atool acat adiff als apack arepack aunpack ; do
      makeBinaryWrapper "${atool}/bin/$i" "$out/bin/$i" \
        --inherit-argv0 --prefix PATH : "${wrappedPath}"
    done

    # i have no idea if this is the "right" way to do this
    mkdir -p "$out/share"
    ln -s "${atool}/share/man" "$out/share/man"
  '';
}
