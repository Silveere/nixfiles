{lib, ...} @ flakeArgs: let
  mkOpt = name: value:
    lib.mkOption {
      description = "Arguments for the ${name} module evaluator";
      default = value;
      readOnly = true;
    };
  mkModule = name: {...} @ args: {
    options.nixfiles.args = lib.mapAttrs mkOpt {
      flake = flakeArgs;
      "${name}" = args;
    };
  };
in {
  options.nixfiles.args = lib.mapAttrs mkOpt {
    flake = flakeArgs;
  };

  config.flake.modules = lib.genAttrs [
    "nixos"
    "homeManager"
  ] (name: {nixfiles = mkModule name;});
}
# translation: give the flake plus the `nixfiles` nixos and homeManager modules
# an option called `nixfiles.args` which passes through both flake args and
# args for the current module evaluator so i can better support the legacy code
# and also poke at it with the repl

