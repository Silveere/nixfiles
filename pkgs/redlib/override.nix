{
  lib,
  redlib,
  callPackage,
  rustPlatform,
  ...
}: let
  sources = callPackage ../_sources/generated.nix {};
in
  redlib.overrideAttrs (prev: rec {
    inherit (sources.redlib) src pname version;
    cargoDeps = rustPlatform.importCargoLock sources.redlib.cargoLock."Cargo.lock";

    checkFlags = prev.checkFlags ++ [
      "--skip=test_generic_web_backend"
      "--skip=test_mobile_spoof_backend"
    ];

    patches =
      (prev.patches or [])
      ++ [
        # this is so the commit hash can be embedded so redlib doesn't complain
        # about the server being outdated unless it's /actually/ outdated
        ./no-hash.patch
      ];

    GIT_HASH = src.rev;
  })
