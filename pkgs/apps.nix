{
  packages,
  system,
  ...
}: let
  _packages = packages;
in let
  packages = _packages.${system};
  mkApp = program: {
    type = "app";
    inherit program;
  };
in {
  keysetting = mkApp "${packages.wm-helpers}/bin/keysetting";
}
