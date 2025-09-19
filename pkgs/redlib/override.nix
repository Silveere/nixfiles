{
  lib,
  redlib,
  sources,
  rustPlatform,
  ...
}:
redlib.overrideAttrs (prev: rec {
  inherit (sources.redlib) src pname version;
  cargoDeps = rustPlatform.importCargoLock sources.redlib.cargoLock."Cargo.lock";

  patches = (prev.patches or []) ++ [
    # this is so the commit hash can be embedded so redlib doesn't complain
    # about the server being outdated unless it's /actually/ outdated
    ./no-hash.patch
  ];

  GIT_HASH = src.rev;
})
