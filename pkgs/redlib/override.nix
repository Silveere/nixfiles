{
  lib,
  redlib,
  sources,
  rustPlatform,
  ...
}:
redlib.overrideAttrs (orig: {
  inherit (sources.redlib) src pname version;
  # cargoLock = sources.redlib."Cargo.lock";
  cargoDeps = rustPlatform.importCargoLock sources.redlib.cargoLock."Cargo.lock";
})
